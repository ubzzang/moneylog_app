import 'package:flutter/material.dart';
import 'package:moneylog_app/screens/chat_message_list.dart';
import 'package:moneylog_app/screens/example_prompts_widget.dart';
import 'package:moneylog_app/screens/statistics_screen.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../widgets/chat_input.dart';
import '../services/chat_service.dart';
import '../services/voice_ws_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final VoiceWsService _voice = VoiceWsService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '자연스런 대화로 수입과 지출을 관리하세요!😊',
      isUser: false,
    ),
  ];
  bool _isTyping = false;
  bool _showExamples = true; // 예시 프롬프트 표시 여부

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExamplePromptVisibility();

    _voice.onError = (e) {
      if (!mounted) return;
      _showToast(e);
    };

    _voice.onEvent = (evt) {
      if (!mounted) return;
      final type = (evt['type'] ?? '').toString();

      // 서버 STT 결과(유저 메시지로 표시)
      if (type == 'stt_final') {
        final text = (evt['text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          setState(() {
            _messages.add(ChatMessage(text: text, isUser: true));
            _isTyping = true; // 이후 llm 처리 중일 가능성
          });
          _hideExamplesForToday(); // 메시지 전송 시 예시 숨김
          // 답변 후 스크롤
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }

      // 서버 LLM 최종 응답(봇 메시지로 표시)
      if (type == 'llm_final') {
        final reply = (evt['reply'] ?? '').toString();
        setState(() {
          _messages.add(ChatMessage(text: reply, isUser: false));
          _isTyping = false;
        });
        // 답변 후 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      // 선택: llm_partial/status 등을 받으면 _isTyping=true로 표시 가능
    };
  }

  // 하루 기준 프롬프트 표시
  Future<void> _loadExamplePromptVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final lastHiddenDate = prefs.getString('example_prompts_hidden_date');
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    // 저장된 날짜가 오늘이 아니면 예시 프롬프트 표시
    if (lastHiddenDate != today) {
      setState(() {
        _showExamples = true;
      });
    } else {
      setState(() {
        _showExamples = false;
      });
    }
  }

  // 오늘 하루 동안 예시 프롬프트 숨김
  Future<void> _hideExamplesForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    await prefs.setString('example_prompts_hidden_date', today);

    setState(() {
      _showExamples = false;
    });
  }

  // 입력창에 복사됨
  void _handlePromptTap(String prompt) {
    setState(() {
      _chatController.text = prompt;
    });
    _hideExamplesForToday(); // 하루 동안 숨김
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: '챗봇',
        showBackButton: true,
        showActions: false,
      ),

      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ChatMessageList(
                  messages: _messages,
                  isTyping: _isTyping,
                  scrollController: _scrollController,
                ),
                // 예시 프롬프트는 초기 상태에만 표시
                if (_showExamples && _messages.length == 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ExamplePromptsWidget(
                      onPromptTap: _handlePromptTap,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1),
          ChatInput(
            controller: _chatController,
            onSend: _sendMessage,
            onMicStart: () async {
              await _voice.startCapture();   // 토글 ON: 계속 캡처/전송
            },
            onMicStop: () async {
              await _voice.stopCapture();    // 토글 OFF: 캡처 중단 + audio_end
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    _chatController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
    });
    _hideExamplesForToday(); // 하루동안 숨김!!!!!!!!

    // 스크롤을 최하단으로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final response = await _chatService.sendMessage(userMessage);
      if (!mounted) return;

      final data = jsonDecode(response.body);
      final reply = data['reply'] ?? '처리되었습니다';

      setState(() {
        _isTyping = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _messages.add(ChatMessage(
            text: reply,
            isUser: false,
          ));
        });

        // 답변 후 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showToast('처리에 실패했어요');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;
      });

      _showToast('네트워크 오류가 발생했습니다');
      print('채팅 에러: $e');
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}