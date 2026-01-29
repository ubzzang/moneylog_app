import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;


class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  // 음성 토글용 콜백
  final Future<void> Function()? onMicStart;
  final Future<void> Function()? onMicStop;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMicStart,
    this.onMicStop,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isListening = false;

  Future<void> _toggleListening() async {
    debugPrint('[UI] onMicStart=${widget.onMicStart != null}, onMicStop=${widget.onMicStop != null}');
    debugPrint('[UI] before setState, next=${!_isListening}');


    if (widget.onMicStart == null || widget.onMicStop == null) return;

    final next = !_isListening;

    // ✅ 1) UI를 먼저 토글 (즉시 변화)
    setState(() => _isListening = next);

    // ✅ 2) 실제 start/stop은 await 없이 실행(멈춰도 UI는 반응)
    try {
      if (next) {
        widget.onMicStart!().catchError((e, st) {
          debugPrint('[UI] onMicStart failed: $e');
          if (mounted) setState(() => _isListening = false);
        });
      } else {
        widget.onMicStop!().catchError((e, st) {
          debugPrint('[UI] onMicStop failed: $e');
          if (mounted) setState(() => _isListening = true);
        });
      }
    } catch (_) {
      // 동기 예외만 여기로 옴(대부분 async 예외는 여기로 안 옴)
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 기능 시작/종료에 실패했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 음성인식 버튼
            Container(
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _toggleListening,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : Colors.grey[600],
                ),
                padding: EdgeInsets.all(8),
              ),
            ),
            SizedBox(width: 8),

            // 텍스트 입력창
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: _isListening ? '듣고 있어요...' : '메시지를 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            SizedBox(width: 8),

            // 전송 버튼
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF4C7BED),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: widget.onSend,
                icon: Icon(Icons.send, color: Colors.white),
                padding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}