import 'package:flutter/material.dart';
// ✅ ClinicsMapScreen 임포트 추가
import 'clinics_map_screen.dart';

class ClinicsScreen extends StatelessWidget {
  const ClinicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF), // ✅ 전체 배경색 (두 번째 이미지 색)
      appBar: AppBar(
        title: const Text(
          '주변 치과',
          style: TextStyle(
            color: Colors.white, // ✅ 글씨 색 흰색
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3869A8), // ✅ AppBar 배경색 (첫 번째 이미지 색)
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 아이콘도 흰색
      ),
      body: const ClinicsMapScreen(), // ✅ ClinicsMapScreen 위젯으로 교체
    );
  }
}
