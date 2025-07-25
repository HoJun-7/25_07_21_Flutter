import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatelessWidget {
  final String baseUrl;
  final String userId;

  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBackgroundColor = Color(0xFFB4D4FF);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('종료'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () => context.go('/mypage'),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/meditooth_logo.png', height: 30),
              const SizedBox(width: 8),
              const Text(
                'MediTooth',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 아이콘 클릭됨')),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryBackgroundColor, Color(0xFFE0F2F7)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/meditooth_logo.png',
                      height: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '건강한 치아, MediTooth와 함께!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    /// 다이아몬드 버튼 배치
                    SizedBox(
                      height: 460,  // 간격 위해 높이 증가
                      width: 400,   // 간격 위해 너비 증가
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 75,  // 위쪽 버튼 위치 조정
                            child: _buildDiamondButton(
                              context,
                              label: 'AI 진단',
                              icon: Icons.camera_alt_rounded,
                              onPressed: () => context.push('/upload'),
                              cardColor: const Color(0xFF6A9EEB),
                            ),
                          ),
                          Positioned(
                            left: 0,  // 좌측 버튼 좌표 조정
                            bottom: 150,
                            child: _buildDiamondButton(
                              context,
                              label: '이전 결과',
                              icon: Icons.history_edu_rounded,
                              onPressed: () => context.push('/history'),
                              cardColor: const Color(0xFFFFB380),
                            ),
                          ),
                          Positioned(
                            right: 40,  // 우측 버튼 좌표 조정
                            bottom: 150,
                            child: _buildDiamondButton(
                              context,
                              label: '치과 찾기',
                              icon: Icons.location_on_rounded,
                              onPressed: () => context.push('/clinics'),
                              cardColor: const Color(0xFFC2A8FF),
                            ),
                          ),
                          Positioned(
                            bottom: 40,  // 하단 버튼 위치 조정
                            child: Tooltip(
                              message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                              triggerMode: kIsWeb
                                  ? TooltipTriggerMode.longPress
                                  : TooltipTriggerMode.manual,
                              child: _buildDiamondButton(
                                context,
                                label: '실시간 예측',
                                icon: Icons.videocam_rounded,
                                onPressed: kIsWeb
                                    ? null
                                    : () => GoRouter.of(context).push(
                                          '/diagnosis/realtime',
                                          extra: {
                                            'baseUrl': baseUrl,
                                            'userId': userId,
                                          },
                                        ),
                                cardColor: kIsWeb
                                    ? const Color(0xFFD0D0D0)
                                    : const Color(0xFF82C8A0),
                                textColor: kIsWeb ? Colors.black54 : Colors.white,
                                iconColor: kIsWeb ? Colors.black54 : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 다이아몬드 형태 카드 버튼 위젯
  Widget _buildDiamondButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color cardColor,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return Transform.rotate(
      angle: 0.785398, // 45도
      child: Card(
        color: onPressed == null ? Colors.grey[300] : cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(8.0),
            child: Transform.rotate(
              angle: -0.785398, // 다시 정방향으로
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: iconColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
