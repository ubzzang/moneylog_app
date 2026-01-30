import 'package:flutter/material.dart';
import 'package:moneylog_app/services/auth_service.dart';
import 'package:moneylog_app/services/transaction_service.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../widgets/menu_drawer.dart';

class StatisticsScreen extends StatefulWidget {
  final bool isLoggedIn;
  const StatisticsScreen({super.key, this.isLoggedIn = true});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();

  String _viewMode = 'daily'; // daily or monthly
  DateTime _selectedDate = DateTime.now();

  List<Transaction> _transactions = [];
  Map<String, double> _categoryExpenses = {};
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = false;

  final List<Color> _categoryColors = [
    Color(0xFF4C7BED),
    Color(0xFF5755BA),
    Color(0xFFFB5D76),
    Color(0xFF0296FC),
    Color(0xFF9E76D9),
    Color(0xFF94A5D1),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: '통계',
        showBackButton: true,
        showActions: false,
      ),
      //endDrawer: MenuDrawer(isLoggedIn: widget.isLoggedIn),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildViewModeSelector(),
            _buildDateNavigator(),
            _buildSummaryCards(),
            if (_viewMode == 'monthly') ...[
              _buildCategoryAnalysis(),
              _buildCharts(),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 일간/월간 뷰 선택
  Widget _buildViewModeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _viewMode = 'daily';
                  _loadData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == 'daily' ? Color(0xFF3C76F1) : Colors.grey[300],
                foregroundColor: _viewMode == 'daily' ? Colors.white : Colors.black,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('일간뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _viewMode = 'monthly';
                  _loadData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == 'monthly' ? Color(0xFF4C7BED) : Colors.grey[300],
                foregroundColor: _viewMode == 'monthly' ? Colors.white : Colors.black,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('월간뷰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 네비게이터
  Widget _buildDateNavigator() {
    final dateText = _viewMode == 'daily'
        ? '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일'
        : '${_selectedDate.year}년 ${_selectedDate.month}월';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Color(0xFF4C7BED)),
            onPressed: () {
              setState(() {
                if (_viewMode == 'daily') {
                  _selectedDate = _selectedDate.subtract(Duration(days: 1));
                } else {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                }
                _loadData();
              });
            },
          ),
          Text(
            dateText,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Color(0xFF4C7BED)),
            onPressed: () {
              setState(() {
                if (_viewMode == 'daily') {
                  _selectedDate = _selectedDate.add(Duration(days: 1));
                } else {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                }
                _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  // 요약 카드
  Widget _buildSummaryCards() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard('총 수입', _totalIncome, Color(0xFF00B274)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('총 지출', _totalExpense, Color(0xFFFE4040)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            '${_formatCurrency(amount)}원',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리별 분석 (월간뷰만)
  Widget _buildCategoryAnalysis() {
    if (_categoryExpenses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            '지출 내역이 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sortedCategories = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소비 분석',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          // 카테고리별 막대
          ...sortedCategories.take(6).map((entry) {
            final index = sortedCategories.indexOf(entry);
            final percent = (_totalExpense > 0) ? (entry.value / _totalExpense * 100) : 0;
            final color = _categoryColors[index % _categoryColors.length];

            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent / 100,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(entry.value)}원',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 차트 (월간뷰만)
  Widget _buildCharts() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수입 / 지출 비교',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: [_totalIncome, _totalExpense].reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return Text('수입', style: TextStyle(fontSize: 14));
                        if (value == 1) return Text('지출', style: TextStyle(fontSize: 14));
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _totalIncome,
                        color: Color(0xFF6585F6),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _totalExpense,
                        color: Color(0xFFF765A3),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 데이터 로드
  void _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final mid = await _authService.getMid();
    if (mid == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = _viewMode == 'daily'
          ? await _transactionService.getListByDay(
        mid: mid,
        date: _formatDate(_selectedDate),
        page: 1,
        size: 100,
      )
          : await _transactionService.getListByMonth(
        mid: mid,
        month: _formatMonth(_selectedDate),
        page: 1,
        size: 1000,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['dtoList'] ?? [];

        double income = 0;
        double expense = 0;
        Map<String, double> categories = {};

        for (final e in list) {
          final amount = (e['amount'] as num).toDouble();
          final type = e['type'].toString().toUpperCase();
          final category = e['category'] ?? '기타';

          if (type == 'INCOME') {
            income += amount;
          } else if (type == 'EXPENSE') {
            expense += amount;
            categories[category] = (categories[category] ?? 0) + amount;
          }
        }

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
          _totalIncome = income;
          _totalExpense = expense;
          _categoryExpenses = categories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
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