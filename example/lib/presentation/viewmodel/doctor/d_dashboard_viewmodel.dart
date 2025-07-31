import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int pendingToday = 0;
  int completedToday = 0;
  int canceledToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '홍길동';

  List<FlSpot> _lineData = [];
  Map<String, double> _categoryRatio = {};

  List<String> announcements = [
    "8월 1일 정기 점검 안내",
    "병원 내부 소독 작업 일정 공지",
    "새로운 진료 프로토콜 적용 안내",
    "환자 정보 유출 금지",
  ];

  List<String> todoList = [
    "환자 김철수 상담 결과 공유",
    "주간 미팅 준비",
    "진료실 청소 및 정리",
  ];

  Map<String, double> get categoryRatio => _categoryRatio;

  List<LineChartBarData> get chartData => [
        LineChartBarData(
          spots: _lineData,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
          ),
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ];

  List<PieChartSectionData> get pieChartSections {
    final total = _categoryRatio.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return [];

    return _categoryRatio.entries.mapIndexed((i, entry) {
      return PieChartSectionData(
        color: getCategoryColor(i),
        value: entry.value,
        title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Future<void> loadDashboardData(String baseUrl, String registerId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/consult/today-status-counts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        requestsToday = data['total'];
        pendingToday = data['pending'];
        completedToday = data['completed'];
        canceledToday = data['canceled'];
      }

      unreadNotifications = 2;

      _lineData = List.generate(
        7,
        (index) => FlSpot(index.toDouble(), (index * 2 + 3).toDouble()),
      );

      _categoryRatio = {
        '충치': 30,
        '잇몸질환': 25,
        '임플란트': 20,
        '교정': 15,
        '기타': 10,
      };

      notifyListeners();
    } catch (e) {
      print("loadDashboardData 오류: $e");
    }
  }

  /// ✅ 의사 이름 가져오는 독립 메서드
  Future<String> loadDoctorName(String baseUrl, String registerId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/doctor-name/$registerId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['name'];
      }
    } catch (e) {
      print('loadDoctorName 오류: $e');
    }
    return '알 수 없음';
  }

  Color getCategoryColor(int index) {
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  int get waitingPatients => 3;
  int get averageResponseTimeInMinutes => 7;
  int get upcomingSchedules => 4;
}

extension MapIndexedExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}