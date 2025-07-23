import 'package:flutter/material.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  // 예시 데이터 (추후 확장 가능)
  int totalPatients = 0;
  int todayAppointments = 0;

  void fetchDashboardData() {
    // TODO: API 호출로 데이터 불러오기
    totalPatients = 10;
    todayAppointments = 2;
    notifyListeners();
  }
}
