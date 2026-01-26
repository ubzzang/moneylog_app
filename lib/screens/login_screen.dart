import 'package:flutter/material.dart';
import 'dart:convert';
import 'home_screen.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF4C7BED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),

                // 타이틀
                Text(
                  '캐시톡',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'GmarketSans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI와 함께하는 스마트 가계부',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 48),

                // 아이디 입력
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '아이디',
                    hintText: '아이디를 입력하세요',
                    prefixIcon: Icon(Icons.face_4_outlined),
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
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
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
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 24),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                      '로그인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'GmarketSans',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호 찾기
                TextButton(
                  onPressed: () {
                    _showSnackBar('비밀번호 찾기 기능은 준비중입니다');
                  },
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '또는',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),

                // 회원가입 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF4C7BED),
                      side: BorderSide(color: Color(0xFF4C7BED), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '회원가입',
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
        ),
      ),
    );
  }

  // 로그인 처리
  void _handleLogin() async {
    // 입력 검증
    if (_usernameController.text.trim().isEmpty) {
      _showSnackBar('아이디를 입력해주세요');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showSnackBar('비밀번호를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API 호출
      final response = await _authService.loginService({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 토큰 저장
        if (data['token'] != null) {
          await _authService.saveToken(data['token']);
        }

        if (data['id'] != null) {
          await _authService.saveMid(data['id']);
        }
        _showSnackBar('로그인에 성공했습니다.');

        // 로그인 후 홈화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(isLoggedIn: true),  // 수정!
          ),
        );
      } else {
        // 로그인 실패
        _showSnackBar('아이디 또는 비밀번호가 올바르지 않습니다.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
      }
      print('로그인 에러: $e');
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}