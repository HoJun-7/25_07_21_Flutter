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

          // ✅ 왼쪽: 마이페이지 이동
          leading: IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () => context.go('/mypage'),
          ),

          // ✅ 중앙: 로고 + 텍스트
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/meditooth_logo.png',
                height: 30,
              ),
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

          // ✅ 오른쪽: 알림 아이콘
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
              colors: [
                primaryBackgroundColor,
                Color(0xFFE0F2F7),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/meditooth_logo.png',
                          height: 120,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '건강한 치아, MediTooth와 함께!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black45,
                                offset: Offset(3.0, 3.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.0,
                      children: [
                        _buildIconCardButton(
                          context,
                          label: 'AI 진단',
                          icon: Icons.camera_alt_rounded,
                          onPressed: () => context.push('/upload'),
                          cardColor: const Color(0xFF6A9EEB),
                        ),
                        Tooltip(
                          message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                          triggerMode: kIsWeb ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
                          child: _buildIconCardButton(
                            context,
                            label: '실시간 예측하기',
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
                            cardColor: kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0),
                            textColor: kIsWeb ? Colors.black54 : Colors.white,
                            iconColor: kIsWeb ? Colors.black54 : Colors.white,
                          ),
                        ),
                        _buildIconCardButton(
                          context,
                          label: '이전 결과 보기',
                          icon: Icons.history_edu_rounded,
                          onPressed: () => context.push('/history'),
                          cardColor: const Color(0xFFFFB380),
                        ),
                        _buildIconCardButton(
                          context,
                          label: '주변 치과 찾기',
                          icon: Icons.location_on_rounded,
                          onPressed: () => context.push('/clinics'),
                          cardColor: const Color(0xFFC2A8FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconCardButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color cardColor,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return Card(
      color: onPressed == null ? Colors.grey[300] : cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 70, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
