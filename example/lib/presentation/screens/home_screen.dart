import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  final String baseUrl;
  final String userId;

  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  int _currentPage = 0;

  final List<_DiamondButtonData> pages = [];

  @override
  void initState() {
    super.initState();

    // 버튼 정의
    pages.addAll([
      _DiamondButtonData(
        label: 'AI 진단',
        icon: Icons.camera_alt_rounded,
        color: const Color(0xFF6A9EEB),
        onTap: () => context.push('/upload'),
      ),
      _DiamondButtonData(
        label: '실시간 예측',
        icon: Icons.videocam_rounded,
        color: kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0),
        onTap: kIsWeb
            ? null
            : () => context.push('/diagnosis/realtime', extra: {
                  'baseUrl': widget.baseUrl,
                  'userId': widget.userId,
                }),
        disabled: kIsWeb,
      ),
      _DiamondButtonData(
        label: '이전 결과',
        icon: Icons.history_edu_rounded,
        color: const Color(0xFFFFB380),
        onTap: () => context.push('/history'),
      ),
      _DiamondButtonData(
        label: '치과 찾기',
        icon: Icons.location_on_rounded,
        color: const Color(0xFFC2A8FF),
        onTap: () => context.push('/clinics'),
      ),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBackgroundColor = Color(0xFFB4D4FF);

    return Scaffold(
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
            const Text('MediTooth', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 아이콘 클릭됨')),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBackgroundColor, Color(0xFFE0F2F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isCurrent = index == _currentPage;

                    return Center(
                      child: AnimatedScale(
                        scale: isCurrent ? 1.0 : 0.85,
                        duration: const Duration(milliseconds: 300),
                        child: _AnimatedDiamondButton(
                          label: page.label,
                          icon: page.icon,
                          onPressed: page.onTap,
                          cardColor: page.color,
                          textColor: page.disabled ? Colors.black54 : Colors.white,
                          iconColor: page.disabled ? Colors.black54 : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SmoothPageIndicator(
                controller: _pageController,
                count: pages.length,
                effect: const WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiamondButtonData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  _DiamondButtonData({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.disabled = false,
  });
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(8.0),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 48, color: widget.iconColor),
                      const SizedBox(height: 12),
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
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
