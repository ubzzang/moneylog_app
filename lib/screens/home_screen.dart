import 'package:flutter/material.dart';
import 'package:moneylog_app/screens/chat_message_list.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/chat_message.dart';
import '../widgets/login_banner.dart';
import '../widgets/chat_input.dart';
import '../widgets/menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;

  const HomeScreen({super.key, this.isLoggedIn = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
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
              'CashTalk',
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
            // 로그인 O: 캘린더 + 거래내역 + 챗봇
            _buildCalendar(),
            Divider(height: 1),
            Expanded(child: _buildTransactionList()),
          ] else ...[
            // 로그인 X: 로그인 배너 + 챗봇만
            LoginBanner(),
            Expanded(child: ChatMessageList(messages: _messages)),
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
            // TODO: 선택한 날짜의 거래내역 API 호출
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
  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
    });
    _chatController.clear();

    // TODO: API 호출
    // 임시 응답
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (widget.isLoggedIn) {
            _messages.add(ChatMessage(
              text: '거래 내역을 기록했어요! 😊',
              isUser: false,
            ));
            // 임시: 테스트 거래내역 추가
            _transactions.add(Transaction(
              id: DateTime.now().toString(),
              date: _selectedDay,
              type: 'expense',
              amount: 8000,
              category: '식비',
              memo: userMessage,
            ));
          } else {
            _messages.add(ChatMessage(
              text: '로그인하시면 거래내역을 저장할 수 있어요!',
              isUser: false,
            ));
          }
        });
      }
    });
  }

  // 거래내역 로드 (API 호출)
  void _loadTransactions(DateTime date) {
    // TODO: API에서 데이터 가져오기
    print('${date.year}-${date.month}-${date.day} 거래내역 로드');
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