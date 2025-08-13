import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // mapIndexed 사용을 위해 추가
import 'dart:async'; // ⬅ 추가
import 'package:flutter/foundation.dart' show kIsWeb; // ⬅ 웹 폭 고정용 추가

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart'; // ViewModel은 여기서 import만!
import '/presentation/screens/doctor/doctor_drawer.dart'; // DoctorDrawer는 여기서 import만!

// -------------------------
// DRealHomeScreen (Dashboard Home)
// -------------------------
class DRealHomeScreen extends StatefulWidget {
  final String baseUrl;
  const DRealHomeScreen({super.key, required this.baseUrl});

  @override
  State<DRealHomeScreen> createState() => _DRealHomeScreenState();
}

class _DRealHomeScreenState extends State<DRealHomeScreen> with WidgetsBindingObserver {
  Timer? _autoRefreshTimer; // ⬅ 타이머 변수

  // ====== HomeScreen의 알림 팝업 로직 이식 ======
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
  // ========================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 첫 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<DoctorDashboardViewModel>();
      await vm.loadDashboardData(widget.baseUrl);
      await vm.loadRecent7DaysData(widget.baseUrl);
    });

    // 1분마다 자동 갱신 (카드 + 그래프)
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        final vm = context.read<DoctorDashboardViewModel>();
        vm.loadDashboardData(widget.baseUrl);
        vm.loadRecent7DaysData(widget.baseUrl);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final vm = context.read<DoctorDashboardViewModel>();
      vm.loadDashboardData(widget.baseUrl);
      vm.loadRecent7DaysData(widget.baseUrl);
    }
  }

  // 뒤로가기 시 앱 종료 팝업
  Future<bool> _onWillPop() async {
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
  }

  // 범례를 그리는 위젯
  Widget _buildCategoryLegend(DoctorDashboardViewModel vm) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          runSpacing: 8.0,
          children: IterableExtension<MapEntry<String, double>>(vm.categoryRatio.entries).mapIndexed((index, entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: vm.getCategoryColor(index),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key} (${((entry.value / vm.categoryRatio.values.fold(0.0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFAAD0F8);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector( // 바깥 탭 시 알림 팝업 닫기
        behavior: HitTestBehavior.translucent,
        onTap: _closeNotificationPopup,
        child: Scaffold(
          backgroundColor: backgroundColor,
          drawer: DoctorDrawer(baseUrl: widget.baseUrl),
          appBar: AppBar(
            title: Consumer<DoctorDashboardViewModel>(
              builder: (_, vm, __) => Text(
                '${vm.doctorName} 대시보드',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
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
          // body를 Stack으로 감싸 팝업 오버레이를 상단에 띄움
          body: Stack(
            children: [
              // 본문
              SafeArea(
                child: kIsWeb
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _buildScrollableBody(context),
                        ),
                      )
                    : _buildScrollableBody(context),
              ),

              // 알림 팝업 — 더 위로 붙도록 수정 (SafeArea + Align topRight)
              if (_isNotificationPopupVisible)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
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
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 본문을 메서드로 분리 (웹/모바일 공통 사용)
  Widget _buildScrollableBody(BuildContext context) {
    return Consumer<DoctorDashboardViewModel>(
      builder: (context, vm, child) {
        return RefreshIndicator(
          onRefresh: () => vm.loadDashboardData(widget.baseUrl),
          color: Colors.white,
          backgroundColor: Colors.blueAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${vm.doctorName}님',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildSummaryCards(vm),
                const SizedBox(height: 24),
                Text(
                  '최근 7일 신청 건수',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  height: 200,
                  child: const _LineChartWidget(),
                ),
                const SizedBox(height: 24),
                Text(
                  '진료 카테고리 비율',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  height: 200,
                  child: const _PieChartWidget(),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _buildCategoryLegend(vm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(DoctorDashboardViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _SummaryCard(
            title: '오늘의 요청\n',
            count: vm.requestsToday,
            icon: Icons.request_page,
            color: Colors.blue.shade700,
            tabFilter: 'ALL',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '읽지 않은 \n알림',
            count: vm.unreadNotifications,
            icon: Icons.notifications_active,
            color: Colors.orange.shade700,
            tabFilter: '진단 대기',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '오늘의 응답\n',
            count: vm.answeredToday,
            icon: Icons.done_all,
            color: Colors.green.shade700,
            tabFilter: '진단 완료',
          ),
        ),
      ],
    );
  }
}

// -------------------------
// Summary Card Widget
// -------------------------
class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String tabFilter;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.tabFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabIndexMap = {
      'ALL': 0,
      '진단 대기': 1,
      '진단 완료': 2,
    };

    return InkWell(
      onTap: () {
        final initialTab = tabIndexMap[tabFilter] ?? 0;
        context.push('/d_telemedicine_application', extra: {'initialTab': initialTab});
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// Line Chart Widget
// -------------------------
class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    if (vm.recent7DaysCounts.isEmpty) {
      return const Center(child: Text("데이터 없음", style: TextStyle(color: Colors.black87)));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: vm.recent7DaysCounts
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            color: Colors.blueAccent,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: true),
          )
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final labels = ['6일전','5일전','4일전','3일전','2일전','어제','오늘'];
                if (value.toInt() < 0 || value.toInt() >= labels.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Transform.rotate(
                    angle: -0.785,
                    child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: (vm.recent7DaysCounts.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
      ),
    );
  }
}

// -------------------------
// Pie Chart Widget
// -------------------------
class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    final List<Color> pieChartColors = [
      Colors.lightBlue.shade300,
      Colors.orange.shade300,
      Colors.lightGreen.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
    ];

    return PieChart(
      PieChartData(
        sections: vm.pieChartSections.mapIndexed((index, section) {
          final color = pieChartColors[index % pieChartColors.length];
          return section.copyWith(
            color: color,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 4,
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
