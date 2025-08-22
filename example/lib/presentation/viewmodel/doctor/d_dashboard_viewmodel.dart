// lib/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';

/// 날씨 + 공기질 모델 (API 키 불필요: Open-Meteo 사용)
class WeatherInfo {
  final String locationLabel; // 예: '대전광역시 서구'
  final double tempC;         // 기온(℃)
  final double? pm10;         // μg/m³
  final double? pm25;         // μg/m³
  final String pmGrade;       // '좋음' | '보통' | '나쁨' | '매우나쁨'
  final String description;   // UI: '미세먼지 보통'

  const WeatherInfo({
    required this.locationLabel,
    required this.tempC,
    required this.pm10,
    required this.pm25,
    required this.pmGrade,
  }) : description = '미세먼지 $pmGrade';
}

/// 도시 스펙 (주요 도시 롤링용)
class CitySpec {
  final String name;      // 예: '대전'
  final double lat;
  final double lon;
  final String? subLabel; // 예: '서구'
  const CitySpec({required this.name, required this.lat, required this.lon, this.subLabel});
  String get label => subLabel == null ? name : '$name $subLabel';
}

class DoctorDashboardViewModel extends ChangeNotifier {
  DoctorDashboardViewModel();

  String? _baseUrl;
  void setBaseUrl(String baseUrl) => _baseUrl = baseUrl;

  // ===== 상단 카드 =====
  int requestsToday = 0;
  int answeredToday = 0;
  int unreadNotifications = 0;
  String doctorName = '';

  // ===== 최근 7일 =====
  List<int> recent7DaysCounts = [];
  List<String> recent7DaysLabels = [];      // MM-DD
  List<String> recent7DaysFullDates = [];   // YYYY-MM-DD
  List<FlSpot> _lineData = [];
  List<String> get recent7DaysDates => recent7DaysFullDates;

  // ===== 성별·연령 =====
  Map<String, int> ageDistributionData = {};
  int maleCount = 0;
  int femaleCount = 0;

  // ===== 시간대별 건수 =====
  List<String> hourlyLabels = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  List<int> hourlyCounts = List.filled(24, 0);
  List<FlSpot> hourlySpots = [];

  // ===== 날짜별 사진 =====
  List<Map<String, dynamic>> images = [];
  List<String> imageUrls = [];
  int imagesTotal = 0;
  bool isLoadingImages = false;

  // ===== 오버레이 포함 새 구조 =====
  final List<DashboardImageItem> imageItems = [];

  // ===== 영상 타입 비율 =====
  Map<String, int> videoTypeRatio = {};

  // (기존 호환)
  Map<String, double> _categoryRatio = {};
  Map<String, double> get categoryRatio => _categoryRatio;
  List<String> get photoUrls => imageUrls;

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

  // ===== 날짜/날씨 박스 & 시계 =====
  String timeText = '';
  WeatherInfo? weather;
  bool isLoadingWeather = false;
  String? weatherError;
  Timer? _clock;
  Timer? _clockAligner;

  // ---- 주요 도시 롤링(기본 2초 전환) + 주기적 새로고침 ----
  bool _cityTickerEnabled = false;
  List<CitySpec> _cities = const [
    CitySpec(name: '서울', lat: 37.5665, lon: 126.9780, subLabel: '중구'),
    CitySpec(name: '부산', lat: 35.1796, lon: 129.0756),
    CitySpec(name: '대구', lat: 35.8714, lon: 128.6014),
    CitySpec(name: '인천', lat: 37.4563, lon: 126.7052),
    CitySpec(name: '광주', lat: 35.1595, lon: 126.8526),
    CitySpec(name: '대전', lat: 36.3504, lon: 127.3845, subLabel: '서구'), // ✅ 대전 서구
    CitySpec(name: '울산', lat: 35.5384, lon: 129.3114),
    CitySpec(name: '세종', lat: 36.4800, lon: 127.2890),
  ];

  Duration _rotateEvery = const Duration(seconds: 4);   // ✅ 기본 2초 전환
  Duration _refreshEvery = const Duration(minutes: 7);  // 전체 새로고침 주기
  int _cityIndex = 0;
  int _tickSecond = 0;

  Timer? _secondTicker;     // 1초 틱(진행바)
  Timer? _cityRotateTimer;  // 도시 전환
  Timer? _cityRefreshTimer; // 전체 도시 데이터 새로고침
  final Map<String, WeatherInfo> _wCache = {}; // label -> WeatherInfo

