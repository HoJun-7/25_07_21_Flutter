// lib/presentation/screens/doctor/d_telemedicine_application_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '/presentation/viewmodel/doctor/d_history_viewmodel.dart';
import '/presentation/model/doctor/d_history.dart';
import '/presentation/screens/doctor/doctor_drawer.dart'; // 모바일 드로어
import '/presentation/viewmodel/auth_viewmodel.dart'; // 썸네일 토큰

/// 화면에서 편하게 쓰기 위한 보조 getter 들(충돌 방지: isXray 는 d_history.dart 에서만 정의)
extension DoctorRecordUi on DoctorHistoryRecord {
  String get status => isReplied == 'Y' ? '진단 완료' : '진단 대기';
  String get name => userName ?? userId;

  String get date {
    final dt = timestamp;
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  String get time {
    final dt = timestamp;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class DTelemedicineApplicationScreen extends StatefulWidget {
  final String baseUrl;
  final int initialTab;

  const DTelemedicineApplicationScreen({
    super.key,
    required this.baseUrl,
    this.initialTab = 0,
  });

  @override
  State<DTelemedicineApplicationScreen> createState() =>
      _DTelemedicineApplicationScreenState();
}

class _DTelemedicineApplicationScreenState
    extends State<DTelemedicineApplicationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> statuses = ['ALL', '진단 대기', '진단 완료'];
  int _selectedIndex = 0;
  late PageController _pageController;
  int _currentPage = 0;
  final int _itemsPerPage = 8;

  // ▼ 알림 팝업
  bool _isNotificationPopupVisible = false;
  final List<String> _fallbackNotifications = const [
    '새로운 진단 결과가 도착했습니다.',
    '예약이 내일로 예정되어 있습니다.',
    '프로필 업데이트를 완료해주세요.',
  ];

  void _toggleNotificationPopup() =>
      setState(() => _isNotificationPopupVisible = !_isNotificationPopupVisible);
  void _closeNotificationPopup() {
    if (_isNotificationPopupVisible) {
      setState(() => _isNotificationPopupVisible = false);
    }
  }

  double _notifPopupTop(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;
    return kIsWeb ? 4 : (padTop + 8);
  }

  List<String> _safeNotifications(DoctorHistoryViewModel vm) {
    try {
      final dynamic n = (vm as dynamic).notifications;
      if (n is List<String>) return n;
    } catch (_) {}
    return _fallbackNotifications;
  }
  // ▲ 알림 팝업

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _pageController = PageController(initialPage: _selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorHistoryViewModel>().fetchConsultRecords();

      final extra = GoRouterState.of(context).extra;
      if (extra is Map && extra.containsKey('initialTab')) {
        final int index = extra['initialTab'] ?? 0;
        if (index >= 0 && index < statuses.length) {
          setState(() {
            _selectedIndex = index;
            _pageController.jumpToPage(index);
          });
        }
      }
    });
  }

  bool _isMobile(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // 휴대폰/태블릿(협의치) + 웹이 아닌 경우 → 모바일로 간주
    return !kIsWeb && w < 900;
  }

