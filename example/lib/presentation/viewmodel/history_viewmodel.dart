import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/history.dart';

class HistoryViewModel with ChangeNotifier {
  final String baseUrl;
  List<HistoryRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  String? _currentAppliedImagePath;
  String? get currentAppliedImagePath => _currentAppliedImagePath;

  HistoryViewModel({required this.baseUrl});

  List<HistoryRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentAppliedImagePath(String path) {
    _currentAppliedImagePath = path;
    notifyListeners();
  }

  Future<void> fetchAppliedImagePath(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/consult/active?user_id=$userId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentAppliedImagePath = data['image_path'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('신청 이미지 경로 불러오기 실패: $e');
    }
  }

  Future<void> fetchRecords(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/inference_results?role=P&user_id=$userId');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final List<HistoryRecord> loadedRecords = [];

        for (final item in data) {
          final record = HistoryRecord.fromJson(item);

          // ✅ consult 상태 정보 요청 (is_requested, is_replied)
          final statusUrl = Uri.parse('$baseUrl/consult/status'
              '?user_id=${record.userId}&image_path=${Uri.encodeComponent(record.originalImagePath)}');
          final statusRes = await http.get(statusUrl);

          if (statusRes.statusCode == 200) {
            final statusData = json.decode(statusRes.body);
            final updatedRecord = record.copyWith(
              isRequested: statusData['is_requested'] ?? 'N',
              isReplied: statusData['is_replied'] ?? 'N',
            );
            loadedRecords.add(updatedRecord);
          } else {
            loadedRecords.add(record);
          }
        }

        _records = loadedRecords;
      } else {
        _error = '서버 오류: ${res.statusCode}';
      }
    } catch (e) {
      _error = '네트워크 오류: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
