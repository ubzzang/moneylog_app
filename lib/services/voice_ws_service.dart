import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

import '../common/constants.dart';

/// backend 기준 프로토콜 요약
/// - WS URL: /ws/voice-chat (인증 필요: Authorization Bearer <token>)
/// - 클라 → 서버:
///   - Binary: PCM16 LE, 16kHz, mono, 40~60ms 프레임(권장), 연속 전송
///   - Text: {"type":"audio_end"}  // "말 끝" 힌트(서버 VAD가 불안정할 때 특히 유효)
/// - 서버 → 클라:
///   - Text(JSON): stt_partial/final, llm_partial/final, tts_start/end/cancel 등
///   - Binary: TTS PCM16 chunk(16kHz mono)
class VoiceWsService {
  static const int sampleRate = 16000;
  static const int channels = 1;

  // 50ms 프레임(권장): 0.05s * 16000 = 800 samples, PCM16 => 1600 bytes
  static const int frameBytes50ms = 1600;

  IOWebSocketChannel? _channel;
  StreamSubscription? _wsSub;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  StreamController<Uint8List>? _recorderBytesCtrl;
  StreamSubscription? _recorderBytesSub;
  StreamSink<Uint8List>? _playerSink;

  bool _connected = false;
  bool _isCapturing = false;

  // 외부(UI)에 이벤트 전달
  void Function(Map<String, dynamic> event)? onEvent;
  void Function(String err)? onError;
  void Function(bool capturing)? onCapturingChanged;

  Future<String> _bearer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return 'Bearer $token';
  }

  Future<void> connectIfNeeded() async {
    if (_connected) return;

    // 1) 마이크 권한
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('마이크 권한이 없습니다.');
    }

    // 2) 오디오 장치 오픈
    await _recorder.openRecorder();
    await _player.openPlayer();

    // 3) PCM16 스트림 재생 준비(서버→클라 Binary)
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: channels,
      sampleRate: sampleRate,
      interleaved: true, // 9.30.0에서 요구되는 케이스가 많음
      bufferSize: 3200,   // 권장(안정성 우선). 저지연이면 1600
    );
    _playerSink = _player.uint8ListSink;

    // 4) WS 연결(backend6: /ws/** authenticated)
    final url = Constants.voiceWsUrl();
    final auth = await _bearer();

    _channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: {'Authorization': auth},
    );

    _wsSub = _channel!.stream.listen(
          (data) {
        if (data is String) {
          _handleText(data);
        } else if (data is Uint8List) {
          _handleBinary(data);
        } else if (data is List<int>) {
          _handleBinary(Uint8List.fromList(data));
        }
      },
      onError: (e) => onError?.call('WS 오류: $e'),
      onDone: () {
        _connected = false;
        onError?.call('WS 연결 종료');
      },
      cancelOnError: true,
    );

    _connected = true;
  }

  void _handleText(String jsonStr) {
    try {
      final obj = jsonDecode(jsonStr);
      if (obj is Map<String, dynamic>) {
        onEvent?.call(obj);
      } else if (obj is Map) {
        onEvent?.call(obj.map((k, v) => MapEntry(k.toString(), v)));
      }
    } catch (_) {
      // JSON이 아닌 로그 문자열 등은 무시 가능
    }
  }

  void _handleBinary(Uint8List pcmChunk) {
    // 서버→클라 Binary는 TTS PCM16 chunk로 간주하고 즉시 재생
    try {
      _playerSink?.add(pcmChunk);
    } catch (e) {
      onError?.call('오디오 재생 오류: $e');
    }
  }

  bool get isConnected => _connected;
  bool get isCapturing => _isCapturing;

  /// 토글 시작: 계속 캡처해서 서버로 송신(서버가 VAD로 발화 경계 판단)
  Future<void> startCapture() async {
    await connectIfNeeded();
    if (_isCapturing) return;

    _recorderBytesCtrl = StreamController<Uint8List>();
    _recorderBytesSub = _recorderBytesCtrl!.stream.listen((bytes) {
      if (bytes.isEmpty) return;
      _sendRechunked(bytes);
    });

    await _recorder.startRecorder(
      toStream: _recorderBytesCtrl!.sink,
      codec: Codec.pcm16,
      numChannels: channels,
      sampleRate: sampleRate,
    );

    _isCapturing = true;
    onCapturingChanged?.call(true);
  }

  /// 토글 종료: 캡처 중단 + audio_end(말 끝 힌트)
  Future<void> stopCapture() async {
    if (!_isCapturing) return;

    _isCapturing = false;
    onCapturingChanged?.call(false);

    try {
      await _recorder.stopRecorder();
    } catch (_) {}

    // 서버에게 "입력 중단/발화 종료 힌트"
    try {
      _channel?.sink.add(jsonEncode({'type': 'audio_end'}));
    } catch (_) {}

    await _recorderBytesSub?.cancel();
    _recorderBytesSub = null;

    await _recorderBytesCtrl?.close();
    _recorderBytesCtrl = null;
  }

  void _sendRechunked(Uint8List pcm) {
    if (!_connected || _channel == null) return;

    // flutter_sound가 내는 chunk 크기는 가변일 수 있어 50ms(1600 bytes) 단위로 쪼개 전송
    int off = 0;
    while (off < pcm.length) {
      final end = (off + frameBytes50ms <= pcm.length) ? off + frameBytes50ms : pcm.length;
      final chunk = pcm.sublist(off, end);

      // NOTE: 마지막 chunk가 너무 작으면 서버 프레임 검증에서 drop될 수 있음.
      // 간이 구현에서는 그대로 전송(관측 후 필요 시 "잔여 버퍼 누적"으로 개선)
      _channel!.sink.add(chunk);

      off = end;
    }
  }

  Future<void> dispose() async {
    try { await stopCapture(); } catch (_) {}

    try { await _wsSub?.cancel(); } catch (_) {}
    _wsSub = null;

    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;

    try { await _player.stopPlayer(); } catch (_) {}
    try { await _player.closePlayer(); } catch (_) {}

    try { await _recorder.closeRecorder(); } catch (_) {}

    _connected = false;
  }
}