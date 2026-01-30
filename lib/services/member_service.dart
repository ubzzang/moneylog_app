import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common/constants.dart';

class MemberService {
  static const String BASE_URL = '${Constants.BASE_API_URL}/api/members';

  // 토큰 가져오기
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 공통 헤더 생성
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 회원 정보 조회
  Future<Map<String, dynamic>> getMember(String username) async {
    try {
      final headers = await _getHeaders();
      final url = '$BASE_URL/list?username=$username';

      print('====== getMember 요청 시작 ======');
      print('📡 요청 URL: $url');
      print('📋 헤더: $headers');
      print('🔑 토큰: ${headers['Authorization']}');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 본문: ${response.body}');
      print('====== getMember 요청 종료 ======');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // React 코드와 동일하게 처리
        if (data['dtoList'] != null && data['dtoList'].isNotEmpty) {
          return data['dtoList'][0];
        }
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 403) {
        throw Exception('접근 권한이 없습니다. 응답: ${response.body}');
      } else {
        throw Exception('회원 정보 조회 실패: ${response.statusCode}, 응답: ${response.body}');
      }
    } catch (e) {
      print('회원 정보 조회 오류: $e');
      rethrow;
    }
  }

  // 비밀번호 확인
  Future<bool> verifyPassword(String password) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/verify-password'),
        headers: await _getHeaders(),
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body == 'true') return true;
        if (body == 'false') return false;
        return jsonDecode(body) as bool;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        throw Exception('비밀번호 확인 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('비밀번호 확인 오류: $e');
      rethrow;
    }
  }

  // 회원 정보 변경
  Future<void> changeInfo(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/change-info'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? '잘못된 요청입니다.');
        } catch (e) {
          throw Exception('잘못된 요청입니다.');
        }
      } else {
        throw Exception('회원 정보 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 정보 변경 오류: $e');
      rethrow;
    }
  }

  // 회원 역할 변경
  Future<void> changeRole(String username, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/change/$username/$role'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        throw Exception('역할 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('역할 변경 오류: $e');
      rethrow;
    }
  }

  // 회원 탈퇴
  Future<void> deleteMember(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('$BASE_URL/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        throw Exception('회원 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 삭제 오류: $e');
      rethrow;
    }
  }

  // 회원 목록 조회
  Future<Map<String, dynamic>> getMembers(Map<String, dynamic> pageRequestDTO) async {
    try {
      final queryParams = Uri(queryParameters:
      pageRequestDTO.map((key, value) => MapEntry(key, value.toString()))
      ).query;

      final response = await http.get(
        Uri.parse('$BASE_URL/list?$queryParams'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('회원 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('회원 목록 조회 오류: $e');
      rethrow;
    }
  }
}