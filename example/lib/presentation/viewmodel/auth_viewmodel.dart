import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/presentation/model/user.dart';

class AuthViewModel with ChangeNotifier {
  final String _baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _errorMessage;
  String? duplicateCheckErrorMessage;
  bool isCheckingUserId = false;
  User? _currentUser;

  AuthViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  // ✅ access_token 불러오기
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // ✅ 아이디 중복 확인 (username → register_id 로 수정)
  Future<bool?> checkUserIdDuplicate(String userId, String role) async {
    isCheckingUserId = true;
    duplicateCheckErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/auth/check-username').replace(
        queryParameters: {
          'register_id': userId, // 🔧 핵심 수정
          'role': role,          // 백엔드에서 사용하지 않아도 무방
        },
      );

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // exists == true 면 중복
        final exists = data['exists'] == true;
        duplicateCheckErrorMessage = data['message']?.toString();
        notifyListeners();
        return exists;
      } else {
        String message = '서버 응답 오류 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (_) {}
        _errorMessage = '아이디 중복검사 오류: $message';
        duplicateCheckErrorMessage = message;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '아이디 중복검사 네트워크 오류: ${e.toString()}';
      duplicateCheckErrorMessage = _errorMessage;
      notifyListeners();
      return null;
    } finally {
      isCheckingUserId = false;
      notifyListeners();
    }
  }

  void clearDuplicateCheckErrorMessage() {
    duplicateCheckErrorMessage = null;
    notifyListeners();
  }

  // ✅ 회원가입
  Future<String?> registerUser(Map<String, dynamic> userData) async {
    _errorMessage = null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (res.statusCode == 201) {
        notifyListeners();
        return null;
      } else {
        String message = '회원가입 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (_) {}
        _errorMessage = '회원가입 실패: $message';
        notifyListeners();
        return _errorMessage;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  // ✅ 로그인
  Future<User?> loginUser(String registerId, String password, String role) async {
    _errorMessage = null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'register_id': registerId, 'password': password, 'role': role}),
      );

      if (res.statusCode == 200) {
        final decodedBody = jsonDecode(res.body);
        final token = decodedBody['access_token'];
        if (token != null) {
          await _secureStorage.write(key: 'access_token', value: token);
        }

        if (decodedBody.containsKey('user')) {
          _currentUser = User.fromJson(decodedBody['user']);
          notifyListeners();
          return _currentUser;
        } else {
          _errorMessage = '로그인 실패: 응답 형식 오류';
          notifyListeners();
          return null;
        }
      } else {
        String message = '로그인 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'];
          }
        } catch (_) {}
        _errorMessage = '로그인 실패: $message';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: $e';
      if (kDebugMode) print('로그인 오류: $e');
      notifyListeners();
      return null;
    }
  }

  // ✅ 비밀번호 재확인
  Future<String?> reauthenticate(String registerId, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reauthenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'register_id': registerId,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) return null;
        return result['message'] ?? '비밀번호가 일치하지 않습니다.';
      } else {
        final result = jsonDecode(response.body);
        return result['message'] ?? '서버 오류';
      }
    } catch (e) {
      return '네트워크 오류: $e';
    }
  }

  // ✅ 사용자 정보 업데이트
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updatedData) async {
    if (_currentUser == null) {
      return {'isSuccess': false, 'message': '로그인 정보가 없습니다.'};
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      final decoded = jsonDecode(response.body);
      final message = decoded['message'] ?? '응답 메시지를 가져올 수 없습니다.';

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(updatedData);
        _currentUser = updatedUser;
        notifyListeners();
        return {'isSuccess': true, 'message': message};
      } else {
        return {'isSuccess': false, 'message': message};
      }
    } catch (e) {
      return {'isSuccess': false, 'message': '네트워크 오류: $e'};
    }
  }

  // ✅ 회원 탈퇴 (username → register_id 로 수정)
  Future<String?> deleteUser(String registerId, String password, String? role) async {
    _errorMessage = null;
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/auth/delete_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'register_id': registerId, // 🔧 핵심 수정
          'password': password,
          'role': role,
        }),
      );

      if (res.statusCode == 200) {
        notifyListeners();
        return null;
      } else {
        String message = '회원 탈퇴 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'];
          }
        } catch (_) {}
        _errorMessage = message;
        notifyListeners();
        return _errorMessage;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  // ✅ 로그아웃
  void logout() async {
    _currentUser = null;
    await _secureStorage.delete(key: 'access_token');
    notifyListeners();
  }
}