  bool get cityTickerEnabled => _cityTickerEnabled;
  int get currentCityIndex => _cityIndex;
  CitySpec get currentCity => _cities[_cityIndex];
  double get cityProgress =>
      _rotateEvery.inSeconds == 0 ? 0 : (_tickSecond.clamp(0, _rotateEvery.inSeconds) / _rotateEvery.inSeconds);

  /// ✅ init에서 자동으로 도시 롤링 시작
  Future<void> init({
    String? baseUrl,
    bool autoStartCityTicker = true,
    Duration rotateEvery = const Duration(seconds: 2),
    Duration refreshEvery = const Duration(minutes: 7),
    List<CitySpec>? cities,
  }) async {
    if (baseUrl != null) _baseUrl = baseUrl;
    _startClockAligned();
    await refreshWeather(); // 첫 화면용(대전 서구)

    if (autoStartCityTicker) {
      // 롤링을 비동기로 바로 시작(화면 블로킹 없이)
      startCityTicker(
        cities: cities,
        rotateEvery: rotateEvery,
        refreshEvery: refreshEvery,
      );
    }
  }

  // ---- 롤링 컨트롤 ----
  void startCityTicker({
    List<CitySpec>? cities,
    Duration? rotateEvery,
    Duration? refreshEvery,
  }) {
    if (cities != null && cities.isNotEmpty) _cities = cities;
    if (rotateEvery != null) _rotateEvery = rotateEvery;
    if (refreshEvery != null) _refreshEvery = refreshEvery;

    _cityTickerEnabled = true;
    _tickSecond = 0;
    _cityIndex = 0;

    // 타이머 즉시 시작 (캐시는 백그라운드로 갱신)
    _startCityTimers();

    // 현재 도시 표시 (캐시 있으면 즉시, 없으면 해당 도시에 한해 fetch)
    final c = currentCity;
    final cached = _wCache[c.label];
    if (cached != null) {
      weather = cached;
      notifyListeners();
    } else {
      // 한 도시만 우선 새로고침(대기하지 않음)
      refreshWeather(lat: c.lat, lon: c.lon, locationLabel: c.label);
    }

    // 모든 도시 캐시 백그라운드 갱신
    _refreshAllCities();
  }

  void stopCityTicker() {
    _cityTickerEnabled = false;
    _cancelCityTimers();
    _tickSecond = 0;
    notifyListeners();
  }

  void manualNextCity() {
    if (!_cityTickerEnabled) return;
    _cityIndex = (_cityIndex + 1) % _cities.length;
    _tickSecond = 0;
    final c = currentCity;
    final cached = _wCache[c.label];
    if (cached != null) weather = cached;
    notifyListeners();
  }

  Future<void> manualRefreshAllCities() async {
    await _refreshAllCities();
  }

