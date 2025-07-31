import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userVm = context.read<UserInfoViewModel>();
      final user = userVm.user;
      final dashboardVm = context.read<DoctorDashboardViewModel>();

      if (user != null) {
        await dashboardVm.loadDashboardData(widget.baseUrl, user.registerId);

        // 👇 이름 불러오기 분리
        final name = await dashboardVm.loadDoctorName(widget.baseUrl, user.registerId);
        dashboardVm.doctorName = name;
        userVm.updateUserName(name);
        dashboardVm.notifyListeners();
      }
    });
  }

  Future<bool> _onWillPop() async {
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '${vm.unreadNotifications}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
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
              onRefresh: () {
                final user = context.read<UserInfoViewModel>().user;
                if (user != null) {
                  return vm.loadDashboardData(widget.baseUrl, user.registerId);
                }
                return Future.value(); // fallback
              },
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
                    const SizedBox(height: 24),

                    // 기존 요약 카드 Row
                    _buildSummaryCards(vm),

                    const SizedBox(height: 24),

                    // 최근 7일 신청 건수 차트
                    Text(
                      '최근 7일 신청 건수',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
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

                    // 5. 공지사항 / 병원 전달사항 알림 박스 (Row로 감싸서 너비 조정)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildAnnouncementBox(vm),
                        ),
                        const SizedBox(width: 16), // 공지사항과 할일 리스트 사이 간격
                        Expanded(
                          child: _buildTodoList(vm),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24), // 마지막 위젯과의 간격
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
            title: '전체',
            count: vm.requestsToday,
            icon: Icons.list_alt,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '답변전',
            count: vm.pendingToday,
            icon: Icons.pending_actions,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '답변완료',
            count: vm.completedToday,
            icon: Icons.check_circle,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '취소',
            count: vm.canceledToday,
            icon: Icons.cancel,
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementBox(DoctorDashboardViewModel vm) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공지사항 / 병원 전달사항',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...vm.announcements.map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(DoctorDashboardViewModel vm) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '간단한 메모 / 할일 리스트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...vm.todoList.map(
              (task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Card(
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
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);
    return LineChart(
      LineChartData(
        lineBarsData: vm.chartData.map((lineBarData) {
          return lineBarData.copyWith(
            color: Colors.blueAccent,
            barWidth: 3,
            isCurved: true,
            dotData: const FlDotData(show: true),
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
                    angle: -0.785, // 텍스트 회전
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
              interval: 2,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey, width: 1)),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 20,
      ),
    );
  }
}
