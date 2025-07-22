import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

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

class _DRealHomeScreenState extends State<DRealHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorDashboardViewModel>().loadDashboardData(widget.baseUrl);
    });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 범례 항목 내부의 정렬은 시작점에 유지
      children: vm.categoryRatio.entries.mapIndexed((index, entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Row의 크기를 내용물에 맞춤
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: vm.getCategoryColor(index), // ViewModel에서 색상 가져오기
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key} (${((entry.value / vm.categoryRatio.values.fold(0.0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        drawer: DoctorDrawer(baseUrl: widget.baseUrl),
        appBar: AppBar(
          title: Consumer<DoctorDashboardViewModel>(
            builder: (_, vm, __) => Text('${vm.doctorName} 대시보드'),
          ),
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
                  ),
                  if (vm.unreadNotifications > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
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
        body: Consumer<DoctorDashboardViewModel>(
          builder: (context, vm, child) {
            return RefreshIndicator(
              onRefresh: () => vm.loadDashboardData(widget.baseUrl),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 전체 컬럼은 시작점 정렬 유지
                  children: [
                    Text(
                      '안녕하세요, ${vm.doctorName}님',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(vm),
                    const SizedBox(height: 24),
                    Text(
                      '최근 7일 신청 건수',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 200, child: _LineChartWidget()),
                    const SizedBox(height: 24),
                    Text(
                      '진료 카테고리 비율',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 200, child: _PieChartWidget()),
                    const SizedBox(height: 16), // 파이 차트와 범례 사이 간격
                    // 범례를 Center 위젯으로 감싸서 가운데 정렬
                    Center( // <--- 이 부분 추가
                      child: _buildCategoryLegend(vm),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DoctorDashboardViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SummaryCard(
          title: '오늘의 요청',
          count: vm.requestsToday,
          icon: Icons.request_page,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: '오늘의 응답',
          count: vm.answeredToday,
          icon: Icons.done_all,
          color: Colors.green,
        ),
        _SummaryCard(
          title: '읽지 않은 알림',
          count: vm.unreadNotifications,
          icon: Icons.notifications_active,
          color: Colors.red,
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

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 3,
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
                style: const TextStyle(fontSize: 14),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          lineBarsData: vm.chartData,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final labels = ['6일전', '5일전', '4일전', '3일전', '2일전', '어제', '오늘'];
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                  // 텍스트를 회전시켜 겹침 방지
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0, // 라벨과 차트 사이 간격
                    child: Transform.rotate(
                      angle: -0.785, // 약 -45도 (radians)
                      child: Text(
                        labels[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 2),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 20,
        ),
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

    return Padding(
      padding: const EdgeInsets.all(8),
      child: PieChart(
        PieChartData(
          sections: vm.pieChartSections,
          centerSpaceRadius: 40,
          sectionsSpace: 4,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}