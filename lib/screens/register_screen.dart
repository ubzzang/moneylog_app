import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/transaction_service.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';
import 'package:moneylog_app/screens/home_screen.dart'; // Transaction 클래스 import

enum TxType { income, expense }

class TransactionFormPage extends StatefulWidget {
  final int mid;
  final Transaction? transaction; // 수정할 거래내역 (null이면 신규 등록)

  const TransactionFormPage({
    super.key,
    required this.mid,
    this.transaction, // 선택적 파라미터
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  // 1) 수입/지출 토글 상태
  TxType _type = TxType.expense;

  // 2) 날짜/카테고리/금액/메모 상태
  DateTime _date = DateTime.now();
  String? _category;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _memoCtrl = TextEditingController();

  // 3) 카테고리 목록 (요구사항 그대로)
  static const List<String> _incomeCategories = ['월급', '용돈', '부수입', '기타'];
  static const List<String> _expenseCategories = ['외식', '배달', '교통', '쇼핑', '생활', '기타'];

  List<String> get _currentCategories =>
      _type == TxType.income ? _incomeCategories : _expenseCategories;

  String get _titleText => widget.transaction == null
      ? (_type == TxType.income ? '수입등록' : '지출등록')
      : (_type == TxType.income ? '수입수정' : '지출수정');

  // (공통 컬러)
  static const Color _primaryBlue = Color(0xFF3C76F1);
  static const Color _skyBlueSelected = Color(0xFFBFE6FF);
  static const Color _darkText = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 데이터 로드
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _date = tx.date;
      _amountCtrl.text = tx.amount.toInt().toString();
      _memoCtrl.text = tx.memo;
      _category = tx.category;
      _type = tx.type.toUpperCase() == 'INCOME' ? TxType.income : TxType.expense;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  // 날짜 선택기
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),

      builder: (context, child) {
        return Theme(
          data: ThemeData(
            fontFamily: 'Pretendard',
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C7BED),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4C7BED),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() => _date = picked);
  }

  void _switchType(TxType next) {
    if (_type == next) return;
    setState(() {
      _type = next;
      if (_category == null || !_currentCategories.contains(_category)) {
        _category = null;
      }
    });
  }

  Future<void> _submit() async {
    final amountText = _amountCtrl.text.trim();
    final amount = int.tryParse(amountText);

    if (_category == null) {
      _toast('카테고리를 선택해주세요.');
      return;
    }
    if (amount == null || amount <= 0) {
      _toast('금액을 올바르게 입력해주세요. (숫자만)');
      return;
    }

    final dateText =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    final typeText = _type == TxType.income ? 'INCOME' : 'EXPENSE';

    final payload = {
      "mid": widget.mid,
      "type": typeText,
      "category": _category,
      "date": dateText,
      "amount": amount,
      "memo": _memoCtrl.text.trim(),
    };

    try {
      var res;

      // 수정 모드인지 신규 등록인지 구분
      if (widget.transaction != null) {
        // 수정 모드
        payload['id'] = int.parse(widget.transaction!.id);
        res = await TransactionService().updateTransaction(
          transaction: payload,
        );
      } else {
        // 신규 등록 모드
        res = await TransactionService().register(payload);
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        _toast(widget.transaction == null ? '등록 완료!' : '수정 완료!');
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        _toast(widget.transaction == null ? '등록 실패: ${res.statusCode}' : '수정 실패: ${res.statusCode}');
      }
    } catch (e) {
      _toast('네트워크 오류가 발생했어요.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Pretendard'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonAppBar(
        title: _titleText, // 수입등록/지출등록/수입수정/지출수정
        showBackButton: true,
        showActions: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 토글(수입등록 / 지출등록)
              _buildTypeSelector(),
              const SizedBox(height: 16),

              // 날짜
              _LabeledRow(
                label: '날짜',
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _inputDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateText,
                          style: const TextStyle(fontFamily: 'Pretendard'),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 카테고리 드롭다운
              _LabeledRow(
                label: '카테고리',
                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.white,
                  ),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _category,
                    items: _currentCategories
                        .map(
                          (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontFamily: 'Pretendard'),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                    decoration: _inputDecoration(hintText: '카테고리 선택'),
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      color: _darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 금액
              _LabeledRow(
                label: '금액',
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hintText: '숫자만 입력'),
                  style: const TextStyle(fontFamily: 'Pretendard', color: _darkText),
                ),
              ),
              const SizedBox(height: 14),

              // 메모
              _LabeledRow(
                label: '메모',
                child: TextFormField(
                  controller: _memoCtrl,
                  maxLines: 6,
                  decoration: _inputDecoration(hintText: '메모를 입력하세요'),
                  style: const TextStyle(fontFamily: 'Pretendard', color: _darkText),
                ),
              ),
              const SizedBox(height: 24),

              // 하단 버튼들
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Color(0xFFFFFFFF),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        foregroundColor: _darkText,
                        textStyle: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B274),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(widget.transaction == null ? '등록' : '수정'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final isIncome = _type == TxType.income;

    ButtonStyle style(bool selected) {
      return ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF3C76F1) : Colors.grey[300],
        foregroundColor: selected ? Colors.white : Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _switchType(TxType.income),
            style: style(isIncome),
            child: const Text(
              '수입등록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _switchType(TxType.expense),
            style: style(!isIncome),
            child: const Text(
              '지출등록',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Pretendard',
        color: Color(0xFF9CA3AF),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

// 나머지 _LabeledRow 위젯은 그대로 유지
class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}