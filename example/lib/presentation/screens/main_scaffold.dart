import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;            // ShellRoute에서 전달받는 현재 라우트 위젯
  final String currentLocation;  // 현재 라우트 경로

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  bool _isHomeBranch(String location) {
    // 홈으로 간주할 경로들
    return location.startsWith('/home') ||
        location.startsWith('/upload') ||
        location.startsWith('/history') ||
        location.startsWith('/survey') ||            // ✅ 치과 문진
        location.startsWith('/multimodal_result');   // ✅ AI 소견 결과
    // 필요시 추가: /camera, /diagnosis/realtime, /consult_success 등
  }

  int _indexFor(String location) {
    if (location.startsWith('/chatbot')) return 0;
    if (_isHomeBranch(location)) return 1;
    if (location.startsWith('/mypage')) return 2;
    // 기타는 기본적으로 홈
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final int currentIndex = _indexFor(currentLocation);

    // 화면이 아주 작거나 텍스트 확대가 큰 경우 컴팩트 모드
    final bool compact =
        media.size.height < 560 || media.viewInsets.bottom > 0 || media.textScaler.scale(1) > 1.2;

    // 라벨/텍스트를 유지하면서도 높이를 넉넉히 주고, 바 내부만 글자 확대 상한을 둠
    final NavigationBarThemeData navTheme = NavigationBarThemeData(
      height: compact ? 60 : 68, // ⬅ 바 높이(라벨 포함 안전)
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: MaterialStateProperty.all(
        IconThemeData(size: compact ? 22 : 26),
      ),
      labelTextStyle: MaterialStateProperty.all(
        TextStyle(fontSize: compact ? 10 : 12, height: 1.0),
      ),
      // 배경/인디케이터 색을 앱 테마에 맞게 쓰고 싶다면 여기서 추가 지정
      // backgroundColor: Theme.of(context).colorScheme.surface,
      // indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
    );

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: MediaQuery(
          // ⬇️ 바 내부만 텍스트 스케일 상한 적용 → 서브픽셀 1px 오버플로우 방지
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: compact ? 1.05 : 1.15),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              useMaterial3: true,                 // NavigationBar는 M3 컴포넌트
              navigationBarTheme: navTheme,
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/chatbot');
                    break;
                  case 1:
                    context.go('/home');
                    break;
                  case 2:
                    context.go('/mypage');
                    break;
                }
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat),
                  label: '챗봇',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '마이페이지',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}