  void _startCityTimers() {
    _cancelCityTimers();

    // 초 단위 진행바
    _secondTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickSecond = (_tickSecond + 1) % (_rotateEvery.inSeconds == 0 ? 1 : _rotateEvery.inSeconds);
      notifyListeners();
    });

    // 도시 전환
    _cityRotateTimer = Timer.periodic(_rotateEvery, (_) {
      _cityIndex = (_cityIndex + 1) % _cities.length;
      _tickSecond = 0;
      final c = currentCity;
      final cached = _wCache[c.label];
      if (cached != null) {
        weather = cached; // API 호출 없이 캐시만 즉시 반영
        notifyListeners();
      }
    });

    // 실데이터 새로고침(모든 도시)
    _cityRefreshTimer = Timer.periodic(_refreshEvery, (_) async {
      await _refreshAllCities();
    });
  }

  void _cancelCityTimers() {
    _secondTicker?.cancel();
    _cityRotateTimer?.cancel();
    _cityRefreshTimer?.cancel();
  }

  Future<void> _refreshAllCities() async {
    for (final c in _cities) {
      try {
        final wi = await _fetchWeatherFromOpenMeteo(lat: c.lat, lon: c.lon, label: c.label);
        _wCache[c.label] = wi;
        if (_cityTickerEnabled && c == currentCity) {
          weather = wi; // 현재 도시면 화면도 갱신
        }
      } catch (_) {
        // 도시별 실패는 무시(캐시 유지)
      }
    }
    notifyListeners();
  }

  /// 분의 00초에 맞춰 정렬해서 1분마다 갱신
  void _startClockAligned() {
    _updateTimeText();
    _clock?.cancel();
    _clockAligner?.cancel();

    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final delay = nextMinute.difference(now);

    _clockAligner = Timer(delay, () {
      _updateTimeText();
      _clock = Timer.periodic(const Duration(minutes: 1), (_) => _updateTimeText());
    });
  }

  void _updateTimeText() {
    final now = DateTime.now();
    final ampm = (now.hour < 12) ? 'AM' : 'PM';
    final hh12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final mm = now.minute.toString().padLeft(2, '0');
    timeText = '${now.year}. ${now.month}. ${now.day}  $ampm $hh12:$mm';
    notifyListeners();
  }

  /// ✅ 날씨 + 미세먼지 갱신 (Open-Meteo / API 키 불필요)
  Future<void> refreshWeather({
    double lat = 36.3504, // 대전 위도
    double lon = 127.3845, // 대전 경도
    String locationLabel = '대전광역시 서구',
  }) async {
    isLoadingWeather = true;
    weatherError = null;
    notifyListeners();

    double temperature = weather?.tempC ?? 27.0;
    double? pm10;
    double? pm25;

    try {
      // 1) 기온: current + hourly 동시 요청
      final now = DateTime.now();
      final wUri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'Asia/Seoul',
          'current': 'temperature_2m',
          'hourly': 'temperature_2m',
          'past_days': '1',
          'forecast_days': '1',
        },
      );
      final wr = await http.get(wUri);

      double? curTemp;
      double? nearHourlyTemp;

      if (wr.statusCode == 200) {
        final j = jsonDecode(wr.body) as Map<String, dynamic>;

        if (j['current'] is Map && j['current']['temperature_2m'] is num) {
          curTemp = (j['current']['temperature_2m'] as num).toDouble();
        } else if (j['current_weather'] is Map &&
            (j['current_weather']['temperature'] is num)) {
          curTemp = (j['current_weather']['temperature'] as num).toDouble();
        }

        // hourly에서 현재와 가장 가까운 값(±90분)
        if (j['hourly'] is Map) {
          final h = j['hourly'] as Map;
          final List times = (h['time'] as List?) ?? const [];
          final List temps = (h['temperature_2m'] as List?) ?? const [];
          int bestIdx = -1;
          Duration bestGap = const Duration(days: 999);
          for (int i = 0; i < times.length && i < temps.length; i++) {
            final t = DateTime.tryParse(times[i].toString());
            if (t == null) continue;
            final gap = t.difference(now).abs();
            if (gap < bestGap) {
              bestGap = gap;
              bestIdx = i;
            }
          }
          if (bestIdx >= 0 && temps[bestIdx] is num && bestGap <= const Duration(minutes: 90)) {
            nearHourlyTemp = (temps[bestIdx] as num).toDouble();
          }
        }
      } else {
        weatherError = 'weather ${wr.statusCode}';
      }

      // 최종 기온
      temperature = (nearHourlyTemp ?? curTemp ?? temperature);

      // 2) 공기질
      final aUri = Uri.https(
        'air-quality-api.open-meteo.com',
        '/v1/air-quality',
        {
          'latitude': '$lat',
          'longitude': '$lon',
          'current': 'pm10,pm2_5',
          'timezone': 'Asia/Seoul',
        },
      );
      final ar = await http.get(aUri);
      if (ar.statusCode == 200) {
        final j = jsonDecode(ar.body) as Map<String, dynamic>;
        if (j['current'] is Map) {
          final cur = j['current'] as Map;
          if (cur['pm10'] is num) pm10 = (cur['pm10'] as num).toDouble();
          if (cur['pm2_5'] is num) pm25 = (cur['pm2_5'] as num).toDouble();
        }
        if ((pm10 == null || pm25 == null) && j['hourly'] is Map) {
          final h = j['hourly'] as Map;
          final List? t = h['time'] as List?;
          final List? pm10L = h['pm10'] as List?;
          final List? pm25L = h['pm2_5'] as List?;
          if (t != null && t.isNotEmpty) {
            final last = t.length - 1;
            if (pm10 == null && pm10L != null && pm10L.length > last && pm10L[last] is num) {
              pm10 = (pm10L[last] as num).toDouble();
            }
            if (pm25 == null && pm25L != null && pm25L.length > last && pm25L[last] is num) {
              pm25 = (pm25L[last] as num).toDouble();
            }
          }
        }
      } else {
        weatherError = [weatherError, 'air ${ar.statusCode}']
            .whereType<String>()
            .join(' / ');
      }

      final grade = _korPmGrade(pm10: pm10, pm25: pm25);
      final wi = WeatherInfo(
        locationLabel: locationLabel,
        tempC: temperature,
        pm10: pm10,
        pm25: pm25,
        pmGrade: grade,
      );
      weather = wi;

      if (_cityTickerEnabled) {
        _wCache[locationLabel] = wi;
      }
    } catch (e) {
      weatherError = e.toString();
      final grade = _korPmGrade(pm10: pm10, pm25: pm25);
      weather ??= WeatherInfo(
        locationLabel: locationLabel,
        tempC: temperature,
        pm10: pm10,
        pm25: pm25,
        pmGrade: grade,
      );
    } finally {
      isLoadingWeather = false;
      notifyListeners();
    }
  }

  /// 단일 위치 Open-Meteo 호출(캐시용)
  Future<WeatherInfo> _fetchWeatherFromOpenMeteo({
    required double lat,
    required double lon,
    required String label,
  }) async {
    double temperature = 27.0;
    double? pm10;
    double? pm25;

    final now = DateTime.now();
    final wUri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': '$lat',
        'longitude': '$lon',
        'timezone': 'Asia/Seoul',
        'current': 'temperature_2m',
        'hourly': 'temperature_2m',
        'past_days': '1',
        'forecast_days': '1',
      },
    );
    final wr = await http.get(wUri);
    if (wr.statusCode == 200) {
      final j = jsonDecode(wr.body) as Map<String, dynamic>;
      double? curTemp;
      double? nearHourlyTemp;

      if (j['current'] is Map && j['current']['temperature_2m'] is num) {
        curTemp = (j['current']['temperature_2m'] as num).toDouble();
      } else if (j['current_weather'] is Map &&
          (j['current_weather']['temperature'] is num)) {
        curTemp = (j['current_weather']['temperature'] as num).toDouble();
      }

      if (j['hourly'] is Map) {
        final h = j['hourly'] as Map;
        final List times = (h['time'] as List?) ?? const [];
        final List temps = (h['temperature_2m'] as List?) ?? const [];
        int bestIdx = -1;
        Duration bestGap = const Duration(days: 999);
        for (int i = 0; i < times.length && i < temps.length; i++) {
          final t = DateTime.tryParse(times[i].toString());
          if (t == null) continue;
          final gap = t.difference(now).abs();
          if (gap < bestGap) {
            bestGap = gap;
            bestIdx = i;
          }
        }
        if (bestIdx >= 0 && temps[bestIdx] is num && bestGap <= const Duration(minutes: 90)) {
          nearHourlyTemp = (temps[bestIdx] as num).toDouble();
        }
      }
      temperature = (nearHourlyTemp ?? curTemp ?? temperature);
    }

    final aUri = Uri.https(
      'air-quality-api.open-meteo.com',
      '/v1/air-quality',
      {
        'latitude': '$lat',
        'longitude': '$lon',
        'current': 'pm10,pm2_5',
        'timezone': 'Asia/Seoul',
      },
    );
    final ar = await http.get(aUri);
    if (ar.statusCode == 200) {
      final j = jsonDecode(ar.body) as Map<String, dynamic>;
      if (j['current'] is Map) {
        final cur = j['current'] as Map;
        if (cur['pm10'] is num) pm10 = (cur['pm10'] as num).toDouble();
        if (cur['pm2_5'] is num) pm25 = (cur['pm2_5'] as num).toDouble();
      }
      if ((pm10 == null || pm25 == null) && j['hourly'] is Map) {
        final h = j['hourly'] as Map;
        final List? t = h['time'] as List?;
        final List? pm10L = h['pm10'] as List?;
        final List? pm25L = h['pm2_5'] as List?;
        if (t != null && t.isNotEmpty) {
          final last = t.length - 1;
          if (pm10 == null && pm10L != null && pm10L.length > last && pm10L[last] is num) {
            pm10 = (pm10L[last] as num).toDouble();
          }
          if (pm25 == null && pm25L != null && pm25L.length > last && pm25L[last] is num) {
            pm25 = (pm25L[last] as num).toDouble();
          }
        }
      }
    }

    final grade = _korPmGrade(pm10: pm10, pm25: pm25);
    return WeatherInfo(
      locationLabel: label,
      tempC: temperature,
      pm10: pm10,
      pm25: pm25,
      pmGrade: grade,
    );
  }

  /// PM 등급(환경부 구간)
  String _korPmGrade({double? pm10, double? pm25}) {
    int worst = 1; // 1좋음 2보통 3나쁨 4매우나쁨
    if (pm10 != null) {
      final g = (pm10 <= 30) ? 1 : (pm10 <= 80) ? 2 : (pm10 <= 150) ? 3 : 4;
      worst = math.max(worst, g);
    }
    if (pm25 != null) {
      final g = (pm25 <= 15) ? 1 : (pm25 <= 35) ? 2 : (pm25 <= 75) ? 3 : 4;
      worst = math.max(worst, g);
    }
    switch (worst) {
      case 1:
        return '좋음';
      case 2:
        return '보통';
      case 3:
        return '나쁨';
      default:
        return '매우나쁨';
    }
  }

  // ==================== 서버 API들 ====================

  Future<void> loadDashboardData(String baseUrl) async {
    _baseUrl ??= baseUrl;
    final today = DateTime.now();
    final ymd =
        '${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    try {
      final r = await http.get(Uri.parse('$baseUrl/consult/stats?date=$ymd'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        requestsToday = _asInt(data['total']);
        answeredToday = _asInt(data['completed']);
        unreadNotifications = (requestsToday - answeredToday).clamp(0, 1 << 30);
        doctorName = (data['doctorName'] ?? '김닥터').toString();
      } else {
        debugPrint('❌ 통계 데이터 로딩 실패: ${r.statusCode}');
      }
      _lineData = [];
      _categoryRatio = {};
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadDashboardData 예외: $e');
    }
  }

  Future<void> loadRecent7DaysData(String baseUrl) async {
    _baseUrl ??= baseUrl;
    try {
      final r = await http.get(Uri.parse('$baseUrl/consult/recent-7-days'));
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        final List<dynamic> list = json['data'] ?? [];
        list.sort((a, b) => (a['date'] ?? '').compareTo(b['date'] ?? ''));
        recent7DaysCounts = list.map((e) => _asInt(e['count'])).toList();
        recent7DaysFullDates =
            list.map<String>((e) => (e['date'] ?? '').toString()).toList();
        recent7DaysLabels = recent7DaysFullDates
            .map((s) => s.length >= 10 ? s.substring(5, 10) : s)
            .toList();
        _lineData = List.generate(
          recent7DaysCounts.length,
          (i) => FlSpot(i.toDouble(), recent7DaysCounts[i].toDouble()),
        );
      } else {
        debugPrint('❌ 최근 7일 로딩 실패: ${r.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadRecent7DaysData 예외: $e');
    }
  }

  Future<void> loadAgeDistributionData(String baseUrl) async {
    _baseUrl ??= baseUrl;
    try {
      final r = await http.get(Uri.parse('$baseUrl/consult/demographics'));
      if (r.statusCode == 200) {
        final jsonBody = jsonDecode(r.body);
        final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;
        final gender = (data['gender'] ?? {}) as Map<String, dynamic>;
        final age = (data['age'] ?? {}) as Map<String, dynamic>;
        maleCount = _asInt(gender['male']);
        femaleCount = _asInt(gender['female']);
        ageDistributionData =
            age.map((k, v) => MapEntry(k.toString(), _asInt(v)));
      } else {
        debugPrint('❌ 연령/성별 로딩 실패: ${r.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadAgeDistributionData 예외: $e');
      ageDistributionData = {};
      maleCount = 0;
      femaleCount = 0;
      notifyListeners();
    }
  }

  Future<void> loadHourlyStats(String baseUrl, {DateTime? day}) async {
    _baseUrl ??= baseUrl;
    final d = day ?? DateTime.now();
    final ymd =
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    try {
      final r =
          await http.get(Uri.parse('$baseUrl/consult/hourly-stats?date=$ymd'));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body['data'] ?? {};
        final List<dynamic> labelsRaw = data['labels'] ?? [];
        final List<dynamic> countsRaw = data['counts'] ?? [];

        hourlyLabels =
            List<String>.from(labelsRaw.map((e) => e.toString()));
        if (hourlyLabels.length != 24) {
          hourlyLabels =
              List.generate(24, (i) => i.toString().padLeft(2, '0'));
        }

        hourlyCounts = List<int>.from(countsRaw.map((e) => _asInt(e)));
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
        debugPrint('❌ 시간대별 건수 로딩 실패: ${r.statusCode}');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadHourlyStats 예외: $e');
    }
  }

  Future<void> loadImagesByDate(
    String baseUrl, {
    DateTime? day,
    int limit = 12,
    int offset = 0,
  }) async {
    _baseUrl ??= baseUrl;
    final d = day ?? DateTime.now();
    final ymdDash =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      isLoadingImages = true;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/consult/images?date=$ymdDash&limit=$limit&offset=$offset');
      final r = await http.get(uri);

      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final List<dynamic> rows = body['data'] ?? [];

        imagesTotal = _asInt(body['total'], fallback: rows.length);

        images = rows.whereType<Map<String, dynamic>>().map((e) => {
              'id': e['id'],
              'user_id': e['user_id'],
              'image_url': (e['image_url'] ?? e['image_path'] ?? '').toString(),
              'request_datetime': e['request_datetime'],
              'is_replied': e['is_replied'],
            }).toList();

        imageUrls = images
            .map((e) => (e['image_url'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();

        imageItems
          ..clear()
          ..addAll(rows.whereType<Map<String, dynamic>>().map((e) {
            final original =
                (e['image_url'] ?? e['image_path'] ?? '').toString();
            final typeRaw = e['image_type'];
            final type = (typeRaw is String) ? typeRaw.toLowerCase() : null;

            final Map<String, String> overlays = (e['overlays'] is Map)
                ? Map<String, String>.from(
                    (e['overlays'] as Map)
                        .map((k, v) => MapEntry('$k', '$v')),
                  )
                : <String, String>{};

            return DashboardImageItem(
              id: _asIntOrNull(e['id']),
              userId: '${e['user_id']}',
              originalUrl: original,
              imageType: type, // 'xray' | 'normal' | null
              overlays: overlays,
              requestDateTime:
                  _safeParseDateTime(e['request_datetime']),
              isReplied: e['is_replied'] == 'Y' || e['is_replied'] == true,
            );
          }));
      } else {
        debugPrint('❌ 이미지 목록 로딩 실패: ${r.statusCode}');
        images = [];
        imageUrls = [];
        imageItems.clear();
        imagesTotal = 0;
      }
      isLoadingImages = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadImagesByDate 예외: $e');
      isLoadingImages = false;
      images = [];
      imageUrls = [];
      imageItems.clear();
      imagesTotal = 0;
      notifyListeners();
    }
  }

  Future<void> loadVideoTypeRatio(String baseUrl, {DateTime? day}) async {
    _baseUrl ??= baseUrl;
    final d = day ?? DateTime.now();
    final ymdDash =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final r = await http
          .get(Uri.parse('$baseUrl/consult/video-type-ratio?date=$ymdDash'));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final Map<String, dynamic> data =
            (body['data'] ?? const <String, dynamic>{})
                as Map<String, dynamic>;

        final xray = _asInt(data['X-ray']);
        final oral = _asInt(data['구강이미지']);

        videoTypeRatio = {'X-ray': xray, '구강이미지': oral};
      } else {
        debugPrint('❌ 영상 타입 비율 로딩 실패: ${r.statusCode}');
        videoTypeRatio = {};
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadVideoTypeRatio 예외: $e');
      videoTypeRatio = {};
      notifyListeners();
    }
  }

  // ===== 유틸 =====
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

  DateTime? _safeParseDateTime(dynamic v) {
    try {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      return DateTime.tryParse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    return fallback;
  }

  int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  List<String> layerKeysFor(DashboardImageItem item) {
    final base = (item.imageType == 'xray')
        ? <String>['original', 'xmodel1', 'xmodel2']
        : <String>['original', 'model1', 'model2', 'model3'];
    return base
        .where((k) => k == 'original' || item.overlays.containsKey(k))
        .toList();
  }

  String resolveUrl(DashboardImageItem item, String layerKey) {
    if (layerKey == 'original') return item.originalUrl;
    return item.overlays[layerKey] ?? item.originalUrl;
  }

  @override
  void dispose() {
    _clock?.cancel();
    _clockAligner?.cancel();
    _cancelCityTimers();
    super.dispose();
  }
}

/// 대시보드 이미지 아이템
class DashboardImageItem {
  final int? id;
  final String userId;
  final String originalUrl;
  final String? imageType; // 'normal' | 'xray' | null
  final Map<String, String> overlays; // {'model1': url, ...}
  final DateTime? requestDateTime;
  final bool isReplied;

  DashboardImageItem({
    required this.id,
    required this.userId,
    required this.originalUrl,
    required this.imageType,
    required this.overlays,
    required this.requestDateTime,
    required this.isReplied,
  });
}
