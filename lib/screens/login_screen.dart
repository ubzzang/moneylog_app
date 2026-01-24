import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
                    color: Color(0xFF3498DB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(height: 24),

                // 타이틀
                Text(
                  'CashTalk',
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
                  ),
                ),
                const SizedBox(height: 48),

                // 이메일 입력
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
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
                      borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                      borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3498DB),
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
                    // TODO: 비밀번호 찾기
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
                      foregroundColor: Color(0xFF3498DB),
                      side: BorderSide(color: Color(0xFF3498DB), width: 2),
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
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('이메일을 입력해주세요');
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
      // TODO: 실제 API 호출
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/login'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': _emailController.text,
      //     'password': _passwordController.text,
      //   }),
      // );

      // 임시: 2초 대기
      await Future.delayed(Duration(seconds: 2));

      // 로그인 성공
      if (mounted) {
        _showSnackBar('로그인 성공!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('로그인에 실패했습니다. 다시 시도해주세요.');
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}