import 'dart:math' as math;
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
  bool _isNotificationPopupVisible = false;
  final List<String> _notifications = const [
    '새로운 진단 결과가 도착했습니다.',
    '예약이 내일로 예정되어 있습니다.',
    '프로필 업데이트를 완료해주세요.',
  ];

  void _toggleNotificationPopup() {
    setState(() => _isNotificationPopupVisible = !_isNotificationPopupVisible);
  }

  void _closeNotificationPopup() {
    if (_isNotificationPopupVisible) {
      setState(() => _isNotificationPopupVisible = false);
    }
  }

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
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('종료')),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeNotificationPopup,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.person, color: Colors.white, size: 28),
              onPressed: () => context.go('/mypage'),
              tooltip: '마이페이지',
            ),
            title: const SizedBox.shrink(),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                      onPressed: _toggleNotificationPopup,
                      tooltip: '알림',
                    ),
                    if (_notifications.isNotEmpty)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${_notifications.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // 배경 그라데이션
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryBackgroundColor, Color(0xFFE0F2F7)],
                  ),
                ),
              ),

              // 본문 (항상 스크롤)
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: kIsWeb ? const BoxConstraints(maxWidth: 500) : const BoxConstraints(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dpr = MediaQuery.of(context).devicePixelRatio;

                        // 패딩/영역 계산
                        final double paddingH = 16;
                        final double topSpacer = kToolbarHeight + 8;

                        final double maxW = constraints.maxWidth - paddingH * 2;
                        final double maxH = constraints.maxHeight; // 정보용 (스크롤 구조)

                        // 헤더 스케일 계산(높이는 고정하지 않음)
                        final double headerBase = 250;
                        final double headerH = math.max(140, maxH * 0.34);
                        final double headerScale = (headerH / headerBase).clamp(0.75, 1.0);
                        final double logoSize = (150 * headerScale).clamp(110, 150);
                        final double titleSize = (28 * headerScale).clamp(20, 28);

                        // Grid 타일 계산
                        const int crossCount = 2;
                        final double crossSpacing = 14;
                        final double mainSpacing = 14;

                        final double tileW = (maxW - crossSpacing) / crossCount;
                        const double naturalAspect = 1.05; // 살짝 가로가 긴 정사각형 느낌

                        // 아이콘/텍스트 스케일
                        final double iconSize = (tileW * 0.34).clamp(48, 66);
                        final double fontSize = (tileW * 0.13).clamp(14, 18);

                        // ✅ 헤더: 고정 높이(SizedBox(height: ...)) 제거 → 자연 높이 + 스크롤 포함
                        Widget header = Padding(
                          padding: EdgeInsets.only(bottom: 12 * headerScale),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: Image.asset(
                                  'assets/images/meditooth_logo.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  isAntiAlias: true,
                                  cacheWidth: (logoSize * dpr).round(),
                                  cacheHeight: (logoSize * dpr).round(),
                                ),
                              ),
                              SizedBox(height: 12 * headerScale),
                              Text(
                                '건강한 치아, MediTooth와 함께!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.15,
                                  shadows: const [
                                    Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(3.0, 3.0)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        // 타일 4개
                        List<Widget> gridChildren = [
                          _buildIconCardButton(
                            context,
                            label: 'AI 확인',
                            icon: Icons.camera_alt_rounded,
                            onPressed: () => context.push('/survey'),
                            cardColor: const Color(0xFF6A9EEB),
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                          _buildIconCardButton(
                            context,
                            label: '실시간 보기',
                            icon: Icons.videocam_rounded,
                            onPressed: kIsWeb
                                ? null
                                : () => GoRouter.of(context).push(
                                      '/diagnosis/realtime',
                                      extra: {'baseUrl': widget.baseUrl, 'userId': widget.userId},
                                    ),
                            cardColor: kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0),
                            textColor: kIsWeb ? Colors.black54 : Colors.white,
                            iconColor: kIsWeb ? Colors.black54 : Colors.white,
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                          _buildIconCardButton(
                            context,
                            label: '내 기록',
                            icon: Icons.history_edu_rounded,
                            onPressed: () => context.push('/history'),
                            cardColor: const Color(0xFFFFB380),
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                          _buildIconCardButton(
                            context,
                            label: '가까운 병원',
                            icon: Icons.location_on_rounded,
                            onPressed: () => context.push('/clinics'),
                            cardColor: const Color(0xFFC2A8FF),
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                        ];

                        // ✅ 항상 스크롤: 부모 SingleChildScrollView, 내부 GridView는 shrinkWrap + 비스크롤
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(paddingH, topSpacer, paddingH, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                header, // ← 자연 높이로 스크롤에 포함
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: crossCount,
                                  crossAxisSpacing: crossSpacing,
                                  mainAxisSpacing: mainSpacing,
                                  childAspectRatio: naturalAspect,
                                  children: gridChildren,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 알림 팝업
              if (_isNotificationPopupVisible)
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(12),
                      child: _notifications.isEmpty
                          ? const Text('알림이 없습니다.', style: TextStyle(color: Colors.black54))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _notifications
                                  .map(
                                    (msg) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.notifications_active_outlined, color: Colors.blueAccent, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(msg, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                ),
            ],
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
    double iconSize = 60,
    double fontSize = 16,
  }) {
    return Card(
      color: onPressed == null ? Colors.grey[300] : cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          // ▼▼▼ 오버플로우 방지: 내용 자동 축소 + 말줄임 ▼▼▼
          child: FittedBox(
            fit: BoxFit.scaleDown, // 카드가 작아지면 내부를 축소
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 불필요 높이 차지 방지
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: iconColor),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ▲▲▲ 오버플로우 방지 ▲▲▲
        ),
      ),
    );
  }
}