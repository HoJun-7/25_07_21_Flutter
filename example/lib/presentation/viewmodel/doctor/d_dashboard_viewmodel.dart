import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  // ===== 상단 카드 =====
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '';

  // ===== 최근 7일 =====
  List<int> recent7DaysCounts = [];
  List<String> recent7DaysLabels = [];
  List<FlSpot> _lineData = [];

  // ===== 성별·연령 =====
  Map<String, int> ageDistributionData = {};
  int maleCount = 0;
  int femaleCount = 0;

  // ===== 시간대별 건수 =====
  List<String> hourlyLabels = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  List<int> hourlyCounts = List.filled(24, 0);
  List<FlSpot> hourlySpots = [];

  // ===== 날짜별 사진 목록 =====
  List<Map<String, dynamic>> images = []; // id, user_id, image_url, request_datetime 등
  List<String> imageUrls = [];
  int imagesTotal = 0;
  bool isLoadingImages = false;

  // ===== 영상 타입 비율 (X-ray / 구강이미지) =====
  Map<String, int> videoTypeRatio = {}; // 예: {"X-ray": 12, "구강이미지": 34}

  // (기존 사용 중이면 유지)
  Map<String, double> _categoryRatio = {};
  Map<String, double> get categoryRatio => _categoryRatio;

  // 호환 getter: 일부 위젯에서 photoUrls 기대 가능
  List<String> get photoUrls => imageUrls;

  // 최근 7일 라인차트 데이터
  List<LineChartBarData> get chartData => [
        LineChartBarData(
          spots: _lineData,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
          ),
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ];

  // 파이차트 섹션 (사용 중이면 유지)
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

  // ==================== API ====================

  /// 오늘의 요청/응답/알림 집계
  /// GET /consult/stats?date=YYYYMMDD
  Future<void> loadDashboardData(String baseUrl) async {
    final today = DateTime.now();
    final formattedDate =
        "${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

    try {
      final response =
          await http.get(Uri.parse('$baseUrl/consult/stats?date=$formattedDate'));

      if (response.statusCode == 200 || response.statusCode == 200) {
        final body = response.body;
        final data = jsonDecode(body);
        requestsToday = data['total'] ?? 0;
        answeredToday = data['completed'] ?? 0;

        // 음수 방지
        unreadNotifications = requestsToday - answeredToday;
        if (unreadNotifications < 0) unreadNotifications = 0;

        doctorName = '김닥터'; // TODO: 서버에서 닥터명 전달 시 교체
      } else {
        debugPrint("❌ 통계 데이터 로딩 실패: ${response.statusCode}");
      }

      _lineData = [];
      _categoryRatio = {};

      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadDashboardData 예외: $e");
    }
  }

  /// 최근 7일 신청 건수
  /// GET /consult/recent-7-days
  Future<void> loadRecent7DaysData(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/consult/recent-7-days'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> list = json['data'] ?? [];

        // 날짜 오름차순
        list.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));

        recent7DaysCounts = list.map((e) => (e['count'] ?? 0) as int).toList();

        // substring(5) 안전화 (YYYY-MM-DD → MM-DD)
        final dates = list.map<String>((e) => (e['date'] ?? '').toString()).toList();
        recent7DaysLabels =
            dates.map((s) => s.length >= 10 ? s.substring(5, 10) : s).toList();

        _lineData = List.generate(
          recent7DaysCounts.length,
          (i) => FlSpot(i.toDouble(), recent7DaysCounts[i].toDouble()),
        );
      } else {
        debugPrint("❌ 최근 7일 로딩 실패: ${response.statusCode}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadRecent7DaysData 예외: $e");
    }
  }

  /// 성별·연령 분포
  /// GET /consult/demographics
  Future<void> loadAgeDistributionData(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/consult/demographics'));
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;
        final gender = (data['gender'] ?? {}) as Map<String, dynamic>;
        final age = (data['age'] ?? {}) as Map<String, dynamic>;

        maleCount = (gender['male'] ?? 0) is int
            ? gender['male'] as int
            : int.tryParse('${gender['male'] ?? 0}') ?? 0;
        femaleCount = (gender['female'] ?? 0) is int
            ? gender['female'] as int
            : int.tryParse('${gender['female'] ?? 0}') ?? 0;

        ageDistributionData = age.map((k, v) {
          final key = k.toString();
          final val = (v is int) ? v : int.tryParse('$v') ?? 0;
          return MapEntry(key, val);
        });
      } else {
        debugPrint("❌ 연령/성별 로딩 실패: ${response.statusCode}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ loadAgeDistributionData 예외: $e");
      ageDistributionData = {};
      maleCount = 0;
      femaleCount = 0;
      notifyListeners();
    }
  }

  /// 시간대별 건수
  /// GET /consult/hourly-stats?date=YYYYMMDD
  Future<void> loadHourlyStats(String baseUrl, {DateTime? day}) async {
    final d = day ?? DateTime.now();
    final ymd =
        "${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}";

    try {
      final res = await http.get(Uri.parse('$baseUrl/consult/hourly-stats?date=$ymd'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? {};
        final List<dynamic> labelsRaw = data['labels'] ?? [];
        final List<dynamic> countsRaw = data['counts'] ?? [];

        // 24개 보장
        hourlyLabels = List<String>.from(labelsRaw.map((e) => e.toString()));
        if (hourlyLabels.length != 24) {
          hourlyLabels = List.generate(24, (i) => i.toString().padLeft(2, '0'));
        }

        hourlyCounts = List<int>.from(
          countsRaw.map((e) => (e is int) ? e : int.tryParse('$e') ?? 0),
        );
        if (hourlyCounts.length != 24) {
          final tmp = List<int>.filled(24, 0);
          for (int i = 0; i < hourlyCounts.length && i < 24; i++) {
            tmp[i] = hourlyCounts[i];
          }
          hourlyCounts = tmp;
        }

        hourlySpots = List.generate(
          hourlyCounts.length,
          (i) => FlSpot(i.toDouble(), hourlyCounts[i].toDouble()),
        );
      } else {
        debugPrint('❌ 시간대별 건수 로딩 실패: ${res.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadHourlyStats 예외: $e');
    }
  }

  /// 날짜별 사진 목록
  /// GET /consult/images?date=YYYY-MM-DD&limit=12&offset=0
  Future<void> loadImagesByDate(
    String baseUrl, {
    DateTime? day,
    int limit = 12,
    int offset = 0,
  }) async {
    final d = day ?? DateTime.now();
    final ymdDash =
        "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    try {
      isLoadingImages = true;
      notifyListeners();

      final uri =
          Uri.parse('$baseUrl/consult/images?date=$ymdDash&limit=$limit&offset=$offset');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> rows = body['data'] ?? [];

        imagesTotal = body['total'] is int
            ? body['total'] as int
            : int.tryParse('${body['total'] ?? ''}') ?? rows.length;

        images = rows
            .whereType<Map<String, dynamic>>()
            .map((e) => {
                  'id': e['id'],
                  'user_id': e['user_id'],
                  'image_url': e['image_url'] ?? e['image_path'] ?? '',
                  'request_datetime': e['request_datetime'],
                  'is_replied': e['is_replied'],
                })
            .toList();

        imageUrls = images
            .map((e) => (e['image_url'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        debugPrint('❌ 이미지 목록 로딩 실패: ${res.statusCode}');
        images = [];
        imageUrls = [];
        imagesTotal = 0;
      }
      isLoadingImages = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadImagesByDate 예외: $e');
      isLoadingImages = false;
      images = [];
      imageUrls = [];
      imagesTotal = 0;
      notifyListeners();
    }
  }

  /// 영상 타입 비율 (X-ray / 구강이미지)
  /// ✅ 백엔드가 YYYY-MM-DD 형식을 파싱하므로 대시 포함으로 전송
  /// GET /consult/video-type-ratio?date=YYYY-MM-DD
  Future<void> loadVideoTypeRatio(String baseUrl, {DateTime? day}) async {
    final d = day ?? DateTime.now();
    final ymdDash =
        "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/consult/video-type-ratio?date=$ymdDash'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final Map<String, dynamic> data =
            (body['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>;

        // 키 고정: "X-ray", "구강이미지" (없는 키는 0)
        final xray = (data['X-ray'] is int)
            ? data['X-ray'] as int
            : int.tryParse('${data['X-ray'] ?? 0}') ?? 0;
        final oral = (data['구강이미지'] is int)
            ? data['구강이미지'] as int
            : int.tryParse('${data['구강이미지'] ?? 0}') ?? 0;

        videoTypeRatio = {'X-ray': xray, '구강이미지': oral};
      } else {
        debugPrint('❌ 영상 타입 비율 로딩 실패: ${res.statusCode}');
        videoTypeRatio = {};
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadVideoTypeRatio 예외: $e');
      videoTypeRatio = {};
      notifyListeners();
    }
  }

  // ==================== 유틸 ====================
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
