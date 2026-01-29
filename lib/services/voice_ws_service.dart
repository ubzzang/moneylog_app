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

  // rebuffer: 50ms(1600 bytes) 고정 프레임 전송을 위한 잔여 버퍼
  Uint8List _pending = Uint8List(0);

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

    _pending = Uint8List(0); // 시작할 때 잔여 버퍼 초기화

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
      _flushPendingPadToFrame(); // 말끝 자투리(잔여)를 버리지 않고 0-padding으로 1프레임(1600) 만들어 flush
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
    if (pcm.isEmpty) return;

    // 1) pending + new bytes 결합
    final combined = Uint8List(_pending.length + pcm.length);
    if (_pending.isNotEmpty) combined.setAll(0, _pending);
    combined.setAll(_pending.length, pcm);

    // 2) 1600 bytes(50ms) 단위로만 전송
    int off = 0;
    final int total = combined.length;

    while (off + frameBytes50ms <= total) {
      final chunk = combined.sublist(off, off + frameBytes50ms);
      _channel!.sink.add(chunk);
      off += frameBytes50ms;
    }

    // 3) 남은 잔여는 다음 입력과 합치기 위해 보관
    _pending = (off < total) ? combined.sublist(off) : Uint8List(0);
  }

  void _flushPendingPadToFrame() {
    if (!_connected || _channel == null) {
      _pending = Uint8List(0);
      return;
    }
    if (_pending.isEmpty) return;

    // 잔여를 0-padding 해서 정확히 1600 bytes로 만들고 1번 전송
    final padded = Uint8List(frameBytes50ms);
    padded.setAll(0, _pending); // 나머지는 자동 0
    _channel!.sink.add(padded);

    _pending = Uint8List(0);
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