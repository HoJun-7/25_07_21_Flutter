import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';      // ✅ jsonDecode 사용 시
import 'package:http/http.dart' as http; // ✅ API 호출용

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '홍길동';

  List<FlSpot> _lineData = [];
  Map<String, double> _categoryRatio = {};

  // ViewModel 외부에서 _categoryRatio를 참조할 수 있도록 getter 추가
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
      final isTouched = false; // 이 부분은 실제 터치 이벤트 처리 시 사용됩니다.
      final double radius = isTouched ? 60 : 50;

      return PieChartSectionData(
        color: getCategoryColor(i),
        value: entry.value,
        title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Future<void> loadDashboardData(String baseUrl) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/consult/today-status-counts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        requestsToday = data['total'];
        pendingToday = data['pending'];
        completedToday = data['completed'];
        canceledToday = data['canceled'];
      }

      // 예시 데이터 유지 (추후 API 연동 가능)
      doctorName = '김닥터';
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

  // 추가 필드 선언
  int pendingToday = 0;
  int completedToday = 0;
  int canceledToday = 0;

  // 기존의 _getColor를 public getter로 변경하여 외부에서 접근 가능하게 함
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

// mapIndexed 확장 (이것은 Iterable에 대한 유틸리티 확장으로, ViewModel 파일에 있어도 괜찮습니다)
extension MapIndexedExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}










/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '홍길동';

  List<FlSpot> _lineData = [];
  Map<String, double> _categoryRatio = {};

  // 공지사항 / 병원 전달사항 리스트
  List<String> announcements = [
    "8월 1일 정기 점검 안내",
    "병원 내부 소독 작업 일정 공지",
    "새로운 진료 프로토콜 적용 안내"
    "환자 정보 유출 금지",
  ];

  // 간단한 메모 / 할일 리스트
  List<String> todoList = [
    "환자 김철수 상담 결과 공유",
    "주간 미팅 준비",
    "진료실 청소 및 정리",
  ];

  // 환자 즐겨찾기 리스트 및 최근 본 환자 리스트 모두 삭제됨

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
      final isTouched = false;
      final double radius = isTouched ? 60 : 50;

      return PieChartSectionData(
        color: getCategoryColor(i),
        value: entry.value,
        title: '${((entry.value / total) * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Future<void> loadDashboardData(String baseUrl) async {
    await Future.delayed(const Duration(milliseconds: 500));
    requestsToday = 10;
    answeredToday = 7;
    unreadNotifications = 2;
    doctorName = '김닥터';

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

// Iterable 확장
extension MapIndexedExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}*/