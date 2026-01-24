import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

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
                    borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 이메일 입력
              Text(
                '이메일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
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
                  hintText: '8자 이상 입력하세요',
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
                    borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
              ),
              const SizedBox(height: 24),

              // 약관 동의
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    activeColor: Color(0xFF3498DB),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Text.rich(
                        TextSpan(
                          text: '서비스 이용약관',
                          style: TextStyle(
                            color: Color(0xFF3498DB),
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: ' 및 ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: '개인정보 처리방침',
                              style: TextStyle(
                                color: Color(0xFF3498DB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '에 동의합니다',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 회원가입 버튼
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_agreedToTerms) ? null : _handleSignup,
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
                        color: Color(0xFF3498DB),
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

  // 회원가입 처리
  void _handleSignup() async {
    // 입력 검증
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('이름을 입력해주세요');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('이메일을 입력해주세요');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showSnackBar('비밀번호는 8자 이상이어야 합니다');
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
      // TODO: 실제 API 호출
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/signup'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'name': _nameController.text,
      //     'email': _emailController.text,
      //     'password': _passwordController.text,
      //   }),
      // );

      // 임시: 2초 대기
      await Future.delayed(Duration(seconds: 2));

      // 회원가입 성공
      if (mounted) {
        _showSnackBar('회원가입이 완료되었습니다!');
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('회원가입에 실패했습니다. 다시 시도해주세요.');
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}