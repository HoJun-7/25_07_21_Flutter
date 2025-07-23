import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child; // ShellRoute에서 전달받을 현재 라우트의 위젯
  final String currentLocation; // 현재 라우트의 위치를 전달받을 변수

  const MainScaffold({super.key, required this.child, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    // 현재 라우트의 위치를 기반으로 BottomNavigationBar의 선택된 인덱스 결정
    int currentIndex = 0;
    final String location = currentLocation; 

    // ✅ 하단 탭 순서에 맞춰 currentIndex 로직 변경 (챗봇:0, 홈:1, 마이페이지:2)
    if (location.startsWith('/chatbot')) { 
      currentIndex = 0;
    } else if (location.startsWith('/home')) { 
      currentIndex = 1;
    } else if (location.startsWith('/mypage')) { 
      currentIndex = 2;
    }
    // /upload, /result, /history 등 ShellRoute 내 다른 화면들도 특정 탭으로 간주할 수 있음
    else if (location.startsWith('/upload') || location.startsWith('/result') || location.startsWith('/history')) {
      // 사진 진단, 진단 결과, 진단 기록 화면은 홈 탭으로 간주 (인덱스 1)
      currentIndex = 1; 
    }


    return Scaffold(
      // ShellRoute의 child 위젯을 Scaffold의 body에 표시
      body: child, 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // ✅ 탭을 눌렀을 때 해당 탭의 최상위 경로로 이동 (순서 변경에 맞춤)
          switch (index) {
            case 0: // 챗봇 탭
              context.go('/chatbot');
              break;
            case 1: // 홈 탭
              context.go('/home');
              break;
            case 2: // 마이페이지 탭
              context.go('/mypage');
              break;
            // 다른 탭이 있다면 여기에 추가
          }
        },
        items: const [
          // ✅ 하단 탭 바 아이템 순서 변경 (챗봇, 홈, 마이페이지)
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '챗봇'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}