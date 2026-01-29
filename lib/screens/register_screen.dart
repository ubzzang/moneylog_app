import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/transaction_service.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';

enum TxType { income, expense }

class TransactionFormPage extends StatefulWidget {
  final int mid;
  const TransactionFormPage({super.key, required this.mid});

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

  String get _titleText => _type == TxType.income ? '수입등록' : '지출등록';

  // (공통 컬러)
  static const Color _primaryBlue = Color(0xFF157AFF);
  static const Color _skyBlueSelected = Color(0xFFBFE6FF); // (3번) 탭 선택 색: 하늘색
  static const Color _darkText = Color(0xFF2C3E50);

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
              primary: Color(0xFF4C7BED),   // 파란 포인트
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
            dialogBackgroundColor: Colors.white, // 흰 배경
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF4C7BED), // 취소/확인 파란색
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
      final res = await TransactionService().register(payload);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _toast('등록 완료!');
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        _toast('등록 실패: ${res.statusCode}');
      }
    } catch (e) {
      _toast('네트워크 오류가 발생했어요.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Pretendard'))), // (6번)
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.grey[50], // (2번) 배경 Home 톤에 맞춤
      appBar: CommonAppBar(
        title: _titleText,      // 수입등록/지출등록 제목 유지
        showBackButton: true,   // 왼쪽 뒤로가기
        showActions: false,     // ✅ 오른쪽 아이콘(+/채팅) 제거
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 토글(수입등록 / 지출등록)
              _TypeToggle(
                type: _type,
                onIncome: () => _switchType(TxType.income),
                onExpense: () => _switchType(TxType.expense),
                selectedColor: _skyBlueSelected, // (3번)
              ),
              const SizedBox(height: 16),

              // 날짜
              _LabeledRow(
                label: '날짜',
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _inputDecoration(), // (4번) 포커스 파란 테두리
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateText,
                          style: const TextStyle(fontFamily: 'Pretendard'), // (6번)
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
                    canvasColor: Colors.white, // 펼친 메뉴 배경 흰색
                  ),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // 메뉴 폭 = 버튼 폭
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
                  decoration: _inputDecoration(hintText: '숫자만 입력'), // (4번)
                  style: const TextStyle(fontFamily: 'Pretendard', color: _darkText), // (6번)
                ),
              ),
              const SizedBox(height: 14),

              // 메모
              _LabeledRow(
                label: '메모',
                child: TextFormField(
                  controller: _memoCtrl,
                  maxLines: 6,
                  decoration: _inputDecoration(hintText: '메모를 입력하세요'), // (4번)
                  style: const TextStyle(fontFamily: 'Pretendard', color: _darkText), // (6번)
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
                          borderRadius: BorderRadius.circular(10), // (5번) 곡선 축소
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        foregroundColor: _darkText,
                        textStyle: const TextStyle(
                          fontFamily: 'Pretendard', // (6번)
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
                        backgroundColor: Color(0xFF4C7BED), // (8번) 등록 버튼 파랑
                        foregroundColor: Colors.white, // (8번) 글자 흰색
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // (5번) 곡선 축소
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Pretendard', // (6번)
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('등록'),
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

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Pretendard', // (6번)
        color: Color(0xFF9CA3AF),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // (5번) 너무 둥글지 않게
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 2), // (4번) 클릭 시 파란 테두리
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: Colors.white, // (2번) 입력폼은 흰색
    );
  }
}

// ---------------- UI 컴포넌트들 ----------------

class _TypeToggle extends StatelessWidget {
  final TxType type;
  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final Color selectedColor;

  const _TypeToggle({
    required this.type,
    required this.onIncome,
    required this.onExpense,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TxType.income;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              text: '수입등록',
              selected: isIncome,
              onTap: onIncome,
              selectedColor: selectedColor,
            ),
          ),
          Expanded(
            child: _ToggleButton(
              text: '지출등록',
              selected: !isIncome,
              onTap: onExpense,
              selectedColor: selectedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ToggleButton({
    required this.text,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white, // (3번) 선택 시 하늘색
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'GmarketSans', // (6번)
            fontSize: 15, // (7번) 탭 글자 키움
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }
}

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
                fontFamily: 'Pretendard', // (6번)
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
