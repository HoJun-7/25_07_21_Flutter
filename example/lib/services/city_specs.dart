import 'package:flutter/foundation.dart';

@immutable
class CitySpec {
  final String name;
  final double lat;
  final double lon;
  const CitySpec({required this.name, required this.lat, required this.lon});
}

/// 대한민국 주요 도시 좌표
const List<CitySpec> kKoreaMajorCities = [
  CitySpec(name: '서울', lat: 37.5665, lon: 126.9780),
  CitySpec(name: '부산', lat: 35.1796, lon: 129.0756),
  CitySpec(name: '대구', lat: 35.8714, lon: 128.6014),
  CitySpec(name: '인천', lat: 37.4563, lon: 126.7052),
  CitySpec(name: '광주', lat: 35.1595, lon: 126.8526),
  CitySpec(name: '대전', lat: 36.3504, lon: 127.3845),
  CitySpec(name: '울산', lat: 35.5384, lon: 129.3114),
  CitySpec(name: '세종', lat: 36.4800, lon: 127.2890),
  CitySpec(name: '수원', lat: 37.2636, lon: 127.0286),
  CitySpec(name: '고양', lat: 37.6584, lon: 126.8320),
  CitySpec(name: '용인', lat: 37.2411, lon: 127.1776),
  CitySpec(name: '제주', lat: 33.4996, lon: 126.5312),
];
