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
        backgroundColor: const Color(0xFF3869A8), // ✅ AppBar 배경색
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 아이콘 흰색
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            tooltip: '알림',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 아이콘 클릭됨')),
              );
            },
          ),
        ],
      ),
      body: const ClinicsMapScreen(), // ✅ 지도 화면
    );
  }
}
