import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorDrawer extends StatelessWidget {
  final String baseUrl;

  const DoctorDrawer({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text('의사 메뉴', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('홈'),
            onTap: () {
              Navigator.pop(context);
              context.go('/d_home'); // 홈 화면으로 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('진료 신청 현황'),
            onTap: () {
              Navigator.pop(context);
              context.go('/d_dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('진료 캘린더'),
            onTap: () {
              Navigator.pop(context);
              context.go('/d_calendar');
            },
          ),
          // 요청에 따라 '환자 목록' ListTile 제거
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              // TODO: 로그아웃 처리 로직 구현 필요
              Navigator.pop(context);
              context.go('/login'); // 로그인 화면 이동
            },
          ),
        ],
      ),
    );
  }
}