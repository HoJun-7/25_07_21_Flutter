import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // mapIndexed 사용을 위해 추가

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

  // 범례를 그리는 위젯 (현재 진료 카테고리 비율 삭제하면서 _buildCategoryLegend는 미사용 상태)

  @override
  Widget build(BuildContext context) {
    // 요청하신 배경색 고정
    const Color backgroundColor = Color(0xFFAAD0F8);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor, // ✅ 배경 색상 고정 적용
        drawer: DoctorDrawer(baseUrl: widget.baseUrl),
        appBar: AppBar(
          title: Consumer<DoctorDashboardViewModel>(
            builder: (_, vm, __) => Text(
              '${vm.doctorName} 대시보드',
              style: const TextStyle(color: Colors.white), // 앱바 타이틀은 흰색 유지 (배경 대비)
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white), // 햄버거 메뉴 아이콘은 흰색 유지 (배경 대비)
          backgroundColor: Colors.transparent, // 앱바 배경 투명
          elevation: 0, // 앱바 그림자 제거
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
                    color: Colors.white, // 알림 아이콘은 흰색 유지 (배경 대비)
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
        body: Consumer<DoctorDashboardViewModel>(
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
                    // 진료 카테고리 비율 관련 부분 삭제됨
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
        Expanded(
          child: _SummaryCard(
            title: '오늘의 요청\n',
            count: vm.requestsToday,
            icon: Icons.request_page,
            color: Colors.blue.shade700,
            tabFilter: 'ALL', // ✅
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '읽지 않은 \n알림',
            count: vm.unreadNotifications,
            icon: Icons.notifications_active,
            color: Colors.orange.shade700,
            tabFilter: '진단 대기', // ✅
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '오늘의 응답\n',
            count: vm.answeredToday,
            icon: Icons.done_all,
            color: Colors.green.shade700,
            tabFilter: '진단 완료', // ✅
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
    // ✅ 탭 필터 → 인덱스로 매핑
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
    return LineChart(
      LineChartData(
        lineBarsData: vm.chartData.map((lineBarData) {
          // 라인 색상 및 두께 조정 (예시)
          return lineBarData.copyWith(
            color: Colors.blueAccent, // 라인 차트 색상 변경
            barWidth: 3,
            isCurved: true, // 곡선 형태로 변경
            dotData: const FlDotData(show: true), // 점 표시
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final labels = ['6일전', '5일전', '4일전', '3일전', '2일전', '어제', '오늘'];
                final index = value.toInt();
                if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Transform.rotate(
                    angle: -0.785,
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10, color: Colors.black87), // 라벨 색상 변경 (이미 검은색 계열)
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.black87), // 라벨 색상 변경 (이미 검은색 계열)
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // 상단 타이틀 제거
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // 우측 타이틀 제거
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Colors.grey, // 그리드 라인 색상
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => const FlLine(
            color: Colors.grey, // 그리드 라인 색상
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1), // 테두리 색상
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 20,
      ),
    );
  }
}
