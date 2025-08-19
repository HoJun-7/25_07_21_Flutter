// lib/presentation/viewmodel/doctor/d_history_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../model/doctor/d_history.dart'; // DoctorHistoryRecord

class DoctorHistoryViewModel with ChangeNotifier {
  final String baseUrl;

  DoctorHistoryViewModel({required this.baseUrl});

  List<DoctorHistoryRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<DoctorHistoryRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 공통 유틸: 안전 파싱 + 최신순 정렬
  List<DoctorHistoryRecord> _parseAndSort(dynamic body) {
    final List<DoctorHistoryRecord> parsed = [];

    if (body is List) {
      // /inference_results (배열)
      for (final e in body) {
        if (e is Map<String, dynamic>) {
          parsed.add(DoctorHistoryRecord.fromJson(e));
        } else if (e is Map) {
          parsed.add(DoctorHistoryRecord.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } else if (body is Map<String, dynamic>) {
      // /consult/list (객체 안에 consults)
      final dynamic arr = body['consults'];
      if (arr is List) {
        for (final e in arr) {
          if (e is Map<String, dynamic>) {
            parsed.add(DoctorHistoryRecord.fromJson(e));
          } else if (e is Map) {
            parsed.add(DoctorHistoryRecord.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
    }

    // 최신순 (timestamp desc)
    parsed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return parsed;
  }

  /// ✅ 진료 신청 리스트 (/consult/list)
  Future<void> fetchConsultRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/consult/list');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        _records = _parseAndSort(decoded);
      } else {
        _records = [];
        _error = '서버 오류 (${res.statusCode})';
      }
    } catch (e) {
      _records = [];
      _error = '네트워크 오류: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ 특정 환자의 추론 결과 (/inference_results?role=D&user_id=..)
  Future<void> fetchInferenceRecords({required String userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/inference_results?role=D&user_id=$userId');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        _records = _parseAndSort(decoded);
      } else {
        _records = [];
        _error = '서버 오류 (${res.statusCode})';
      }
    } catch (e) {
      _records = [];
      _error = '네트워크 오류: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 공용 초기화
  void clearRecords() {
    _records = [];
    notifyListeners();
  }
}
