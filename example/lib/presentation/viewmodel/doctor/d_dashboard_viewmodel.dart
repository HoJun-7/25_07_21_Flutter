import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '';

  // ✅ 대시보드에서 바로 보여줄 오늘 접수 리스트
  List<ConsultItem> consultsToday = [];

  List<FlSpot> _lineData = [];
  Map<String, double> _categoryRatio = {};

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

  String _todayYyyymmdd() => DateFormat('yyyyMMdd').format(DateTime.now());

  Future<void> loadDashboardData(String baseUrl) async {
    final date = _todayYyyymmdd();

    try {
      // 1) 통계
      final statsRes = await http.get(Uri.parse('$baseUrl/consult/stats?date=$date'));
      if (statsRes.statusCode == 200) {
        final data = jsonDecode(statsRes.body);
        requestsToday = data['total'] ?? 0;
        answeredToday = data['completed'] ?? 0;
        unreadNotifications = requestsToday - answeredToday;
        doctorName = '김닥터'; // TODO: 백엔드에서 닥터 이름 연동
      } else {
        debugPrint("❌ 통계 데이터 로딩 실패: ${statsRes.statusCode}");
      }

      // 2) ✅ 오늘 리스트 (여기가 핵심 추가)
      final listUri = Uri.parse('$baseUrl/consult/list?date=$date');
      final listRes = await http.get(listUri);
      debugPrint('📡 [list] $listUri');
      debugPrint('📥 [list] status=${listRes.statusCode}');
      debugPrint('📥 [list] body=${listRes.body}');
      if (listRes.statusCode == 200) {
        final root = jsonDecode(listRes.body) as Map<String, dynamic>;
        final arr = (root['consults'] as List?) ?? const [];
        consultsToday = arr
            .map((e) => ConsultItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        consultsToday = [];
      }

      // 3) 차트/카테고리(추후 연동)
      _lineData = [];
      _categoryRatio = {};

      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadDashboardData 예외 발생: $e");
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

// ✅ consult 리스트 항목 파서 (백엔드 스키마에 맞춤)
class ConsultItem {
  final int requestId;
  final String userId;        // register_id 문자열
  final String userName;
  final String imagePath;
  final DateTime requestDatetime;
  final bool isReplied;

  ConsultItem({
    required this.requestId,
    required this.userId,
    required this.userName,
    required this.imagePath,
    required this.requestDatetime,
    required this.isReplied,
  });

  factory ConsultItem.fromJson(Map<String, dynamic> j) => ConsultItem(
        requestId: (j['request_id'] as num).toInt(),
        userId: j['user_id']?.toString() ?? '',
        userName: j['user_name']?.toString() ?? '',
        imagePath: j['image_path']?.toString() ?? '',
        requestDatetime:
            DateTime.tryParse(j['request_datetime']?.toString() ?? '') ??
                DateTime.now(),
        isReplied: j['is_replied'] is bool
            ? j['is_replied'] as bool
            : (j['is_replied'] is num
                ? (j['is_replied'] != 0)
                : (j['is_replied']?.toString().toLowerCase() == 'true')),
      );
}

// mapIndexed 확장
extension MapIndexedExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) {
    int i = 0;
    return map((e) => f(i++, e));
  }
}

