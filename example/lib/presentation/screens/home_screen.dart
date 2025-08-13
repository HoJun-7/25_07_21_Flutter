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
  // 알림 팝업 상태 + 더미 알림 목록
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
        onTap: _closeNotificationPopup, // 바깥 탭 시 팝업 닫기
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            // ✅ 왼쪽: 마이페이지 아이콘
            leading: IconButton(
              icon: const Icon(Icons.person, color: Colors.white, size: 28),
              onPressed: () => context.go('/mypage'),
              tooltip: '마이페이지',
            ),
            title: const SizedBox.shrink(), // 가운데 타이틀 비움 (원하면 로고/텍스트 넣어도 됨)
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            // ✅ 오른쪽: 알림 버튼 + 배지
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
              // 배경 + 본문
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryBackgroundColor, Color(0xFFE0F2F7)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          kIsWeb ? const BoxConstraints(maxWidth: 500) : const BoxConstraints(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 로고 + 슬로건
                            Column(
                              children: [
                                Image.asset('assets/images/meditooth_logo.png', height: 120),
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
                            // 기능 그리드
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
                                  onPressed: () => context.push('/survey'),
                                  cardColor: const Color(0xFF6A9EEB),
                                ),
                                Tooltip(
                                  message: kIsWeb ? '웹에서는 이용할 수 없습니다.' : '',
                                  triggerMode: kIsWeb
                                      ? TooltipTriggerMode.longPress
                                      : TooltipTriggerMode.manual,
                                  child: _buildIconCardButton(
                                    context,
                                    label: '실시간 예측하기',
                                    icon: Icons.videocam_rounded,
                                    onPressed: kIsWeb
                                        ? null
                                        : () => GoRouter.of(context).push(
                                              '/diagnosis/realtime',
                                              extra: {
                                                'baseUrl': widget.baseUrl,
                                                'userId': widget.userId,
                                              },
                                            ),
                                    cardColor:
                                        kIsWeb ? const Color(0xFFD0D0D0) : const Color(0xFF82C8A0),
                                    textColor: kIsWeb ? Colors.black54 : Colors.white,
                                    iconColor: kIsWeb ? Colors.black54 : Colors.white,
                                  ),
                                ),
                                _buildIconCardButton(
                                  context,
                                  label: '진료 기록',
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

              // ✅ 알림 팝업 (오른쪽 상단 고정)
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
                                          const Icon(Icons.notifications_active_outlined,
                                              color: Colors.blueAccent, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              msg,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
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
  }) {
    return Card(
      color: onPressed == null ? Colors.grey[300] : cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}