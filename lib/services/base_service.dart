import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> authHeader() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${token ?? ''}',
  };
}

// 기본 헤더
Map<String, String> basicHeader() {
  return {
    'Content-Type': 'application/json',
  };
}