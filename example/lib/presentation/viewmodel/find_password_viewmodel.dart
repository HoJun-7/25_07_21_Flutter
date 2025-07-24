import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindPasswordViewModel extends ChangeNotifier {
  final String baseUrl;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  FindPasswordViewModel({required this.baseUrl});

  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  String? get errorMessage => _errorMessage;

  void resetMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ bool 값을 리턴하여 성공 여부 판단 가능
  Future<bool> findPassword({required String name, required String phone}) async {
    _isLoading = true;
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();

    if (name.isEmpty || phone.isEmpty) {
      _errorMessage = '이름과 전화번호를 모두 입력해주세요.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/find_password'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _successMessage = data['message'] ?? '비밀번호 재설정 링크가 이메일로 전송되었습니다.';
        _errorMessage = null;
        return true; // ✅ 성공
      } else {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? '비밀번호 찾기에 실패했습니다.';
        _successMessage = null;
        return false; // ❌ 실패
      }
    } catch (e) {
      _errorMessage = '네트워크 오류가 발생했습니다: ${e.toString()}';
      _successMessage = null;
      return false; // ❌ 실패
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
