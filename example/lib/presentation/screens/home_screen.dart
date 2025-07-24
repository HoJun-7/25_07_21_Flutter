import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

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
  String _infoBoxText = '어떤 진료를 원하시나요?';

  static const String _defaultInfoText = '어떤 진료를 원하시나요?';

  final Map<String, double> _cardScales = {
    'photoPredict': 1.0,
    'realtimePredict': 1.0,
    'history': 1.0,
  };

  TextStyle get _juaTextStyle => GoogleFonts.jua(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );

  final Map<String, String>? _latestRecordData = {
    'date': '2024.07.22',
    'resultSummary': '우측 어금니 충치 의심',
    'detailPath': '/history',
  };

  late ScrollController _scrollController;
  final GlobalKey _photoPredictCardKey = GlobalKey();
  final GlobalKey _realtimePredictCardKey = GlobalKey();
  final GlobalKey _historyCardKey = GlobalKey();
  final GlobalKey _latestRecordCardKey = GlobalKey();

  // _cardInfoTexts는 현재 직접 사용되지 않지만, 정보 아이콘 탭 콜백에 문자열 리터럴로 전달되므로
  // 경고가 뜨는 것이 맞습니다. 이 맵을 제거하거나, 스크롤 감지를 다시 활성화하여 사용해야 합니다.
  // 여기서는 일단 남겨두겠습니다. (경고 무시 가능)
  late final Map<GlobalKey, String> _cardInfoTexts;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _cardInfoTexts = {
      _latestRecordCardKey: '가장 최근의 진단 결과를 확인합니다.',
      _photoPredictCardKey: '분석하기위한 아픈 치아 사진을 준비해주세요.',
      _realtimePredictCardKey: '카메라로 실시간 예측을 진행합니다.',
      _historyCardKey: '분석한 모든 결과를 찾아 볼 수 있습니다.',
    };
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final paddingTop = screenHeight * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MediTooth',
          style: GoogleFonts.jua(
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, paddingTop, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/cdss-icon_500.png',
                  width: 150,
                  height: 150,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 15),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F3FF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // BoxBoxShadow -> BoxShadow 로 수정
                      BoxShadow(
                        color: Colors.grey.withAlpha((255 * 0.3).round()), // withOpacity 대신 withAlpha
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _infoBoxText,
                    textAlign: TextAlign.center,
                    style: _juaTextStyle.copyWith(fontSize: 18, color: Colors.blueGrey[700]),
                  ),
                ),
                const SizedBox(height: 40),

                if (_latestRecordData != null) ...[
                  _buildLatestRecordStaticCard(
                    context,
                    globalKey: _latestRecordCardKey,
                    // 불필요한 ! 제거
                    date: _latestRecordData['date']!,
                    resultSummary: _latestRecordData['resultSummary']!,
                    onInfoTap: () => _updateInfoBoxText('가장 최근의 진단 결과를 확인합니다.'),
                  ),
                  const SizedBox(height: 25),
                ],

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
      ),
    );
  }

  Widget _buildLatestRecordStaticCard(
    BuildContext context, {
    required GlobalKey globalKey,
    required String date,
    required String resultSummary,
    VoidCallback? onInfoTap,
  }) {
    return Container(
      key: globalKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC7E6FF),
            Color(0xFFF0F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withAlpha((255 * 0.12).round()), // withOpacity 대신 withAlpha
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFADD8E6), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blueGrey[700], size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최근 진단 결과',
                  style: _juaTextStyle.copyWith(
                    color: Colors.blueGrey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('날짜: $date',
                  style: _juaTextStyle.copyWith(
                    color: Colors.blueGrey[600],
                    fontSize: 14,
                  ),
                ),
                Text('요약: $resultSummary',
                  style: _juaTextStyle.copyWith(
                    color: Colors.blueGrey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onInfoTap != null)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blueGrey), // const 추가
              onPressed: onInfoTap,
              tooltip: '설명 보기',
            ),
        ],
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
    final bool disabled = onTap == null; // 'final' 추가

    final currentScale = _cardScales[cardKey] ?? 1.0;

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
              // withOpacity 대신 withAlpha
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
                  Text(title,
                    style: GoogleFonts.jua(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                    style: GoogleFonts.jua(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!kIsWeb && onInfoTap != null)
              // const 추가
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                onPressed: onInfoTap,
              )
            else
              const Icon(Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
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
