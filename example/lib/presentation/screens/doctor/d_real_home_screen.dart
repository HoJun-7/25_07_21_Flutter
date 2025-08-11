// C:\Users\302-15\Desktop\25_07_21_Flutter-2\example\lib\presentation\screens\doctor\d_real_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFAAD0F8);

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
                    const SizedBox(height: 24),
                    _buildTodaysSchedule(vm),
                    const SizedBox(height: 24),
                    _buildRecentRequests(vm),
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

  // ✅ 수정된 오늘의 진료 스케줄 섹션
  Widget _buildTodaysSchedule(DoctorDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 진료 스케줄',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            // ✅ 진료 캘린더 화면으로 이동하는 코드
            context.push('/d_schedule');
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, size: 36, color: Colors.purple.shade700),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vm.todaysScheduleCount}건의 스케줄이 예정되어 있습니다.',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '클릭하여 상세 스케줄을 확인하세요.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // 최근 5건의 진료 요청 섹션
  Widget _buildRecentRequests(DoctorDashboardViewModel vm) {
    final dummyRequests = [
      {'patient': '김철수', 'category': '치아 교정 상담', 'time': '10:30 AM'},
      {'patient': '박영희', 'category': '잇몸 치료 문의', 'time': '11:15 AM'},
      {'patient': '이민지', 'category': '충치 진단', 'time': '02:00 PM'},
      {'patient': '최현우', 'category': '임플란트 문의', 'time': '03:45 PM'},
      {'patient': '정다희', 'category': '스케일링 예약', 'time': '04:20 PM'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 5건의 진료 요청',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dummyRequests.length,
            itemBuilder: (context, index) {
              final request = dummyRequests[index];
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.grey),
                    title: Text('${request['patient']} - ${request['category']}'),
                    subtitle: Text('요청 시간: ${request['time']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: 해당 진료 요청 상세 화면으로 이동
                      // context.push('/d_request_detail', extra: request);
                    },
                  ),
                  if (index < dummyRequests.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------
// Summary Card Widget (기존 코드와 동일)
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
// Line Chart Widget (기존 코드와 동일)
// -------------------------
class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);
    final maxY = vm.lineData.isNotEmpty ? vm.lineData.map((e) => e.y).reduce((a, b) => a > b ? a : b) : 1;

    return LineChart(
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
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Transform.rotate(
                    angle: -0.785,
                    child: Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => const FlLine(
            color: Colors.grey,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY + (maxY * 0.1),
      ),
    );
  }
}