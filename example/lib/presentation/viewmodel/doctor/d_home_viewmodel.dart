import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
// ⬇️ 경로는 프로젝트 구조에 맞게 수정
import '/services/weather_service.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  // ===== 대시보드 지표 =====
  int totalPatients = 0;
  int todayAppointments = 0;

  // ===== 날짜/시간 & 날씨 =====
  final WeatherService _weather = WeatherService();
  WeatherInfo? weather;        // 위치 라벨/기온/설명/갱신시각
  String timeText = '';        // "2025. 8. 21 오전 10:23" 형식
  Timer? _clock;
  bool isLoadingWeather = false;
  String? weatherError;

  /// 화면 진입 시 한 번 호출
  Future<void> init() async {
    fetchDashboardData();      // 기존 지표 로딩
    _startClock();             // 시계 시작(분 단위 갱신)
    await refreshWeather();    // 날씨 1회 로딩
  }

  // ===== 지표 불러오기(예시) =====
  void fetchDashboardData() {
    // TODO: API 호출로 교체
    totalPatients = 10;
    todayAppointments = 2;
    notifyListeners();
  }

  // ===== 시계 =====
  void _startClock() {
    final fmt = DateFormat('yyyy. M. d a h:mm', 'ko_KR');
    void tick() {
      timeText = fmt.format(DateTime.now());
      notifyListeners();
    }
    tick(); // 즉시 1회 표시
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => tick());
  }

  // ===== 날씨 갱신 =====
  Future<void> refreshWeather() async {
    isLoadingWeather = true;
    weatherError = null;
    notifyListeners();

    try {
      final pos = await _getPosition();
      weather = await _weather.fetchByCoords(pos.latitude, pos.longitude);
    } catch (_) {
      // 위치 거부/실패 시 서울 좌표로 폴백
      try {
        weather = await _weather.fetchByCoords(37.5665, 126.9780);
      } catch (e) {
        weatherError = '날씨 정보를 불러오지 못했습니다.';
      }
    } finally {
      isLoadingWeather = false;
      notifyListeners();
    }
  }

  // 위치 권한 & 좌표
  Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('location disabled');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('deniedForever');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}