  List<DoctorHistoryRecord> _getFilteredRecords(
      List<DoctorHistoryRecord> all,
      String selectedStatus,
      ) {
    // ✅ 대소문자 무시 검색
    final keyword = _searchController.text.trim().toLowerCase();
    return all.where((r) {
      final matchesStatus = selectedStatus == 'ALL' || r.status == selectedStatus;
      final matchesSearch =
          keyword.isEmpty || (r.name).toLowerCase().contains(keyword);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  List<DoctorHistoryRecord> _getPaginatedRecords(
      List<DoctorHistoryRecord> list) {
    final start = _currentPage * _itemsPerPage;
    final end = (_currentPage + 1) * _itemsPerPage;
    return list.sublist(start, end > list.length ? list.length : end);
  }

  int _getTotalPages(List<DoctorHistoryRecord> filtered) =>
      (filtered.length / _itemsPerPage).ceil();

  Color _getSelectedColorByStatus(String status) {
    switch (status) {
      case '진단 대기':
        return Colors.orange;
      case '진단 완료':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  void _goToNextPage(List<DoctorHistoryRecord> filtered) {
    if (_currentPage + 1 < _getTotalPages(filtered)) {
      setState(() => _currentPage++);
    }
  }

  // ▼ 웹 전용: 콘텐츠 최소 크기 보장 + 스크롤바
  Widget _minSizeOnWeb(Widget child,
      {double minWidth = 1000, double minHeight = 720}) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsH = constraints.maxWidth < minWidth;
        final needsV = constraints.maxHeight < minHeight;
        final hCtrl = ScrollController();
        final vCtrl = ScrollController();
        Widget content = child;

        if (needsV) {
          content = Scrollbar(
            controller: vCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: vCtrl,
              scrollDirection: Axis.vertical,
              child: SizedBox(height: minHeight, child: content),
            ),
          );
        }
        if (needsH) {
          content = Scrollbar(
            controller: hCtrl,
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: hCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: minWidth, child: content),
            ),
          );
        }
        return content;
      },
    );
  }
  // ▲ 웹 전용

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return WillPopScope(
      onWillPop: () async {
        context.go('/d_home');
        return false;
      },
      child: isMobile
          // ===================== 모바일: AppBar + Drawer =====================
          ? Scaffold(
        backgroundColor: const Color(0xFFAAD0F8),
        appBar: AppBar(
          title: const Text('진료 현황'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: _toggleNotificationPopup,
            ),
          ],
        ),
        drawer: DoctorDrawer(baseUrl: widget.baseUrl),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeNotificationPopup,
          child: Stack(
            children: [
              SafeArea(child: _buildMainBody()),
              _buildNotificationPopup(),
            ],
          ),
        ),
      )
      // ===================== 웹/데스크톱: 좌측 고정 사이드바 + 본문 =====================
          : Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFAAD0F8),
        body: _minSizeOnWeb(
          Row(
            children: [
              _buildSideMenu(),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeNotificationPopup,
                  child: Stack(
                    children: [
                      SafeArea(
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                            const BoxConstraints(maxWidth: 800),
                            child: _buildMainBody(),
                          ),
                        ),
                      ),
                      _buildNotificationPopup(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 공통 알림 팝업 (모바일/웹 공용)
  Widget _buildNotificationPopup() {
    return Consumer<DoctorHistoryViewModel>(
      builder: (_, vm, __) {
        if (!_isNotificationPopupVisible) return const SizedBox.shrink();
        final items = _safeNotifications(vm);
        return Positioned(
          top: _notifPopupTop(context),
          right: 12,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(12),
              child: items.isEmpty
                  ? const Text('알림이 없습니다.',
                  style: TextStyle(color: Colors.black54))
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map(
                      (msg) => Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
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
        );
      },
    );
  }

  /// ---------------- (웹 전용) Side Menu ----------------
  Widget _buildSideMenu() {
    return Container(
      width: 220,
      color: const Color(0xFF2D9CDB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "MediTooth",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _sideMenuItem(Icons.dashboard, "통합 대시보드", () => context.go('/d_home')),
          _sideMenuItem(Icons.history, "진료 현황", () => context.go('/d_dashboard')),
          _sideMenuItem(Icons.notifications, "알림", _toggleNotificationPopup),
          _sideMenuItem(Icons.logout, "로그아웃", () => context.go('/login')),
        ],
      ),
    );
  }

  Widget _sideMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
  /// -------------------------------------------

  // 본문
  Widget _buildMainBody() {
    return Consumer<DoctorHistoryViewModel>(
      builder: (context, viewModel, _) {
        final allRecords = viewModel.records;

        return Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(),
            _buildStatusChips(),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _currentPage = 0;
                  });
                },
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final filtered =
                      _getFilteredRecords(allRecords, statuses[index]);
                  final paginated = _getPaginatedRecords(filtered);
                  final totalPages = _getTotalPages(filtered);
                  return _buildListView(
                      filtered, paginated, totalPages);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 0),
              decoration: const InputDecoration(
                hintText: '환자 이름을 검색하세요',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () => setState(() => _currentPage = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / statuses.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: itemWidth,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color:
                    _getSelectedColorByStatus(statuses[_selectedIndex]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Row(
                children: List.generate(statuses.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _currentPage = 0;
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
                    child: SizedBox(
                      width: itemWidth,
                      child: Center(
                        child: Text(
                          statuses[index],
                          style: TextStyle(
                            color: _selectedIndex == index
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListView(
      List<DoctorHistoryRecord> records,
      List<DoctorHistoryRecord> paginated,
      int totalPages,
      ) {
    // ✅ 이미지 base URL (API base에서 /api 제거)
    final imageBaseUrl = widget.baseUrl.replaceAll('/api', '');

    // ✅ 하단 페이지 표시(0건일 때 0/0로 안전)
    final displayCurrent = totalPages == 0 ? 0 : (_currentPage + 1);
    final displayTotal = totalPages == 0 ? 0 : totalPages;

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: records.isEmpty
                ? const Center(child: Text('일치하는 환자가 없습니다.'))
                : ListView.separated(
              itemCount: paginated.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final patient = paginated[i];

                // 썸네일 URL (없으면 null)
                final thumbPath =
                    patient.originalImagePath ?? patient.imagePath ?? '';
                final hasThumb = thumbPath.isNotEmpty;
                final thumbUrl = hasThumb ? '$imageBaseUrl$thumbPath' : null;

                return PressableCard(
                  shadow: false,
                  borderRadius:
                  const BorderRadius.all(Radius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  margin: EdgeInsets.zero,
                  onTap: () async {
                    // ✅ X-ray 여부에 따라 다른 상세화면으로
                    final route = patient.isXray
                        ? 'doctor-xray-result-detail'
                        : 'doctor-photo-result-detail';

                    // ===== ▼▼▼ 환자쪽과 동일한 페이로드 구성 ▼▼▼ =====
                    final relOrAbs = patient.originalImageUrl; // 상대 or 절대
                    if (relOrAbs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미지 경로가 비어 있습니다.')),
                      );
                      return;
                    }

                    // 원본 절대 URL
                    final originalImageUrl = relOrAbs.startsWith('http')
                        ? relOrAbs
                        : '$imageBaseUrl${relOrAbs.startsWith('/') ? '' : '/'}$relOrAbs';

                    // 파일명 추출 (오버레이 URL 조합용)
                    final filename = relOrAbs.split('/').isNotEmpty
                        ? relOrAbs.split('/').last
                        : relOrAbs;

                    // 오버레이 절대 URL 맵 (환자쪽 규칙과 동일)
                    final Map<int, String> processedImageUrls = patient.isXray
                        ? {
                      1: '$imageBaseUrl/images/xmodel1/$filename',
                      2: '$imageBaseUrl/images/xmodel2/$filename',
                    }
                        : {
                      1: '$imageBaseUrl/images/model1/$filename',
                      2: '$imageBaseUrl/images/model2/$filename',
                      3: '$imageBaseUrl/images/model3/$filename',
                    };

                    // 모델 결과(팔레트/라벨 등) 그대로
                    final modelInfos = patient.modelInfos;

                    // consult 상태
                    final isRequested = 'Y';
                    final isReplied = (patient.isReplied == 'Y') ? 'Y' : 'N';

                    // 상세 화면 이동 (환자쪽과 동일 키명)
                    final result = await context.pushNamed<bool>(
                      route,
                      extra: {
                        'userId': patient.userId,
                        'originalImageUrl': originalImageUrl,       // ✅ 절대 URL
                        'processedImageUrls': processedImageUrls,    // ✅ 오버레이 절대 URL
                        'modelInfos': modelInfos,                  // ✅ 팔레트/라벨 등
                        'inferenceResultId': patient.inferenceResultId,
                        'baseUrl': widget.baseUrl,
                        'isRequested': isRequested,
                        'isReplied': isReplied,
                        if (patient.requestId != null)
                          'requestId': patient.requestId,
                      },
                    );
                    // 상세 화면에서 true를 반환하면 목록을 새로고침합니다.
                    if (result == true && mounted) {
                      context.read<DoctorHistoryViewModel>().fetchConsultRecords();
                    }
                    // ===== ▲▲▲ 변경 끝 ▲▲▲ =====
                  },
                  child: Row(
                    children: [
                      // 썸네일
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasThumb
                            ? _AuthThumb(
                          url: thumbUrl!,
                          baseUrl: widget.baseUrl,
                          size: 56,
                        )
                            : Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6FB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.shade400,
                                width: 0.5),
                          ),
                          child: const Icon(Icons.image_not_supported,
                              size: 20, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(patient.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('날짜 : ${patient.date}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          Text('시간 : ${patient.time}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        height: 64,
                        width: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                          _getSelectedColorByStatus(patient.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          patient.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 하단 네비게이션
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('이전'),
              ),
              const SizedBox(width: 16),
              Text('$displayCurrent / $displayTotal'),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: (_currentPage + 1 < totalPages)
                    ? () => _goToNextPage(records)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('다음'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 인증 썸네일 위젯 (history_screen.dart 과 동일)
/// ─────────────────────────────────────────────────────────
class _AuthThumb extends StatefulWidget {
  final String url;      // 절대 URL (imageBaseUrl + path)
  final String baseUrl;  // api base (토큰 발급용)
  final double size;

  const _AuthThumb({
    super.key,
    required this.url,
    required this.baseUrl,
    this.size = 56,
  });

  @override
  State<_AuthThumb> createState() => _AuthThumbState();
}

class _AuthThumbState extends State<_AuthThumb> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _AuthThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _bytes = null;
    });
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (!mounted) return;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(widget.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      setState(() {
        _bytes = res.statusCode == 200 ? res.bodyBytes : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias, // 모서리/리플/히트테스트 완전 일치
      child: _loading
          ? const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      )
          : (_bytes != null
          ? Image.memory(_bytes!, fit: BoxFit.cover)
          : const Icon(Icons.image_not_supported,
          size: 20, color: Colors.grey)),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 눌림 애니메이션 카드 (라운드 모양과 클릭 범위 일치, 내부 리스트용 그림자 off 지원)
/// ─────────────────────────────────────────────────────────
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color background;
  final bool shadow; // 내부에서는 false 권장

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.background = Colors.white,
    this.shadow = true,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius as BorderRadius? ?? BorderRadius.circular(16);
    final shape = RoundedRectangleBorder(borderRadius: r);

    Widget core = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(0.0, _pressed ? 2.0 : 0.0)
        ..scale(_pressed ? 0.985 : 1.0, _pressed ? 0.985 : 1.0),
      child: Material(
        color: widget.background,
        elevation: 0,
        shape: shape,
        clipBehavior: Clip.antiAlias, // 모서리/리플/히트테스트 완전 일치
        child: InkWell(
          customBorder: shape, // 둥근 모양 클릭 영역
          onTap: widget.onTap,
          onHighlightChanged: (v) => _setPressed(v),
          onHover: (v) => _setHovered(v),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (!widget.shadow) {
      return Padding(padding: widget.margin, child: core);
    }

    // 외곽 그림자(리스트 바깥 단독 카드에 사용)
    final shadow = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: const Color(0x2A000000),
            blurRadius: _pressed ? 10 : (_hovered ? 20 : 16),
            spreadRadius: _pressed ? 0.5 : 1.2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: core,
    );

    return Padding(padding: widget.margin, child: shadow);
  }
}