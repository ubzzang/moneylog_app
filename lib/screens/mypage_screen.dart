import 'package:flutter/material.dart';
import 'package:moneylog_app/screens/login_screen.dart';
import 'package:moneylog_app/widgets/common_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int? _id;
  String _username = '';
  String _name = '';
  String _originalNickname = '';
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _initMyPage();
  }

  Future<void> _initMyPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final id = prefs.getInt('mid');
      final username = prefs.getString('username');
      final name = prefs.getString('name');
      final nickname = prefs.getString('nickname');


      if (username == null || username.isEmpty) {
        setState(() => _errorMessage = '로그인이 필요합니다. 다시 로그인해주세요.');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
        return;
      }
      setState(() {
        _id = id;
        _username = username;
        _name = name ?? '';
        _originalNickname = nickname ?? '';
        _nicknameController.text = _originalNickname;
      });
      print('마이페이지 정보 로드 완료');
    } catch (e) {
      print('오류: $e');
      setState(() => _errorMessage = '회원 정보를 불러오지 못했습니다: $e');
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final isNicknameChanged =
        _nicknameController.text.trim() != _originalNickname;
    final isPasswordChanged =
        _newPasswordController.text.trim().isNotEmpty;

    if (!isNicknameChanged && !isPasswordChanged) {
      setState(() {
        _errorMessage = '변경된 내용이 없습니다.';
        _isLoading = false;
      });
      return;
    }

    if (isPasswordChanged &&
        _newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다.';
        _isLoading = false;
      });
      return;
    }

    final data = <String, dynamic>{};
    if (isNicknameChanged) data['nickname'] = _nicknameController.text.trim();
    if (isPasswordChanged) data['password'] = _newPasswordController.text;

    try {
      await _memberService.changeInfo(data);

      // SharedPreferences 업데이트
      if (isNicknameChanged) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nickname', _nicknameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원정보가 수정되었습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      await _initMyPage();
    } catch (e) {
      setState(() => _errorMessage = '회원정보 수정 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '회원탈퇴',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '정말 탈퇴하시겠습니까?\n탈퇴 시 모든 정보가 삭제됩니다.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '탈퇴',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _memberService.deleteMember(_id!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '회원 탈퇴 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: '마이페이지',
        showBackButton: true,
        showActions: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '내 정보',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'GmarketSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '회원 정보를 확인하고 수정할 수 있습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 32),

            // 아이디 (읽기 전용)
            Text(
              '아이디',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _username),
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 이름 (읽기 전용)
            Text(
              '이름',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _name),
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 닉네임 (수정 가능)
            Text(
              '닉네임',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: '닉네임을 입력하세요',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Color(0xFF4C7BED), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 비밀번호 변경 섹션
            Text(
              '비밀번호 변경',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'GmarketSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '비밀번호를 변경하지 않으려면 비워두세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 16),

            // 새 비밀번호
            Text(
              '새 비밀번호',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                hintText: '새 비밀번호를 입력하세요',
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Color(0xFF4C7BED), width: 2),
                ),
              ),
              obscureText: _obscureNewPassword,
            ),
            const SizedBox(height: 20),

            // 새 비밀번호 확인
            Text(
              '새 비밀번호 확인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                hintText: '새 비밀번호를 다시 입력하세요',
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Color(0xFF4C7BED), width: 2),
                ),
              ),
              obscureText: _obscureConfirmPassword,
            ),

            // 비밀번호 일치 여부 표시
            if (_newPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  _newPasswordController.text ==
                      _confirmPasswordController.text
                      ? '비밀번호가 일치합니다.'
                      : '비밀번호가 일치하지 않습니다.',
                  style: TextStyle(
                    color: _newPasswordController.text ==
                        _confirmPasswordController.text
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 에러 메시지
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 수정 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4C7BED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '회원정보 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'GmarketSans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 회원탈퇴 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _handleDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '회원탈퇴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'GmarketSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}