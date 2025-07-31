import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // mapIndexed 사용을 위해 추가
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb import

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
                          color: Colors.redAccent, // 알림 숫자 배경색 (좀 더 쨍한 빨강)
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${vm.unreadNotifications}',
                          style: const TextStyle(
                            color: Colors.white, // 알림 숫자는 흰색 유지 (배경 대비)
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
        body: kIsWeb ? _buildWebLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Consumer<DoctorDashboardViewModel>(
      builder: (context, vm, child) {
        return RefreshIndicator(
          onRefresh: () => vm.loadDashboardData(widget.baseUrl),
          color: Colors.white, // 새로고침 아이콘 색상 변경 (배경에 대비되도록)
          backgroundColor: Colors.blueAccent, // 새로고침 배경색 변경
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${vm.doctorName}님',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white, // 환영 메시지 텍스트는 흰색 유지 (배경 대비)
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 16),
                _buildSummaryCards(vm),
                const SizedBox(height: 24),
                Text(
                  '최근 7일 신청 건수',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white, // 섹션 제목 텍스트는 흰색 유지 (배경 대비)
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 16), // 간격 조정
                // 라인 차트 컨테이너 배경 추가 및 패딩 조정
                Container(
                  padding: const EdgeInsets.all(8), // 내부 패딩
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // 차트 컨테이너 배경색
                    borderRadius: BorderRadius.circular(12), // 둥근 모서리
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
                            color: Colors.white, // 섹션 제목 텍스트는 흰색 유지 (배경 대비)
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 16), // 간격 조정
                // 파이 차트 컨테이너 배경 추가 및 패딩 조정
                Container(
                  padding: const EdgeInsets.all(8), // 내부 패딩
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // 차트 컨테이너 배경색
                    borderRadius: BorderRadius.circular(12), // 둥근 모서리
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
                const SizedBox(height: 16), // 파이 차트와 범례 사이 간격
                Center(
                  child: _buildCategoryLegend(vm), // 범례 위젯 호출
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        constraints: const BoxConstraints(maxWidth: 1200), // 웹 콘텐츠의 최대 너비
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vm.doctorName}님의 웹 대시보드',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                '요약 정보',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // 웹에서는 Summary Cards를 반응형으로 배치할 수 있습니다.
              // 예를 들어, GridView 또는 Wrap을 사용합니다.
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // GridView가 SingleChildScrollView 내부에 있으므로 스크롤 비활성화
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2, // 화면 너비에 따라 열 개수 조정
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2, // 카드 비율 조정
                children: [
                  _SummaryCard(
                    title: '전체',
                    count: vm.requestsToday,
                    icon: Icons.list_alt,
                    color: Colors.blue.shade700,
                  ),
                  _SummaryCard(
                    title: '답변전',
                    count: vm.pendingToday,
                    icon: Icons.pending_actions,
                    color: Colors.orange.shade700,
                  ),
                  _SummaryCard(
                    title: '답변완료',
                    count: vm.completedToday,
                    icon: Icons.check_circle,
                    color: Colors.green.shade700,
                  ),
                  _SummaryCard(
                    title: '취소',
                    count: vm.canceledToday,
                    icon: Icons.cancel,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // GridView가 SingleChildScrollView 내부에 있으므로 스크롤 비활성화
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1, // 화면 너비에 따라 열 개수 조정
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 2.0, // 차트 카드 비율 조정
                children: [
                  _buildWebChartCard(
                    context,
                    title: '최근 7일 신청 건수 (웹)',
                    chartWidget: const _LineChartWidget(),
                  ),
                  _buildWebChartCard(
                    context,
                    title: '진료 카테고리 비율 (웹)',
                    chartWidget: Column(
                      children: [
                        Expanded(child: const _PieChartWidget()),
                        const SizedBox(height: 16),
                        _buildCategoryLegend(vm),
                      ],
                    ),
                  ),
                ],
              ),
              // 여기에 더 많은 웹 특정 위젯 또는 레이아웃을 추가할 수 있습니다.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebChartCard(BuildContext context, {required String title, required Widget chartWidget}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(child: chartWidget),
          ],
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 카드 모서리 둥글게
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
                color: color, // 아이콘 색상과 동일하게 유지 (이미 검은색 계열)
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black87), // 텍스트 색상 명확히 (이미 검은색 계열)
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
            ),
          ],
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

/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';

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
            title: '오늘의 요청',
            count: vm.requestsToday,
            icon: Icons.request_page,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '읽지 않은 알림',
            count: vm.unreadNotifications,
            icon: Icons.notifications_active,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '오늘의 응답',
            count: vm.answeredToday,
            icon: Icons.done_all,
            color: Colors.green.shade700,
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
*/