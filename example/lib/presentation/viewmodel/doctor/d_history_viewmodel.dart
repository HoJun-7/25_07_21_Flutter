import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  String _yyyyMMdd(DateTime d) => DateFormat('yyyyMMdd').format(d);

  // nullable → 안전하게 int로 변환
  int _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? -1;
    return -1;
  }

  /// ✅ 진료 신청 리스트 불러오기 (의사 현황)
  Future<void> fetchConsultRecords({DateTime? day}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final date = _yyyyMMdd(day ?? DateTime.now()); // 오늘 기준
      final url = Uri.parse('$baseUrl/consult/list?date=$date'); // ✅ 핵심: date 파라미터
      final res = await http.get(url);

      debugPrint('📡 [consult/list] GET $url');
      debugPrint('📥 [consult/list] status=${res.statusCode}');
      debugPrint('📥 [consult/list] body=${res.body}');

      if (res.statusCode == 200) {
        final root = json.decode(res.body);
        if (root is Map<String, dynamic>) {
          final arr = (root['consults'] as List?) ?? const [];
          _records = arr
              .map((e) => DoctorHistoryRecord.fromJson(e as Map<String, dynamic>))
              .toList();

          // ✅ requestId가 null/문자일 수 있으니 안전 변환 후 내림차순
          _records.sort((a, b) {
            final br = _toInt(b.requestId);
            final ar = _toInt(a.requestId);
            return br.compareTo(ar); // desc
          });
        } else {
          _error = '응답 포맷 오류';
          _records = [];
        }
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

  /// ✅ 환자 진단 결과 리스트 불러오기 (의사용 환자별 결과)
  Future<void> fetchInferenceRecords({required String userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/inference_results?role=D&user_id=$userId');
      final res = await http.get(url);

      debugPrint('📡 [inference_results] GET $url');
      debugPrint('📥 [inference_results] status=${res.statusCode}');
      debugPrint('📥 [inference_results] body=${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          _records = data
              .map((e) => DoctorHistoryRecord.fromJson(e as Map<String, dynamic>))
              .toList();

          // ✅ 동일하게 안전 정렬
          _records.sort((a, b) {
            final br = _toInt(b.requestId);
            final ar = _toInt(a.requestId);
            return br.compareTo(ar); // desc
          });
        } else {
          _error = '응답 포맷 오류';
          _records = [];
        }
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
    _error = null;
    notifyListeners();
  }
}


