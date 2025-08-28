import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'city_specs.dart';

@immutable
class CityWeather {
  final double tempC;
  final int weatherCode; // WMO 코드
  final DateTime fetchedAt;
  const CityWeather({
    required this.tempC,
    required this.weatherCode,
    required this.fetchedAt,
  });
}

class NationalWeatherService extends ChangeNotifier {
  final List<CitySpec> cities;
  final Duration rotateEvery;
  final Duration refreshEvery;

  NationalWeatherService({
    required this.cities,
    this.rotateEvery = const Duration(seconds: 8),
    this.refreshEvery = const Duration(minutes: 15),
  }) : assert(cities.isNotEmpty) {
    _start();
  }

  // 실시간 시계 (초단위)
  final ValueNotifier<DateTime> now = ValueNotifier<DateTime>(DateTime.now());

  int _index = 0;
  Map<String, CityWeather> _byCity = <String, CityWeather>{};

  Timer? _clock;
  Timer? _rotator;
  Timer? _refresher;

  CitySpec get currentCity => cities[_index % cities.length];
  CityWeather? get currentCityWeather => _byCity[currentCity.name];

  void _start() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
    _rotator = Timer.periodic(rotateEvery, (_) {
      _index = (_index + 1) % cities.length;
      notifyListeners();
    });
    _refresher = Timer.periodic(refreshEvery, (_) => refreshAll());
    unawaited(refreshAll()); // 최초 1회
  }

  Future<void> refreshAll() async {
    for (final c in cities) {
      await _fetchOne(c);
      await Future.delayed(const Duration(milliseconds: 120));
    }
    notifyListeners();
  }

  Future<void> _fetchOne(CitySpec c) async {
    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': c.lat.toString(),
          'longitude': c.lon.toString(),
          'current': 'temperature_2m,weather_code',
          'timezone': 'Asia/Seoul',
        },
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final cur = m['current'] as Map<String, dynamic>;
        final t = (cur['temperature_2m'] as num).toDouble();
        final code = (cur['weather_code'] as num).toInt();
        _byCity = Map<String, CityWeather>.from(_byCity)
          ..[c.name] = CityWeather(
            tempC: t,
            weatherCode: code,
            fetchedAt: DateTime.now(),
          );
      }
    } catch (_) {
      // 네트워크 실패는 다음 주기에서 복구
    }
  }

  static String wmoToKo(int code) {
    switch (code) {
      case 0: return '맑음';
      case 1:
      case 2: return '대체로 맑음';
      case 3: return '흐림';
      case 45:
      case 48: return '안개';
      case 51:
      case 53:
      case 55: return '이슬비';
      case 61:
      case 63:
      case 65: return '비';
      case 66:
      case 67: return '어는 비';
      case 71:
      case 73:
      case 75: return '눈';
      case 77: return '눈날림';
      case 80:
      case 81:
      case 82: return '소나기';
      case 85:
      case 86: return '소낙눈';
      case 95: return '뇌우';
      case 96:
      case 99: return '뇌우·우박';
      default: return '날씨';
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _rotator?.cancel();
    _refresher?.cancel();
    now.dispose();
    super.dispose();
  }
}