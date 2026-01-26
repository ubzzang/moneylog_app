import 'package:flutter/material.dart';
import 'package:moneylog_app/screens/chat_message_list.dart';
import 'package:moneylog_app/services/auth_service.dart';
import 'package:moneylog_app/services/transaction_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import '../widgets/login_banner.dart';
import '../widgets/chat_input.dart';
import '../widgets/menu_drawer.dart';
import '../services/chat_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  const HomeScreen({super.key, this.isLoggedIn = false});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '안녕하세요! 오늘 지출을 말씀해주세요',
      isUser: false,
    ),
  ];
  bool _isTyping = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Transaction> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF3498DB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, size: 28),
            SizedBox(width: 8),
            Text(
              '캐시톡',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'GmarketSans',
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: MenuDrawer(isLoggedIn: widget.isLoggedIn),
      body: Column(
        children: [
          // 로그인 여부에 따라 다른 화면
          if (widget.isLoggedIn) ...[
            // 로그인 했을때
            _buildCalendar(),
            Divider(height: 1),
            Expanded(
              child: ChatMessageList(
                messages: _messages,
                isTyping: _isTyping,
              ),
            ),
          ] else ...[
            // 로그인 안했을때
            LoginBanner(),
            Expanded(
              child: ChatMessageList(
                messages: _messages,
                isTyping: _isTyping,
              ),
            ),
          ],

          Divider(height: 1),

          // 챗봇 입력창 (공통)
          ChatInput(
            controller: _chatController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  // 캘린더 위젯
  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _loadTransactions(selectedDay);
          });
        },
        calendarFormat: CalendarFormat.week,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF3498DB),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  // 거래내역 리스트
  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '${_selectedDay.month}월 ${_selectedDay.day}일\n거래내역이 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Text(
              '챗봇에게 "점심값 8000원"이라고\n말해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3498DB),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  // 거래내역 개별 아이템
  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.category),
        subtitle: Text(transaction.memo),
        trailing: Text(
          '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}원',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  // 메시지 전송
  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
    });
    _chatController.clear();

    try {
      final response = await _chatService.sendMessage(userMessage);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: data['reply'] ?? '응답을 받았습니다.',
            isUser: false,
          ));
        });

        // 거래내역 저장 성공시 새로고침
        if (widget.isLoggedIn) {
          _loadTransactions(_selectedDay);
        }
      } else {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: '에러가 발생했습니다.',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: '네트워크 오류가 발생했습니다.',
            isUser: false,
          ));
        });
      }
      print('채팅 에러: $e');
    }
  }

  // 거래내역 로드 (API 호출)
  void _loadTransactions(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final mid = await _authService.getMid();

      if (mid == null) {
        print('mid 없음 - 로그인 필요');
        setState(() {
          _transactions = [];
        });
        return;
      }

      final response = await _transactionService.getListByDay(
        mid: mid,
        date: dateStr,
        page: 1,
        size: 100,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['dtoList'] ?? [];

        final parsed = list.map((e) {
          return Transaction(
            id: e['id'].toString(),
            date: DateTime.parse(e['date']),
            type: e['type'], // INCOME / EXPENSE
            amount: (e['amount'] as num).toDouble(),
            category: e['category'] ?? '기타',
            memo: e['memo'] ?? '',
          );
        }).toList();

        setState(() {
          _transactions = parsed;
        });
      } else {
        setState(() {
          _transactions = [];
        });
      }
    } catch (e) {
      print('거래내역 로드 실패: $e');
      setState(() {
        _transactions = [];
      });
    }
  }



  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}

// 거래 데이터 모델
class Transaction {
  final String id;
  final DateTime date;
  final String type;
  final double amount;
  final String category;
  final String memo;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.memo,
  });
}