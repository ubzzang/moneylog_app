import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();  // 추가!

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool? _usernameAvailable;  // 아이디 중복 체크 결과

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '회원가입',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'GmarketSans',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 문구
              Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'GmarketSans',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CashTalk과 함께 스마트하게 돈을 관리해보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard'
                ),
              ),
              const SizedBox(height: 32),

              // 이름 입력
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
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '홍길동',
                  prefixIcon: Icon(Icons.person_outline),
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
                    borderSide: BorderSide(color: Color(0xFF4C7BED), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 닉네임 입력 (추가!)
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
                    borderSide: BorderSide(color: Color(0xFF4C7BED), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 아이디 입력 (변경!)
              Text(
                '아이디',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: '아이디를 입력하세요',
                        prefixIcon: Icon(Icons.account_circle_outlined),
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
                          borderSide: BorderSide(color: Color(0xFF4C7BED), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        // 아이디 입력 변경시 중복체크 결과 초기화
                        setState(() {
                          _usernameAvailable = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _checkUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4C7BED),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('중복확인'),
                  ),
                ],
              ),
              // 중복 체크 결과 표시
              if (_usernameAvailable == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    '사용 가능한 아이디입니다.',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              if (_usernameAvailable == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    '이미 존재하는 아이디입니다.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),

              // 비밀번호 입력
              Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요.',
                  prefixIcon: Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
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
                    borderSide: BorderSide(color: Color(0xFF4C7BED), width: 2),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 20),

              // 비밀번호 확인
              Text(
                '비밀번호 확인',
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
                  hintText: '비밀번호를 다시 입력하세요',
                  prefixIcon: Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
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
                    borderSide: BorderSide(color: Color(0xFF4C7BED), width: 2),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
              ),
              // 비밀번호 일치 여부 표시
              if (_confirmPasswordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _passwordController.text == _confirmPasswordController.text
                        ? '비밀번호가 일치합니다.'
                        : '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(
                      color: _passwordController.text == _confirmPasswordController.text
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4C7BED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : Text(
                    '가입하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GmarketSans',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 로그인 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        color: Color(0xFF4C7BED),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아이디 중복 체크
  void _checkUsername() async {
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('아이디를 입력해주세요');
      return;
    }

    try {
      final response = await _authService.checkUsernameService(
        _usernameController.text.trim(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _usernameAvailable = data['available'] ?? false;
        });
      }
    } catch (e) {
      _showSnackBar('중복 확인에 실패했습니다.');
      print('중복 체크 에러: $e');
    }
  }

  // 회원가입 처리
  void _handleSignup() async {
    // 입력 검증
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('이름을 입력해주세요');
      return;
    }
    if (_nicknameController.text.trim().isEmpty) {
      _showSnackBar('닉네임을 입력해주세요');
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('아이디를 입력해주세요');
      return;
    }
    if (_usernameAvailable != true) {
      _showSnackBar('아이디 중복 확인을 해주세요');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('비밀번호가 일치하지 않습니다');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.registerService({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
      });

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('회원가입이 완료되었습니다!');
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      } else if (response.statusCode == 409) {
        _showSnackBar('이미 존재하는 아이디입니다.');
      } else {
        _showSnackBar('회원가입에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
      print('회원가입 에러: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}