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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
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
                    SizedBox(
                      height: 460,
                      width: 400,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 75,
                            child: _AnimatedDiamondButton(
                              label: 'AI 진단',
                              icon: Icons.camera_alt_rounded,
                              onPressed: () => context.push('/upload'),
                              cardColor: const Color(0xFF6A9EEB),
                            ),
                          ),
                          Positioned(
                            left: 40,
                            bottom: 150,
                            child: _AnimatedDiamondButton(
                              label: '이전 결과',
                              icon: Icons.history_edu_rounded,
                              onPressed: () => context.push('/history'),
                              cardColor: const Color(0xFFFFB380),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            bottom: 150,
                            child: _AnimatedDiamondButton(
                              label: '치과 찾기',
                              icon: Icons.location_on_rounded,
                              onPressed: () => context.push('/clinics'),
                              cardColor: const Color(0xFFC2A8FF),
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            child: Tooltip(
                              message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                              triggerMode: kIsWeb ? TooltipTriggerMode.longPress : TooltipTriggerMode.manual,
                              child: _AnimatedDiamondButton(
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
                                cardColor: kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0),
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
}

class _AnimatedDiamondButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color cardColor;
  final Color textColor;
  final Color iconColor;

  const _AnimatedDiamondButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.cardColor,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
  });

  @override
  State<_AnimatedDiamondButton> createState() => _AnimatedDiamondButtonState();
}

class _AnimatedDiamondButtonState extends State<_AnimatedDiamondButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 0.93);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Card(
            color: widget.onPressed == null ? Colors.grey[300] : widget.cardColor,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(8.0),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 38, color: widget.iconColor), // ✅ 아이콘 크기 증가
                      const SizedBox(height: 6),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14, // ✅ 텍스트 크기 증가
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
