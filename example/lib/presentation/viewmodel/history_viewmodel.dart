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

  // Y/N 정규화 헬퍼
  String _yn(dynamic v) {
    if (v is bool) return v ? 'Y' : 'N';
    if (v is num) return v != 0 ? 'Y' : 'N';
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'y' || s == 'yes' || s == 'true' || s == '1') return 'Y';
      if (s == 'n' || s == 'no' || s == 'false' || s == '0') return 'N';
      // 이미 'Y'/'N' 케이스도 방어
      if (s == 'y' || s == 'n') return s.toUpperCase();
    }
    return 'N';
  }

  Future<void> fetchAppliedImagePath(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/consult/active?user_id=${userId.toString()}');
      final res = await http.get(url);

      debugPrint('📥 [active] 상태코드: ${res.statusCode}');
      debugPrint('📥 [active] 본문: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentAppliedImagePath = data['image_path']?.toString();
        notifyListeners();
      } else {
        debugPrint('❌ [active] 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [active] 예외: $e');
    }
  }

  Future<void> fetchRecords(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/inference_results?role=P&user_id=${userId.toString()}');
      final res = await http.get(url);

      debugPrint('📥 [fetchRecords] 상태코드: ${res.statusCode}');
      debugPrint('📥 [fetchRecords] 본문: ${res.body}');

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final List<HistoryRecord> loadedRecords = [];

        for (final item in data) {
          final record = HistoryRecord.fromJson(item);

          // ▷ consult 상태 조회 (이미지 단위)
          final statusUrl = Uri.parse(
            '$baseUrl/consult/status'
            '?user_id=${record.userId.toString()}'
            '&image_path=${Uri.encodeComponent(record.originalImagePath)}',
          );
          final statusRes = await http.get(statusUrl);

          if (statusRes.statusCode == 200) {
            final statusData = json.decode(statusRes.body);

            final reqYN = _yn(statusData['is_requested']);
            final repYN = _yn(statusData['is_replied']);

            debugPrint('🧩 상태 정규화: is_requested=$reqYN, is_replied=$repYN '
                '(raw=${statusData['is_requested']}/${statusData['is_replied']})');

            loadedRecords.add(
              record.copyWith(isRequested: reqYN, isReplied: repYN),
            );
          } else {
            // 조회 실패시 기본값 유지(HistoryRecord.fromJson의 값 사용)
            debugPrint('⚠️ [status] ${statusRes.statusCode} → 기록 그대로 사용');
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

  // 진행중(사용자 단위) 여부 확인 편의 메서드
  Future<bool> hasActiveConsult(String userId) async {
    await fetchAppliedImagePath(userId);
    return _currentAppliedImagePath != null;
  }

  // 상태 업데이트(카드에서 토글 등 할 때)
  void updateRecordStatus(String recordId, String isRequested, String isReplied) {
    final idx = _records.indexWhere((r) => r.id == recordId);
    if (idx != -1) {
      _records[idx] = _records[idx].copyWith(
        isRequested: _yn(isRequested),
        isReplied: _yn(isReplied),
      );
      notifyListeners();
    }
  }

  void clear() {
    _records = [];
    _currentAppliedImagePath = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}

