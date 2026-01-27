import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../common/constants.dart';

class TransactionService {
  static const String BASE_URL = '${Constants.BASE_API_URL}/api/transactions';


  // 월간 수입 / 소비
  Future<http.Response> getListByMonth({
    required int mid,
    String? month,
    int page = 1,
    int size = 100,
  }) async {
    // 토큰 가져오기
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // query params 구성
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }

    final uri = Uri.parse('$BASE_URL/member/$mid/month')
        .replace(queryParameters: queryParams);

    return http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // 하루 수입 / 소비
  Future<http.Response> getListByDay({
    required int mid,
    String? date,
    int page = 1,
    int size = 10,
  }) async {
    // 토큰 가져오기
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // query params 구성
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
    };

    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final uri = Uri.parse('$BASE_URL/member/$mid/day')
        .replace(queryParameters: queryParams);

    return http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
