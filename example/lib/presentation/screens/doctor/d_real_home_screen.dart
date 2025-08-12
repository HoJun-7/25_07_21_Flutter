import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // mapIndexed 사용을 위해 추가
import 'dart:async'; // ⬅ 추가

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

    // ⬅ 1분마다 자동 갱신 타이머 추가 (카드 + 그래프)
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        final vm = context.read<DoctorDashboardViewModel>();
        vm.loadDashboardData(widget.baseUrl);   // ✅ 카드 갱신
        vm.loadRecent7DaysData(widget.baseUrl); // ✅ 그래프 갱신
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel(); // ⬅ 타이머 해제
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final vm = context.read<DoctorDashboardViewModel>();
      vm.loadDashboardData(widget.baseUrl);   // ✅ 상단 카드 갱신
      vm.loadRecent7DaysData(widget.baseUrl); // ✅ 그래프 갱신
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
    // 범례를 흰색 네모 박스 안에 넣기 위해 Card 위젯 사용
    return Card(
      elevation: 4, // 그림자 효과
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 둥근 모서리
      margin: const EdgeInsets.symmetric(horizontal: 0), // 좌우 마진 제거 (Center 위젯이 처리)
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 내부 패딩
        child: Wrap( // Wrap을 사용하여 공간이 부족할 경우 다음 줄로 넘어가도록
          alignment: WrapAlignment.center, // 가운데 정렬
          spacing: 16.0, // 각 항목 간 가로 간격
          runSpacing: 8.0, // 각 줄 간 세로 간격
          children: IterableExtension<MapEntry<String, double>>(vm.categoryRatio.entries).mapIndexed((index, entry) {
            return Row(
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87, // 범례 텍스트 색상을 흰색 배경에 어울리게 변경 (이미 검은색 계열)
                        ),
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

// -------------------------
// Pie Chart Widget
// -------------------------
class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    // 파이 차트 섹션의 색상 정의 (화면 배경과 어울리는 파스텔톤)
    final List<Color> pieChartColors = [
      Colors.lightBlue.shade300, // 연한 파랑
      Colors.orange.shade300,    // 연한 주황
      Colors.lightGreen.shade300, // 연한 초록
      Colors.purple.shade300,    // 연한 보라
      Colors.teal.shade300,      // 연한 청록 (기타 카테고리)
    ];

    return PieChart(
      PieChartData(
        sections: vm.pieChartSections.mapIndexed((index, section) {
          // VM의 pieChartSections에는 이미 원본 데이터가 있으므로,
          // 여기서는 색상만 새로 정의된 pieChartColors에서 가져와 덮어씌웁니다.
          // 범위를 벗어나는 인덱스를 처리하기 위해 % 연산 사용.
          final color = pieChartColors[index % pieChartColors.length];
          return section.copyWith(
            color: color, // 파이 차트 색상 수정 적용
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white, // 파이 차트 섹션 내부 텍스트는 흰색 유지 (색상 대비)
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 4,
        borderData: FlBorderData(show: false),
        // 터치 동작 추가 (선택 효과) - 필요시 구현
        // pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
        //   // 터치 이벤트 처리 로직
        // }),
      ),
    );
  }
}