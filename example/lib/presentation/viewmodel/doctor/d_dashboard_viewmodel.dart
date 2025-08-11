// C:\Users\302-15\Desktop\25_07_21_Flutter-2\example\lib\presentation\viewmodel\doctor\d_dashboard_viewmodel.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '';

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
        doctorName = '김닥터'; // TODO: 백엔드에서 닥터 이름도 전달하도록 개선
      } else {
        debugPrint("❌ 통계 데이터 로딩 실패: ${response.statusCode}");
        requestsToday = 0;
        answeredToday = 0;
        unreadNotifications = 0;
      }

      // '오늘의 요청' 데이터를 기반으로 최근 7일 차트 데이터 생성
      // 이 부분은 실제 API 연동 시 API 응답에 맞게 수정해야 합니다.
      // 현재는 requestsToday 값을 사용하여 오늘의 데이터만 설정합니다.
      _lineData = [
        const FlSpot(0, 0), // 6일 전 (가상 데이터)
        const FlSpot(1, 1), // 5일 전 (가상 데이터)
        const FlSpot(2, 2), // 4일 전 (가상 데이터)
        const FlSpot(3, 3), // 3일 전 (가상 데이터)
        const FlSpot(4, 5), // 2일 전 (가상 데이터)
        const FlSpot(5, 7), // 어제 (가상 데이터)
        FlSpot(6, requestsToday.toDouble()), // 오늘 데이터 (오늘의 요청과 연동)
      ];

      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadDashboardData 예외 발생: $e");
      // 예외 발생 시에도 기본값으로 초기화
      requestsToday = 0;
      answeredToday = 0;
      unreadNotifications = 0;
      _lineData = [];
      notifyListeners();
    }
  }
}