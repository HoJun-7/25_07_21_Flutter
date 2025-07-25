import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _photoPredictCardKey = GlobalKey();
  final GlobalKey _realtimePredictCardKey = GlobalKey();
  final GlobalKey _historyCardKey = GlobalKey();

  String _infoBoxText = '어떤 분석을 원하시나요?';

  static const String _defaultInfoText = '어떤 분석을 원하시나요?';

  final Map<String, double> _cardScales = {
    'photoPredict': 1.0,
    'realtimePredict': 1.0,
    'history': 1.0,
  };

  TextStyle get _juaTextStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateInfoBoxText(String newText) {
    setState(() {
      _infoBoxText = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediTooth',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7EB7E6),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => context.go('/mypage'),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5FAFF),
        width: double.infinity,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _infoBoxText,
                style: _juaTextStyle,
              ),
              const SizedBox(height: 25),
              _buildCardWithHoverAndTapEffect(
                context,
                cardKey: 'photoPredict',
                globalKey: _photoPredictCardKey,
                title: '사진으로 예측하기',
                subtitle: '분석하기위한 아픈 치아 사진을 준비해주세요.',
                icon: Icons.photo_camera,
                gradientColors: const [
                  Color(0xFF6A9BFD),
                  Color(0xFF8DC6FF),
                ],
                onTap: () => context.push('/upload'),
                hoverText: '분석하기위한 아픈 치아 사진을 준비해주세요.',
                onInfoTap: () => _updateInfoBoxText('분석하기위한 아픈 치아 사진을 준비해주세요.'),
              ),
              const SizedBox(height: 25),
              _buildCardWithHoverAndTapEffect(
                context,
                cardKey: 'realtimePredict',
                globalKey: _realtimePredictCardKey,
                title: '실시간 예측하기',
                subtitle: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '카메라로 실시간 예측을 진행합니다.',
                icon: Icons.videocam,
                gradientColors: kIsWeb
                    ? [Colors.grey.shade300, Colors.grey.shade200]
                    : const [
                        Color(0xFF63B8BD),
                        Color(0xFF86DDE1),
                      ],
                onTap: kIsWeb
                    ? null
                    : () => GoRouter.of(context).push(
                          '/diagnosis/realtime',
                          extra: {
                            'baseUrl': widget.baseUrl,
                            'userId': widget.userId,
                          },
                        ),
                hoverText: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '카메라로 실시간 예측을 진행합니다.',
                onInfoTap: () => _updateInfoBoxText('카메라로 실시간 예측을 진행합니다.'),
              ),
              const SizedBox(height: 25),
              _buildCardWithHoverAndTapEffect(
                context,
                cardKey: 'history',
                globalKey: _historyCardKey,
                title: '이전 결과 보기',
                subtitle: '분석한 모든 결과를 찾아 볼 수 있습니다.',
                icon: Icons.history,
                gradientColors: const [
                  Color(0xFF879FFF),
                  Color(0xFFB8CFFF),
                ],
                onTap: () => context.push('/history'),
                hoverText: '분석한 모든 결과를 찾아 볼 수 있습니다.',
                onInfoTap: () => _updateInfoBoxText('분석한 모든 결과를 찾아 볼 수 있습니다.'),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithHoverAndTapEffect(
    BuildContext context, {
    required String cardKey,
    required GlobalKey globalKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
    required String hoverText,
    VoidCallback? onInfoTap,
  }) {
    final bool disabled = onTap == null;
    final double currentScale = _cardScales[cardKey] ?? 1.0;

    Widget mainCardContent = AnimatedScale(
      scale: currentScale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withAlpha((255 * (currentScale > 1.0 ? 0.3 : 0.12)).round()),
              blurRadius: currentScale > 1.0 ? 12 : 6,
              spreadRadius: currentScale > 1.0 ? 4 : 2,
              offset: Offset(0, currentScale > 1.0 ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!kIsWeb && onInfoTap != null)
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                onPressed: onInfoTap,
              )
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );

    if (kIsWeb) {
      return MouseRegion(
        onEnter: (_) => setState(() {
          _cardScales[cardKey] = 1.03;
          _updateInfoBoxText(hoverText);
        }),
        onExit: (_) => setState(() {
          _cardScales[cardKey] = 1.0;
          _updateInfoBoxText(_defaultInfoText);
        }),
        child: GestureDetector(
          onTapDown: (_) {
            if (!disabled) {
              setState(() {
                _cardScales[cardKey] = 0.98;
              });
            }
          },
          onTapUp: (_) {
            if (!disabled) {
              setState(() {
                _cardScales[cardKey] = 1.0;
              });
            }
          },
          onTapCancel: () {
            if (!disabled) {
              setState(() {
                _cardScales[cardKey] = 1.0;
              });
            }
          },
          onTap: onTap,
          child: mainCardContent,
        ),
      );
    } else {
      return GestureDetector(
        key: globalKey,
        onTapDown: (_) {
          if (!disabled) {
            setState(() {
              _cardScales[cardKey] = 0.98;
            });
          }
        },
        onTapUp: (_) {
          if (!disabled) {
            setState(() {
              _cardScales[cardKey] = 1.0;
            });
          }
        },
        onTapCancel: () {
          if (!disabled) {
            setState(() {
              _cardScales[cardKey] = 1.0;
            });
          }
        },
        onTap: onTap,
        child: mainCardContent,
      );
    }
  }
}
