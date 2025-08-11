import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '';

  // ✅ 오늘의 스케줄 수 변수 추가
  int _todaysScheduleCount = 0;
  int get todaysScheduleCount => _todaysScheduleCount;

  List<FlSpot> _lineData = [];
  List<FlSpot> get lineData => _lineData;

  List<LineChartBarData> get chartData => [
    LineChartBarData(
      spots: _lineData,
      isCurved: true,
      gradient: const LinearGradient(
        colors: [Colors.blueAccent, Colors.lightBlueAccent],
      ),
      barWidth: 3,
      dotData: const FlDotData(show: true),
    ),
  ];

  Future<void> loadDashboardData(String baseUrl) async {
    final today = DateTime.now();
    final formattedDate = "${today.year.toString().padLeft(4, '0')}"
        "${today.month.toString().padLeft(2, '0')}"
        "${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(Uri.parse('$baseUrl/consult/stats?date=$formattedDate'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        requestsToday = data['total'] ?? 0;
        answeredToday = data['completed'] ?? 0;
        unreadNotifications = requestsToday - answeredToday;
        doctorName = '김닥터';
      } else {
        debugPrint("❌ 통계 데이터 로딩 실패: ${response.statusCode}");
        requestsToday = 0;
        answeredToday = 0;
        unreadNotifications = 0;
      }

      // ✅ todaysScheduleCount에 대한 데이터 설정 (임시)
      // 실제 API 연동 시 백엔드에서 받은 값으로 대체해야 합니다.
      _todaysScheduleCount = 3; 

      _lineData = [
        const FlSpot(0, 0),
        const FlSpot(1, 1),
        const FlSpot(2, 2),
        const FlSpot(3, 3),
        const FlSpot(4, 5),
        const FlSpot(5, 7),
        FlSpot(6, requestsToday.toDouble()),
      ];

      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadDashboardData 예외 발생: $e");
      requestsToday = 0;
      answeredToday = 0;
      unreadNotifications = 0;
      _todaysScheduleCount = 0; // ✅ 예외 발생 시 초기화
      _lineData = [];
      notifyListeners();
    }
  }
}