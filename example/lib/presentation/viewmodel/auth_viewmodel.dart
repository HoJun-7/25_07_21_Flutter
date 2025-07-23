// lib/presentation/viewmodel/auth_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import '/presentation/model/user.dart'; // ✅ d_user.dart 대신 user.dart 모델 임포트

class AuthViewModel with ChangeNotifier {
  final String _baseUrl;
  String? _errorMessage;
  String? duplicateCheckErrorMessage;
  bool isCheckingUserId = false;
  User? _currentUser; // 이제 user.dart의 User 모델 사용

  AuthViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<bool?> checkUserIdDuplicate(String userId, String role) async {
    isCheckingUserId = true;
    duplicateCheckErrorMessage = null;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/check-username?username=$userId&role=$role'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['exists'] == true;
      } else {
        String message = '서버 응답 오류 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _errorMessage = '아이디 중복검사 서버 응답 오류: $message';
        if (kDebugMode) {
          print(_errorMessage);
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '아이디 중복검사 중 네트워크 오류: ${e.toString()}';
      if (kDebugMode) {
        print(_errorMessage);
      }
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
        } catch (e) {
          // Body was not valid JSON
        }
        _errorMessage = '회원가입 실패: $message';
        notifyListeners();
        return _errorMessage;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: ${e.toString()}';
      if (kDebugMode) {
        print('회원가입 중 네트워크 오류: $e');
      }
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<User?> loginUser(String registerId, String password, String role) async {
    _errorMessage = null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'register_id': registerId, 'password': password, 'role': role}),
      );

      if (res.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(res.body);
        if (decodedBody is Map && decodedBody.containsKey('user') && decodedBody['user'] is Map) {
          _currentUser = User.fromJson(decodedBody['user'] as Map<String, dynamic>);
          notifyListeners();
          return _currentUser;
        } else {
          _errorMessage = '로그인 실패: 서버 응답 형식이 올바르지 않습니다.';
          notifyListeners();
          return null;
        }
      } else {
        String message = '로그인 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _errorMessage = '로그인 실패: $message';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: ${e.toString()}';
      if (kDebugMode) {
        print('로그인 중 네트워크 오류: $e');
      }
      notifyListeners();
      return null;
    }
  }

  Future<String?> deleteUser(String registerId, String password, String? role) async {
    _errorMessage = null;
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/auth/delete_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': registerId, 'password': password, 'role': role}),
      );

      if (res.statusCode == 200) {
        notifyListeners();
        return null;
      } else {
        String message = '회원 탈퇴 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _errorMessage = message;
        notifyListeners();
        return _errorMessage;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: ${e.toString()}';
      if (kDebugMode) {
        print('회원 탈퇴 중 네트워크 오류: $e');
      }
      notifyListeners();
      return _errorMessage;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}