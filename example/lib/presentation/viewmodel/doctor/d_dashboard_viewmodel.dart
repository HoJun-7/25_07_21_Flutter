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
  Map<String, double> _categoryRatio = {};

  /// ✅ 최근 7일 신청 건수
  List<int> recent7DaysCounts = [];
  List<String> recent7DaysLabels = []; // 📌 X축 라벨용 날짜

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

  /// 📌 오늘의 요청/응답/알림 개수 불러오기
  Future<void> loadDashboardData(String baseUrl) async {
    final today = DateTime.now();
    final formattedDate =
        "${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

    try {
      final response =
          await http.get(Uri.parse('$baseUrl/consult/stats?date=$formattedDate'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        requestsToday = data['total'] ?? 0;
        answeredToday = data['completed'] ?? 0;
        unreadNotifications = requestsToday - answeredToday;
        doctorName = '김닥터'; // TODO: 백엔드에서 닥터 이름도 전달하도록 개선
      } else {
        debugPrint("❌ 통계 데이터 로딩 실패: ${response.statusCode}");
      }

      // 차트 데이터 및 카테고리 초기화
      _lineData = [];
      _categoryRatio = {};

      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadDashboardData 예외 발생: $e");
    }
  }

  /// 📌 최근 7일 신청 건수 불러오기
  Future<void> loadRecent7DaysData(String baseUrl) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/consult/recent-7-days'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['data'] ?? [];

        // 📌 날짜순 정렬 (오래된 → 최신)
        list.sort((a, b) => a['date'].compareTo(b['date']));

        // 📌 데이터 분리
        recent7DaysCounts = list.map((e) => e['count'] as int).toList();
        recent7DaysLabels =
          list.map<String>((e) => e['date'].substring(5)).toList(); // MM-DD 형식

        // 📌 그래프 FlSpot 데이터 변환
        _lineData = List.generate(
          recent7DaysCounts.length,
          (i) => FlSpot(i.toDouble(), recent7DaysCounts[i].toDouble()),
        );
      } else {
        debugPrint("❌ 최근 7일 데이터 로딩 실패: ${response.statusCode}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadRecent7DaysData 예외 발생: $e");
    }
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
}

// mapIndexed 확장
extension MapIndexedExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}
