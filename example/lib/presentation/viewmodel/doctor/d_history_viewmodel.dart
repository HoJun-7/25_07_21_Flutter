import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../model/doctor/d_history.dart'; // DoctorHistoryRecord import

class DoctorHistoryViewModel with ChangeNotifier {
  final String baseUrl;
  List<DoctorHistoryRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  DoctorHistoryViewModel({required this.baseUrl});

  List<DoctorHistoryRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ✅ 진료 신청 리스트 불러오기
  Future<void> fetchConsultRecords() async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/consult/list');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(res.body);
        final List<dynamic> data = jsonMap['consults'];

        _records = data.map((e) => DoctorHistoryRecord.fromJson(e)).toList();
      } else {
        _error = '서버 오류: ${res.statusCode}';
        _records = [];
      }
    } catch (e) {
      _error = '네트워크 오류: $e';
      _records = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 환자 진단 결과 리스트 불러오기
  Future<void> fetchInferenceRecords({required String userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/inference_results?role=D&user_id=$userId');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _records = data.map((e) => DoctorHistoryRecord.fromJson(e)).toList();
      } else {
        _error = '서버 오류: ${res.statusCode}';
        _records = [];
      }
    } catch (e) {
      _error = '네트워크 오류: $e';
      _records = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 공통 사용 시 초기화
  void clearRecords() {
    _records = [];
    notifyListeners();
  }
}
