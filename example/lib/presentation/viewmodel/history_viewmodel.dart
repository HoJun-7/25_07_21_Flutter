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

  /// 현재 사용자(환자)의 '상담 신청중' 이미지 경로 조회 (기존 로직 유지)
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

  /// 환자용 기록 목록 조회
  /// 백엔드가 is_requested / is_replied 를 포함해 주므로 별도 consult/status 호출 불필요
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
          // HistoryRecord.fromJson 이 model1/2/3_image_path, image_type,
          // is_requested, is_replied 등을 매핑한다고 가정
          final record = HistoryRecord.fromJson(item);
          loadedRecords.add(record);
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

  /// 서버에 삭제 요청 + 성공 시 로컬 리스트에서도 제거
  /// - baseUrl: 보통 '/api' 포함
  /// - token  : AuthViewModel.getAccessToken() 에서 받아서 넘겨주기
  Future<bool> deleteRecordRemote({
    required String inferenceId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/inference_delete');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inference_id': inferenceId}),
      );

      if (res.statusCode == 200) {
        _records.removeWhere((r) => r.id == inferenceId);
        notifyListeners();
        return true;
      } else {
        _error = '삭제 실패 (status=${res.statusCode} body=${res.body})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '삭제 요청 중 오류: $e';
      notifyListeners();
      return false;
    }
  }

  /// (옵션) UI에서 미리 제거하고 싶을 때 사용할 수 있는 메서드
  void removeRecord(String id) {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
