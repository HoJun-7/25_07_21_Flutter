import 'package:flutter/material.dart';

// 치과 데이터를 위한 모델 클래스
class Clinic {
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String phone;

  Clinic({
    required this.name,
    required this.lat,
    required this.lng,
    this.address = '주소 정보 없음',
    this.phone = '전화 정보 없음',
  });

  // 나중에 API 응답을 파싱하기 위한 fromJson 팩토리 메서드
  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      name: json['name'] as String,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      address: json['address'] as String? ?? '주소 정보 없음',
      phone: json['phone'] as String? ?? '전화 정보 없음',
    );
  }
}

class ClinicsViewModel extends ChangeNotifier {
  final String baseUrl; // ✅ baseUrl 저장

  List<Clinic> _clinics = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Clinic> get clinics => _clinics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ 생성자에서 baseUrl 받기
  ClinicsViewModel({required this.baseUrl}) {
    fetchClinics(); // 뷰모델 생성 시 데이터 로드 시작
  }

  // TODO: 나중에 이 메서드 내부에 실제 API 호출 로직을 구현합니다.
  Future<void> fetchClinics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 나중에 사용할 예시 (baseUrl 기반 API 호출 가능)
      // final response = await http.get(Uri.parse('$baseUrl/clinics'));
      // final List<dynamic> apiResponse = jsonDecode(response.body);
      // _clinics = apiResponse.map((json) => Clinic.fromJson(json)).toList();

      await Future.delayed(const Duration(seconds: 2)); // API 호출 흉내
      _clinics = [
        Clinic(name: '서울 스마일 치과', lat: 37.5665, lng: 126.9780, address: '서울시 중구 세종대로 110', phone: '02-123-4567'),
        Clinic(name: '강남 화이트 치과', lat: 37.4979, lng: 127.0276, address: '서울시 강남구 테헤란로 123', phone: '02-789-0123'),
        Clinic(name: '홍대 예쁨 치과', lat: 37.5575, lng: 126.9238, address: '서울시 마포구 홍익로 20', phone: '02-456-7890'),
        Clinic(name: '종로 밝은 치과', lat: 37.5700, lng: 126.9800, address: '서울시 종로구 종로 1', phone: '02-111-2222'),
        Clinic(name: '여의도 건강 치과', lat: 37.5200, lng: 126.9250, address: '서울시 영등포구 국제금융로 10', phone: '02-333-4444'),
      ];
    } catch (e) {
      _errorMessage = '치과 정보를 불러오는데 실패했습니다: ${e.toString()}';
      debugPrint('Error fetching clinics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
