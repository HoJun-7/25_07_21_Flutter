import 'package:flutter/material.dart';
// 필요하다면 API 호출을 위한 패키지 (예: http 또는 dio)를 임포트
// import 'package:http/http.dart' as http;
// import 'dart:convert'; // JSON 디코딩을 위해

class FindPasswordViewModel extends ChangeNotifier {
  final String baseUrl;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  FindPasswordViewModel({required this.baseUrl});

  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  String? get errorMessage => _errorMessage;

  // 상태를 초기화하는 메서드 (필요에 따라)
  void _resetMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> findPassword({required String name, required String phoneNumber}) async {
    _isLoading = true;
    _successMessage = null;
    _errorMessage = null;
    notifyListeners(); // 로딩 상태 변경을 UI에 알림

    if (name.isEmpty || phoneNumber.isEmpty) {
      _errorMessage = '이름과 전화번호를 모두 입력해주세요.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 실제 API 호출 로직을 여기에 구현
      // 예시: 더미 데이터 또는 간단한 지연
      await Future.delayed(const Duration(seconds: 2)); // 2초 대기 시뮬레이션

      // 여기에 실제 API 호출 코드를 작성합니다.
      // 예시:
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/api/find_password'), // 실제 API 엔드포인트
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // 서버 응답에 따라 성공 메시지 설정
        _successMessage = responseData['message'] ?? '비밀번호 재설정 링크가 전송되었습니다.';
        _errorMessage = null;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? '비밀번호 찾기에 실패했습니다. 정보를 확인해주세요.';
        _successMessage = null;
      }
      */

      // API 호출 대신 임시 성공/실패 로직
      if (name == "홍길동" && phoneNumber == "01012345678") {
        _successMessage = '비밀번호 재설정 링크가 이메일로 전송되었습니다.';
        _errorMessage = null;
      } else {
        _errorMessage = '입력하신 정보와 일치하는 계정이 없습니다.';
        _successMessage = null;
      }

    } catch (e) {
      _errorMessage = '네트워크 오류가 발생했습니다: ${e.toString()}';
      _successMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 상태 및 메시지 변경을 UI에 알림
    }
  }
}