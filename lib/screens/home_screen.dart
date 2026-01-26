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
      text: '안녕하세요! 필요한 기능을 말씀해주세요',
      isUser: false,
    ),
  ];
  bool _isTyping = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Transaction> _transactions = [];
  Map<DateTime, double> _dailyExpenseMap = {};
  Map<DateTime, double> _dailyIncomeMap = {};
  bool _showChatInsteadOfList = true;

  DateTime _normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  // 거래내역은 토스트로 피드백받음
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  // 캘린더 load
  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _showChatInsteadOfList = false;
      _loadTransactions(_selectedDay);
      _loadWeeklyTransactions(_focusedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4C7BED),
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
          IconButton(
            icon: Icon(_showChatInsteadOfList ? Icons.list : Icons.chat),
            onPressed: () {
              setState(() {
                _showChatInsteadOfList = !_showChatInsteadOfList;
              });
            },
          ),
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
            _buildCalendar(),
            const Divider(height: 1),

            Expanded(
              child: _showChatInsteadOfList
                  ? ChatMessageList(
                messages: _messages,
                isTyping: _isTyping,
              )
                  : _buildTransactionList(),
            ),
          ]
          else ...[
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
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,

      selectedDayPredicate: (day) =>
          isSameDay(_selectedDay, day),

      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _loadTransactions(selectedDay);
      },

      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadWeeklyTransactions(focusedDay);
      },

      calendarFormat: CalendarFormat.week,

      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final date = _normalize(day);
          final expense = _dailyExpenseMap[date];
          final income = _dailyIncomeMap[date];

          if (expense == null && income == null) return null;

          return Positioned(
            bottom: 2,
            child: Column(
              children: [
                if (expense != null && expense > 0)
                  Text(
                    '-${expense.toInt()}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (income != null && income > 0)
                  Text(
                    '+${income.toInt()}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        },
      ),



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
          color: Color(0xFF4C7BED),
          shape: BoxShape.circle,
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
          backgroundColor: isIncome ? Colors.green[100] : Colors.red[50],
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.payment_sharp,
            color: isIncome ? const Color(0xFF3C76F1) : const Color(0xFFFB5D76),
          ),
        ),
        title: Text(transaction.category),
        subtitle: Text(transaction.memo,
          style: TextStyle(
            fontFamily: 'Pretendard',
          )),
        trailing: Text(
          '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}원',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? const Color(0xFF3C76F1) :  const Color(0xFFFB5D76),
          ),
        ),
      ),
    );
  }

  // 메시지 전송
  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    _chatController.clear();

    // 로그인 전만 사용자 메시지 보여줌
    if (!widget.isLoggedIn) {
      setState(() {
        _messages.add(ChatMessage(text: userMessage, isUser: true));
        _isTyping = true;
      });
    } else {
      setState(() {
        _isTyping = true;
      });
    }

    try {
      final response = await _chatService.sendMessage(userMessage);
      if (!mounted) return;

      final data = jsonDecode(response.body);
      final reply = data['reply'] ?? '처리되었습니다';

      setState(() {
        _isTyping = false;
      });

      if (response.statusCode == 200) {
        if (widget.isLoggedIn) {
          //  로그인 후: 토스트 + UI 갱신
          _showToast(reply);
          _loadTransactions(_selectedDay);
          _loadWeeklyTransactions(_focusedDay);
        } else {
          //  로그인 전: 챗봇 말풍선
          setState(() {
            _messages.add(ChatMessage(
              text: reply,
              isUser: false,
            ));
          });
        }
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

      // void _loadMonthlyTransactions(DateTime month) async {
  //   final mid = await _authService.getMid();
  //   if (mid == null) return;
  //
  //   final response = await _transactionService.getListByDay(
  //     mid: mid,
  //     year: month.year,
  //     month: month.month,
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body);
  //     final List list = body['dtoList'] ?? [];
  //
  //     final Map<DateTime, double> expenseMap = {};
  //     final Map<DateTime, double> incomeMap = {};
  //
  //     for (final e in list) {
  //       final date = _normalize(DateTime.parse(e['date']));
  //       final amount = (e['amount'] as num).toDouble();
  //       final type = e['type'].toString().toUpperCase();
  //
  //       if (type == 'EXPENSE') {
  //         expenseMap[date] = (expenseMap[date] ?? 0) + amount;
  //       } else if (type == 'INCOME') {
  //         incomeMap[date] = (incomeMap[date] ?? 0) + amount;
  //       }
  //     }
  //
  //     setState(() {
  //       _dailyExpenseMap = expenseMap;
  //       _dailyIncomeMap = incomeMap;
  //     });
  //   }
  // }


  // 주간 데이터 로딩
  void _loadWeeklyTransactions(DateTime focusedDay) async {
    final mid = await _authService.getMid();
    if (mid == null) return;

    final startOfWeek =
    focusedDay.subtract(Duration(days: focusedDay.weekday % 7));

    final Map<DateTime, double> expenseMap = {};
    final Map<DateTime, double> incomeMap = {};

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dateKey = _normalize(day);

      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final response = await _transactionService.getListByDay(
        mid: mid,
        date: dateStr,
        page: 1,
        size: 100,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['dtoList'] ?? [];

        for (final e in list) {
          final amount = (e['amount'] as num).toDouble();
          final type = e['type'].toString().toUpperCase();

          if (type == 'EXPENSE') {
            expenseMap[dateKey] = (expenseMap[dateKey] ?? 0) + amount;
          } else if (type == 'INCOME') {
            incomeMap[dateKey] = (incomeMap[dateKey] ?? 0) + amount;
          }
        }
      }
    }

    setState(() {
      _dailyExpenseMap = expenseMap;
      _dailyIncomeMap = incomeMap;
    });
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