import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/presentation/viewmodel/doctor/d_history_viewmodel.dart';
import '/presentation/model/doctor/d_history.dart';
import 'd_result_detail_screen.dart';

extension DoctorRecordExtensions on DoctorHistoryRecord {
  String get status {
    return isReplied == 'Y' ? '진단 완료' : '진단 대기';
  }

  String get name => userName ?? userId;

  String get date {
    final dateTime = timestamp;
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String get time {
    final dateTime = timestamp;
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
  State<DTelemedicineApplicationScreen> createState() => _DTelemedicineApplicationScreenState();
}

class _DTelemedicineApplicationScreenState extends State<DTelemedicineApplicationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> statuses = ['ALL', '진단 대기', '진단 완료'];
  int _selectedIndex = 0;
  late PageController _pageController;
  int _currentPage = 0;
  final int _itemsPerPage = 8; // 요청에 따라 8로 수정

  // ▼ 알림 팝업
  bool _isNotificationPopupVisible = false;
  final List<String> _fallbackNotifications = const [
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

  List<DoctorHistoryRecord> _getFilteredRecords(List<DoctorHistoryRecord> all, String selectedStatus) {
    String keyword = _searchController.text.trim();
    return all.where((record) {
      final matchesStatus = selectedStatus == 'ALL' || record.status == selectedStatus;
      final matchesSearch = keyword.isEmpty || record.name.contains(keyword);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  List<DoctorHistoryRecord> _getPaginatedRecords(List<DoctorHistoryRecord> list) {
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
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage(List<DoctorHistoryRecord> filtered) {
    if (_currentPage + 1 < _getTotalPages(filtered)) {
      setState(() {
        _currentPage++;
      });
    }
  }

  // ▼ 웹 전용: 콘텐츠 최소 크기 보장 + 스크롤바 표시
  Widget _minSizeOnWeb(Widget child, {double minWidth = 1000, double minHeight = 720}) {
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
            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
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
  // ▲ 웹 전용: 콘텐츠 최소 크기 보장 + 스크롤바 표시

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/d_home');
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFAAD0F8),
        body: _minSizeOnWeb( // ← 여기 적용
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
                        child: kIsWeb
                            ? Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 800),
                                  child: _buildMainBody(),
                                ),
                              )
                            : _buildMainBody(),
                      ),
                      // 알림 팝업
                      Consumer<DoctorHistoryViewModel>(
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
                                    ? const Text('알림이 없습니다.', style: TextStyle(color: Colors.black54))
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: items
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
                                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                      ),
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

  /// ---------------- Side Menu ----------------
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
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _sideMenuItem(Icons.dashboard, "통합 대시보드", () => context.go('/d_home')),
          _sideMenuItem(Icons.history, "진료 현황", () => context.go('/d_dashboard')),
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
                        final filtered = _getFilteredRecords(allRecords, statuses[index]);
                        final paginated = _getPaginatedRecords(filtered);
                        final totalPages = _getTotalPages(filtered);
                        return _buildListView(filtered, paginated, totalPages);
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
                    color: _getSelectedColorByStatus(statuses[_selectedIndex]),
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
                    child: Container(
                      width: itemWidth,
                      alignment: Alignment.center,
                      child: Text(
                        statuses[index],
                        style: TextStyle(
                          color: _selectedIndex == index ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
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

  Widget _buildListView(List<DoctorHistoryRecord> records, List<DoctorHistoryRecord> paginated, int totalPages) {
    return Column(
      children: [
        Expanded(
          child: Container(
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
                    separatorBuilder: (_, __) => Divider(color: Colors.grey[300], thickness: 1),
                    itemBuilder: (context, i) {
                      final patient = paginated[i];
                      return InkWell(
                        onTap: () {
                          context.push(
                            '/d_result_detail',
                            extra: {
                              'userId': patient.userId,
                              'imagePath': patient.originalImagePath ?? '',
                              'baseUrl': widget.baseUrl,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline),
                              const SizedBox(width: 12),
                              Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('날짜 : ${patient.date}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('시간 : ${patient.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                height: 64,
                                width: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _getSelectedColorByStatus(patient.status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  patient.status,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('이전'),
            ),
            const SizedBox(width: 16),
            Text('${_currentPage + 1} / $totalPages'),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: (_currentPage + 1 < totalPages) ? () => _goToNextPage(records) : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('다음'),
            ),
          ],
        ),
      ],
    );
  }
}
