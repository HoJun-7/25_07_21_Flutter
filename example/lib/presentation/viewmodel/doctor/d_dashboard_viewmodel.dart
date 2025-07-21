import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  int _newPatientsToday = 0;
  int _completedConsultationsToday = 0;
  int _pendingConsultations = 0;

  // 원본 통계 데이터 접근용 게터
  int get newPatientsToday => _newPatientsToday;
  int get completedConsultationsToday => _completedConsultationsToday;
  int get pendingConsultations => _pendingConsultations;

  // ✅ UI에서 사용하던 requestsToday, answeredToday 이름 대응 게터
  int get requestsToday => _newPatientsToday;
  int get answeredToday => _completedConsultationsToday;

  // 대시보드 데이터 갱신 메서드
  void updateDashboardData({int? newPatients, int? completed, int? pending}) {
    if (newPatients != null) _newPatientsToday = newPatients;
    if (completed != null) _completedConsultationsToday = completed;
    if (pending != null) _pendingConsultations = pending;
    notifyListeners();
  }

  // ✅ 서버에서 데이터 받아오는 API 호출 메서드
  Future<void> loadDashboardData(String baseUrl) async {
    try {
      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final url = Uri.parse('$baseUrl/consult/stats?date=$today');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        updateDashboardData(
          newPatients: data['total'],
          completed: data['completed'],
          pending: data['pending'],
        );
      } else {
        print('📛 [loadDashboardData] 서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('📛 [loadDashboardData] 예외 발생: $e');
    }
  }
}
