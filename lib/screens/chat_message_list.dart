import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;  // 추가!

  const ChatMessageList({
    super.key,
    required this.messages,
    this.isTyping = false,  // 추가!
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: messages.length + (isTyping ? 1 : 0),  // 타이핑 중이면 +1
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageItem(messages[index]);
      },
    );
  }

  // 타이핑 인디케이터
  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF3498DB),
            radius: 18,
            child: Icon(
              Icons.smart_toy,
              size: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4),
                _buildDot(1),
                SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 타이핑 점
  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Opacity(
          opacity: (value * 2 - index * 0.3).clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // 비어있을 때
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'AI와 대화를 시작해보세요',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '예: "오늘 점심값 8000원 썼어"\n"이번 달 지출 알려줘"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 아이템
  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'assets/images/cat.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF3498DB) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 18,
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}