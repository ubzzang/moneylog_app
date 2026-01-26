import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common/constants.dart';

class AuthService {
  static const String BASE_URL = '${Constants.BASE_API_URL}/api/authentication';

  // 로그인
  Future<http.Response> loginService(Map<String, dynamic> user) {
    return http.post(
      Uri.parse('$BASE_URL/sign-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
  }

  // 회원가입
  Future<http.Response> registerService(Map<String, dynamic> user) {
    return http.post(
      Uri.parse('$BASE_URL/sign-up'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user),
    );
  }

  // 아이디 중복 체크
  Future<http.Response> checkUsernameService(String username) {
    return http.get(
      Uri.parse('$BASE_URL/check-username?username=$username'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // 토큰 저장
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // 로그아웃
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}