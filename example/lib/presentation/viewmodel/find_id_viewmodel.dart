import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindIdViewModel extends ChangeNotifier {
  final String baseUrl;

  FindIdViewModel({required this.baseUrl});

  bool _isLoading = false;
  String? _foundId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get foundId => _foundId;
  String? get errorMessage => _errorMessage;

  Future<void> findId({required String name, required String phone}) async {
    _isLoading = true;
    _foundId = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/auth/find_id'); // ✅ 실제 API 엔드포인트로 수정
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _foundId = data['register_id']; // 서버가 반환하는 키에 따라 수정
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['message'] ?? '아이디 찾기에 실패했습니다.';
      }
    } catch (e) {
      _errorMessage = '아이디 찾기 중 오류가 발생했습니다: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetResult() {
    _foundId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
