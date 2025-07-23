import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import '/presentation/model/doctor/d_patient.dart'; // d_patient.dart 모델 임포트

class DPatientViewModel with ChangeNotifier {
  final String _baseUrl;
  List<Patient> _patients = [];
  Patient? _currentPatient;
  String? _errorMessage;
  bool _isLoading = false;

  // ✅ 생성자에 required String baseUrl 추가
  DPatientViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  List<Patient> get patients => _patients;
  Patient? get currentPatient => _currentPatient;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 특정 의사의 환자 목록 불러오기
  Future<void> fetchPatients(int doctorId) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patient/list/$doctorId')); // 백엔드 엔드포인트 확인

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _patients = data.map((json) => Patient.fromJson(json)).toList();
      } else {
        String message = '환자 목록 불러오기 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _setErrorMessage(message);
      }
    } catch (e) {
      _setErrorMessage('네트워크 오류: ${e.toString()}');
      if (kDebugMode) {
        print('환자 목록 불러오기 중 네트워크 오류: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 특정 환자 정보 불러오기 메서드 추가
  Future<void> fetchPatient(int patientId) async {
    _setLoading(true);
    _setErrorMessage(null);
    _currentPatient = null;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$_baseUrl/patient/$patientId')); // 백엔드 엔드포인트 확인

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        _currentPatient = Patient.fromJson(data);
      } else {
        String message = '환자 정보 불러오기 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _setErrorMessage(message);
      }
    } catch (e) {
      _setErrorMessage('네트워크 오류: ${e.toString()}');
      if (kDebugMode) {
        print('환자 정보 불러오기 중 네트워크 오류: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // 새로운 환자 추가
  Future<bool> addPatient({
    required int doctorId,
    required String name,
    required String dateOfBirth,
    required String gender,
    String? phoneNumber,
    String? address,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/patient/add'), // 백엔드 엔드포인트 확인
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorId': doctorId,
          'name': name,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      );

      if (res.statusCode == 201) {
        await fetchPatients(doctorId); // 성공적으로 추가되면 목록을 새로고침
        return true;
      } else {
        String message = '환자 추가 실패 (Status: ${res.statusCode})';
        try {
          final decodedBody = json.decode(res.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            message = decodedBody['message'] as String;
          }
        } catch (e) {
          // Body was not valid JSON
        }
        _setErrorMessage(message);
        return false;
      }
    } catch (e) {
      _setErrorMessage('네트워크 오류: ${e.toString()}');
      if (kDebugMode) {
        print('환자 추가 중 네트워크 오류: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
