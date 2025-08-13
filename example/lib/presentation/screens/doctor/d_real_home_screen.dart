import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';

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
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<DoctorDashboardViewModel>();
      await vm.loadDashboardData(widget.baseUrl);
      await vm.loadRecent7DaysData(widget.baseUrl);
    });

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

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFAAD0F8);

    // 웹 환경이거나 가로 모드일 때 Row 레이아웃을 사용
    final isDesktopOrLandscape = kIsWeb || MediaQuery.of(context).orientation == Orientation.landscape;

    return WillPopScope(
      onWillPop: _onWillPop,
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
            Consumer<DoctorDashboardViewModel>(
              builder: (_, vm, __) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // TODO: 알림 화면 이동 처리
                    },
                    tooltip: '알림',
                    color: Colors.white,
                  ),
                  if (vm.unreadNotifications > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${vm.unreadNotifications}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
        body: SafeArea(
          child: isDesktopOrLandscape
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  // 모바일/세로 모드 레이아웃
  Widget _buildMobileLayout(BuildContext context) {
    return _buildScrollableBody(context);
  }

  // 웹/가로 모드 레이아웃 (이미지 도면과 유사)
  Widget _buildDesktopLayout(BuildContext context) {
    return Consumer<DoctorDashboardViewModel>(
      builder: (context, vm, child) {
        return RefreshIndicator(
          onRefresh: () => vm.loadDashboardData(widget.baseUrl),
          color: Colors.white,
          backgroundColor: Colors.blueAccent,
          child: Row(
            children: [
              Expanded(
                flex: 1,
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
                      Container(
                        height: 200, // 그래프와 동일한 높이
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                        child: const Center(
                          child: Text(
                            '그래프',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
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
                    child: const Center(
                      child: Text(
                        '사진 / x-ray',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                // "그래프" 박스 추가
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: const Center(
                    child: Text(
                      '그래프',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // "사진 / x-ray" 박스 추가
                Container(
                  height: 300,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                  child: const Center(
                    child: Text(
                      '사진 / x-ray',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                  ),
                ),
                // ⬇⬇⬇ '진료 카테고리 비율' 관련 위젯 삭제 ⬇⬇⬇
                // ⬆⬆⬆ '진료 카테고리 비율' 관련 위젯 삭제 ⬆⬆⬆
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
        context.push('/d_telemedicine_application', extra: {
          'initialTab': initialTab,
        });
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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