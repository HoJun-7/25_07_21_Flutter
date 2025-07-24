// lib/presentation/viewmodel/find_id_viewmodel.dart
import 'package:flutter/material.dart';

class FindIdViewModel extends ChangeNotifier {
  final String baseUrl;

  FindIdViewModel({required this.baseUrl});

  bool _isLoading = false;
  String? _foundId;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get foundId => _foundId;
  String? get errorMessage => _errorMessage;

  Future<void> findId({required String name, required String phoneNumber}) async {
    _isLoading = true;
    _foundId = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (name == '테스트' && phoneNumber == '01012345678') {
        _foundId = 'testuser@example.com';
      } else {
        _errorMessage = '입력하신 정보와 일치하는 아이디가 없습니다.';
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