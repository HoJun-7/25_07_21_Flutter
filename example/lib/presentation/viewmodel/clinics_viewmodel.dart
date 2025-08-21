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
        Clinic(name: '대전 스마일 치과', lat: 36.3504, lng: 127.3845, address: '대전시 중구 중앙로 110', phone: '042-123-4567'),
        Clinic(name: '대전 화이트 치과', lat: 36.3472, lng: 127.3920, address: '대전시 서구 둔산로 123', phone: '042-789-0123'),
        Clinic(name: '대전 예쁨 치과', lat: 36.3530, lng: 127.3885, address: '대전시 유성구 대학로 20', phone: '042-456-7890'),
        Clinic(name: '대전 밝은 치과', lat: 36.3515, lng: 127.3950, address: '대전시 동구 중앙로 1', phone: '042-111-2222'),
        Clinic(name: '대전 건강 치과', lat: 36.3525, lng: 127.3820, address: '대전시 서구 둔산중로 10', phone: '042-333-4444'),

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