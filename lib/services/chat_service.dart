import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moneylog_app/services/base_service.dart';
import '../common/constants.dart';

class ChatService {
  static const String BASE_URL = '${Constants.BASE_API_URL}/api/chat';

  // 메시지 전송
  Future<http.Response> sendMessage(String message) async {
    return await http.post(
      Uri.parse(BASE_URL),
      headers: await authHeader(),  // 인증 헤더!
      body: jsonEncode({'message': message}),
    );
  }
}