import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child; // ShellRoute에서 전달받을 현재 라우트의 위젯
  final String currentLocation; // 현재 라우트의 위치를 전달받을 변수

  const MainScaffold({super.key, required this.child, required this.currentLocation});

  bool _isHomeBranch(String location) {
    // 홈으로 간주할 경로들
    return location.startsWith('/home') ||
           location.startsWith('/upload') ||
           location.startsWith('/history') ||
           location.startsWith('/survey') ||              // ✅ 치과 문진
           location.startsWith('/multimodal_result');     // ✅ AI 소견 결과
    // 필요시 더 추가: /camera, /diagnosis/realtime, /consult_success 등
  }

  @override
  Widget build(BuildContext context) {
    final String location = currentLocation;
    int currentIndex = 0;

    // ✅ 탭 인덱스 결정 로직
    if (location.startsWith('/chatbot')) {
      currentIndex = 0;
    } else if (_isHomeBranch(location)) {
      currentIndex = 1;
    } else if (location.startsWith('/mypage')) {
      currentIndex = 2;
    } else {
      // 기타는 기본적으로 홈로 간주 (안전망)
      if (location.startsWith('/')) {
        currentIndex = 1;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0: // 챗봇
              context.go('/chatbot');
              break;
            case 1: // 홈
              context.go('/home');
              break;
            case 2: // 마이페이지
              context.go('/mypage');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '챗봇'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}