import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:moneylog_app/screens/chat_screen.dart';
import 'package:moneylog_app/screens/password_verification_screen.dart';
import 'package:moneylog_app/screens/statistics_screen.dart';
import 'package:moneylog_app/services/auth_service.dart';
import 'package:moneylog_app/services/transaction_service.dart';
import 'package:moneylog_app/services/chat_service.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';
import 'package:moneylog_app/widgets/chat_input.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import '../widgets/login_banner.dart';
import '../widgets/menu_drawer.dart';
import 'package:moneylog_app/screens/register_screen.dart';
import 'package:moneylog_app/services/voice_ws_service.dart';


class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  const HomeScreen({super.key, this.isLoggedIn = false});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _chatController = TextEditingController();
  final VoiceWsService _voice = VoiceWsService();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Transaction> _transactions = [];
  Map<DateTime, double> _dailyExpenseMap = {};
  Map<DateTime, double> _dailyIncomeMap = {};

  // 월간 통계
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadMonthData(_focusedDay);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: '달력',
        showMyPageButton: true,
        onStatisticsPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StatisticsScreen(isLoggedIn: widget.isLoggedIn),
            ),
          ).then((_) {
            _loadTransactions(_selectedDay);
            _loadMonthData(_focusedDay);
          });
        },

        // ✅ 영랑추가
        onAddPressed: () async {
          final mid = await _authService.getMid();
          if (mid == null) return;

          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionFormPage(mid: mid),
            ),
          );

          if (changed == true) {
            _loadTransactions(_selectedDay);
            _loadMonthData(_focusedDay);
          }
        },
        // 마이페이지
        onMyPagePressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PasswordVerificationScreen(
                targetRoute: '/mypage',
              ),
            ),
          );
        },
        onChatPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          ).then((_) {
            _loadTransactions(_selectedDay);
            _loadMonthData(_focusedDay);
          });
        },
      ),
      endDrawer: MenuDrawer(isLoggedIn: widget.isLoggedIn),
      body: widget.isLoggedIn
          ? _buildLoggedInView()
          : _buildLoggedOutView(),
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendar(),
                _buildProgressBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3, // 거래내역 최소 높이
                  child: _buildTransactionList(),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1),
        ChatInput(
          controller: _chatController,
          onSend: _handleSendMessage,
          onMicStart: () async {
            await _voice.connectIfNeeded();
            await _voice.startCapture();
          },
          onMicStop: () async {
            await _voice.stopCapture();
          },
        ),
      ],
    );
  }

  // 캘린더 위젯
  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _loadTransactions(selectedDay);
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
            _loadMonthData(focusedDay);
          },
          calendarFormat: CalendarFormat.month,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final date = _normalize(day);
              final expense = _dailyExpenseMap[date];
              final income = _dailyIncomeMap[date];

              if (expense == null && income == null) return null;

              return Positioned(
                bottom: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (income != null && income > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                        margin: EdgeInsets.only(bottom: 1),
                        decoration: BoxDecoration(
                          color: Color(0xFF00B274).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${_formatVeryCompact(income)}',
                          style: TextStyle(
                            fontSize: 7,
                            color: Color(0xFF00B274),
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    if (expense != null && expense > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: Color(0xFFFE4040).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${_formatVeryCompact(expense)}',
                          style: TextStyle(
                            fontSize: 7,
                            color: Color(0xFFFE4040),
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: 2),
            titleTextStyle: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
            leftChevronIcon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF4C7BED).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_left,
                color: Color(0xFF4C7BED),
                size: 22,
              ),
            ),
            rightChevronIcon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF4C7BED).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Color(0xFF4C7BED),
                size: 22,
              ),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            weekendStyle: TextStyle(
              color: Color(0xFFFE4040).withOpacity(0.8),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: EdgeInsets.all(10),
            cellPadding: EdgeInsets.zero,
            todayDecoration: BoxDecoration(
              color: Color(0xFF4C7BED).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: Color(0xFF4C7BED),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF4C7BED),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4C7BED).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            selectedTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            defaultTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            weekendTextStyle: TextStyle(
              color: Color(0xFFFE4040).withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            outsideDaysVisible: false,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final expensePercent = _monthlyIncome > 0 ? (_monthlyExpense / _monthlyIncome) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 달 요약',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_focusedDay.year}년 ${_focusedDay.month}월',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '수입',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '+${_formatCompact(_monthlyIncome)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00B274),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '지출',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '-${_formatCompact(_monthlyExpense)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFE4040),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: expensePercent.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: expensePercent > 0.8
                          ? [Color(0xFFFE4040), Color(0xFFFF6B6B)]
                          : [Color(0xFF4C7BED), Color(0xFF6B8FFF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '잔액',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                '${_monthlyIncome - _monthlyExpense >= 0 ? '+' : ''}${_formatCompact(_monthlyIncome - _monthlyExpense)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _monthlyIncome - _monthlyExpense >= 0
                      ? Color(0xFF4C7BED)
                      : Color(0xFFFE4040),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompact(double amount) {
    final int intAmount = amount.toInt();
    // 쉼표 추가
    return intAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _formatVeryCompact(double amount) {
    final int intAmount = amount.toInt();
    // 쉼표 추가
    return intAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  void _handleSendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    _chatController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('처리 중이에요...'),
          ],
        ),
        duration: Duration(days: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final response = await _chatService.sendMessage(message);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? '처리되었습니다';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xFF213864),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply, style: TextStyle(color: Colors.white)),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    child: Text('확인', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
        _loadTransactions(_selectedDay);
        _loadMonthData(_focusedDay);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('처리에 실패했어요'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Text('네트워크 오류가 발생했습니다'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('챗봇 에러: $e');
    }
  }

  Widget _buildLoggedOutView() {
    return Column(
      children: [
        LoginBanner(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '로그인 후 거래내역과 챗봇을 사용해보세요',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 28, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              '${_selectedDay.month}월 ${_selectedDay.day}일\n거래내역이 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              '아래 입력창에서\n"점심값 8000원"이라고 말해보세요!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4C7BED), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: 50,
        ),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionItem(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type.toLowerCase() == 'income';

    // 카테고리별 아이콘
    IconData getIconForCategory(String category, bool isIncome) {
      if (isIncome) {
        // 수입 카테고리 아이콘
        switch (category) {
          case '월급':
            return Icons.account_balance_wallet;
          case '용돈':
            return Icons.card_giftcard;
          case '부수입':
            return Icons.monetization_on;
          default:
            return Icons.arrow_upward;
        }
      } else {
        // 지출 카테고리 아이콘
        switch (category) {
          case '외식':
            return Icons.restaurant;
          case '배달':
            return Icons.delivery_dining;
          case '교통':
            return Icons.directions_car;
          case '쇼핑':
            return Icons.shopping_bag;
          case '생활':
            return Icons.home;
          case '기타':
            return Icons.more_horiz;
          default:
            return Icons.wallet;
        }
      }
    }

    return Slidable(
      key: Key(transaction.id),
      // 왼쪽 스와이프
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          // 수정 버튼
          SlidableAction(
            onPressed: (context) async {
              await _editTransaction(transaction);
            },
            backgroundColor: Color(0xFF9E76D9),
            foregroundColor: Colors.white,
            label: '수정',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('삭제 확인'),
                    content: Text('이 거래내역을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                await _deleteTransaction(transaction.id);
              }
            },
            backgroundColor: Color(0xFFCC3433),
            foregroundColor: Colors.white,
            label: '삭제',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome
                  ? Color(0xFF00B274).withOpacity(0.1)
                  : Color(0xFFFE4040).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              getIconForCategory(transaction.category, isIncome),
              color: isIncome ? Color(0xFF00B274) : Color(0xFFFE4040),
              size: 22,
            ),
          ),
          title: Text(
            transaction.category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: transaction.memo.isNotEmpty
              ? Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              transaction.memo,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          )
              : null,
          trailing: Text(
            '${isIncome ? '+' : '-'}${transaction.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              color: isIncome ? Color(0xFF00B274) : Color(0xFFFE4040),
            ),
          ),
        ),
      ),
    );
  }

  // 거래내역 수정
  Future<void> _editTransaction(Transaction transaction) async {
    final mid = await _authService.getMid();
    if (mid == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormPage(
          mid: mid,
          transaction: transaction, // 수정할 거래내역 전달
        ),
      ),
    );

    if (changed == true) {
      _loadTransactions(_selectedDay);
      _loadMonthData(_focusedDay);
    }
  }

  //거래내역 삭제
  Future<void> _deleteTransaction(String transactionId) async {
    try {
      final response = await _transactionService.deleteTransaction(
        transactionId: transactionId,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('거래내역이 삭제되었습니다'),
              ],
            ),
            backgroundColor: Color(0xFF213864),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 데이터 새로고침
        _loadTransactions(_selectedDay);
        _loadMonthData(_focusedDay);
      } else if (response.statusCode == 403) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('본인의 거래내역만 삭제할 수 있습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 404) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래내역을 찾을 수 없습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('삭제 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadMonthData(DateTime focusedDay) async {
    final mid = await _authService.getMid();
    if (mid == null) return;

    final year = focusedDay.year;
    final month = focusedDay.month;
    final monthStr = '${year}-${month.toString().padLeft(2, '0')}';

    final Map<DateTime, double> expenseMap = {};
    final Map<DateTime, double> incomeMap = {};
    double totalIncome = 0;
    double totalExpense = 0;

    try {
      final response = await _transactionService.getListByMonth(
        mid: mid,
        month: monthStr,
        page: 1,
        size: 1000,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['dtoList'] ?? [];

        for (final e in list) {
          final amount = (e['amount'] as num).toDouble();
          final type = e['type'].toString().toUpperCase();
          final dateStr = e['date'] as String;
          final date = DateTime.parse(dateStr);
          final dateKey = _normalize(date);

          if (type == 'EXPENSE') {
            expenseMap[dateKey] = (expenseMap[dateKey] ?? 0) + amount;
            totalExpense += amount;
          } else if (type == 'INCOME') {
            incomeMap[dateKey] = (incomeMap[dateKey] ?? 0) + amount;
            totalIncome += amount;
          }
        }
      }
    } catch (e) {
      print('월간 데이터 로드 실패: $e');
    }

    setState(() {
      _dailyExpenseMap = expenseMap;
      _dailyIncomeMap = incomeMap;
      _monthlyIncome = totalIncome;
      _monthlyExpense = totalExpense;
    });

    _loadTransactions(_selectedDay);
  }

  void _loadTransactions(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final mid = await _authService.getMid();

      if (mid == null) {
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
            type: e['type'],
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
}

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