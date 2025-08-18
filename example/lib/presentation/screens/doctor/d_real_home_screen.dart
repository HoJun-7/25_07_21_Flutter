import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';

const double kImageRadius = 10; // 카드/전체화면 공통 모서리 반경

class DRealHomeScreen extends StatefulWidget {
  final String baseUrl;
  const DRealHomeScreen({super.key, required this.baseUrl});

  @override
  State<DRealHomeScreen> createState() => _DRealHomeScreenState();
}

class _DRealHomeScreenState extends State<DRealHomeScreen> {
  // 캘린더 상태
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 예시 이벤트
  final Map<DateTime, List<dynamic>> _events = {
    DateTime.utc(2025, 8, 10): ['Event A', 'Event B'],
    DateTime.utc(2025, 8, 12): ['Event C'],
    DateTime.utc(2025, 8, 15): ['Event D', 'Event E', 'Event F'],
    DateTime.utc(2025, 8, 20): ['Event G'],
  };

  List<dynamic> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      final vm = context.read<DoctorDashboardViewModel>();
      vm.loadHourlyStats(widget.baseUrl, day: selectedDay);
      vm.loadImagesByDate(widget.baseUrl, day: selectedDay, limit: 9);
      vm.loadVideoTypeRatio(widget.baseUrl, day: selectedDay);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<DoctorDashboardViewModel>();
      vm.loadDashboardData(widget.baseUrl);
      vm.loadRecent7DaysData(widget.baseUrl);
      vm.loadAgeDistributionData(widget.baseUrl);
      vm.loadHourlyStats(widget.baseUrl, day: _focusedDay);
      vm.loadImagesByDate(widget.baseUrl, day: _focusedDay, limit: 9);
      vm.loadVideoTypeRatio(widget.baseUrl, day: _focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DoctorDrawer(baseUrl: widget.baseUrl),
      body: Row(
        children: [
          _buildSideMenu(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _buildChartsArea()),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _buildAlertsPanel()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== 좌측 메뉴 =====================
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
          _sideMenuItem(Icons.dashboard, "통합 대시보드", () {}),
          _sideMenuItem(Icons.health_and_safety, "환자 모니터링", () => context.go('/patients')),
          _sideMenuItem(Icons.history, "진료 현황", () => context.go('/d_dashboard')),
          _sideMenuItem(Icons.notifications, "알림", () {}),
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

  // ===================== 상단 상태바 =====================
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Consumer<DoctorDashboardViewModel>(
        builder: (context, vm, _) {
          return Row(
            children: [
              // 좌측: 3지표 카드
              Expanded(
                flex: 2,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildClickableNumber(
                        "오늘의 진료",
                        vm.requestsToday,
                        Colors.white,
                        () => context.push('/d_telemedicine_application', extra: {'initialTab': 0}),
                      ),
                      _buildClickableNumber(
                        "진단 대기",
                        vm.unreadNotifications,
                        Colors.white,
                        () => context.push('/d_telemedicine_application', extra: {'initialTab': 1}),
                      ),
                      _buildClickableNumber(
                        "진단 완료",
                        vm.answeredToday,
                        Colors.white,
                        () => context.push('/d_telemedicine_application', extra: {'initialTab': 2}),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 가운데 상태 카드 (샘플)
              Expanded(
                flex: 3,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconStat(Icons.cloud, "단체", 13680, Colors.blue),
                      _buildIconStat(Icons.check_circle, "정상", 10470, Colors.green),
                      _buildIconStat(
                        Icons.warning,
                        "위험",
                        vm.unreadNotifications.clamp(0, 9999).toInt(),
                        Colors.red,
                      ),
                      _buildIconStat(Icons.remove_circle_outline, "의사 수", 3208, Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 우측 날씨 카드 (샘플)
              Container(
                height: 80,
                width: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("2024. 5. 17  AM 10:23", style: TextStyle(color: Colors.white, fontSize: 12)),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("서울시 서대문구", style: TextStyle(color: Colors.white, fontSize: 12)),
                            Text("미세먼지 보통", style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                        Text("20°C",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClickableNumber(String label, int value, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$value", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildIconStat(IconData icon, String label, int value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text("$value", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }

  // ===================== 중앙 차트 영역 =====================
  Widget _buildChartsArea() {
    return Column(
      children: [
        // ── 상단: (왼) 최근7일 + 시간대별  (오) 사진(3분할 오버레이)
        Expanded(
          child: Row(
            children: [
              Expanded(child: _combinedLineChartsCard()),
              const SizedBox(width: 16),
              Expanded(child: _chartCard("사진", Colors.orange, const _ImageCard())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── 하단: (왼) 성별·연령대  (오) 영상 타입 비율
        Expanded(
          child: Row(
            children: [
              Expanded(child: _chartCard("성별 · 연령대", Colors.green, const _DemographicsSplitPanel())),
              const SizedBox(width: 16),
              Expanded(child: _chartCard("영상 타입 비율", Colors.purple, const _VideoTypePieChart())),
            ],
          ),
        ),
      ],
    );
  }

  // ‘한 칸’에 위/아래 그래프를 넣은 카드
  Widget _combinedLineChartsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SubChartTitle(text: "최근 7일 신청 건수", color: Color(0xFFEB5757)),
          SizedBox(height: 4),
          Expanded(flex: 11, child: _Last7DaysLineChartFancy()),
          SizedBox(height: 10),
          _SubChartTitle(text: "시간대별 건수", color: Color(0xFF2F80ED)),
          SizedBox(height: 4),
          Expanded(flex: 9, child: _HourlyLineChartFancy()),
        ],
      ),
    );
  }

  Widget _chartCard(String title, Color color, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: chart),
        ],
      ),
    );
  }

  // ===================== 우측 알림 패널 + 캘린더 =====================
  Widget _buildAlertsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("실시간 알림", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text("위험 알림 ${index + 1}"),
                  subtitle: const Text("상세 내용 표시"),
                  dense: true,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      eventLoader: _getEventsForDay,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blue),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blue),
      ),
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), shape: BoxShape.circle),
        selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        markerDecoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

// 미니 섹션 타이틀
class _SubChartTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SubChartTitle({Key? key, required this.text, required this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// ===================== 유틸: 날짜 라벨 포맷 =====================
String _weekdayKr(int w) => const ['일', '월', '화', '수', '목', '금', '토'][w % 7];

String _prettyDateLabel({
  required int index,
  required List<String> labels,        // 보통 'MM-DD'
  required List<String>? fulls,        // 가능하면 'YYYY-MM-DD'
}) {
  DateTime? dt;
  if (fulls != null && index >= 0 && index < fulls.length) {
    final s = fulls[index];
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) dt = DateTime.tryParse(s);
  }
  if (dt == null && index >= 0 && index < labels.length) {
    final s = labels[index];
    if (RegExp(r'^\d{2}-\d{2}$').hasMatch(s)) {
      final now = DateTime.now();
      dt = DateTime.tryParse('${now.year}-$s');
    }
  }
  if (dt == null) return '${labels[index]}';
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final w = _weekdayKr(dt.weekday % 7);
  return '$mm/$dd ($w)';
}

/// ===================== 최근 7일 라인차트 =====================
class _Last7DaysLineChartFancy extends StatelessWidget {
  const _Last7DaysLineChartFancy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    final counts = vm.recent7DaysCounts;
    final labels = vm.recent7DaysLabels;

    if (counts.isEmpty || labels.length != counts.length) {
      return const Center(child: Text("데이터 없음", style: TextStyle(color: Colors.black87)));
    }

    List<String>? fullDates;
    try {
      final dyn = vm as dynamic;
      if (dyn.recent7DaysDates is List) {
        fullDates = List<String>.from(dyn.recent7DaysDates);
      } else if (dyn.recent7DaysFullDates is List) {
        fullDates = List<String>.from(dyn.recent7DaysFullDates);
      }
    } catch (_) {}

    final maxY = counts.reduce((a, b) => a > b ? a : b).toDouble();
    final avgY = counts.reduce((a, b) => a + b) / counts.length;
    final maxIndex = counts.indexOf(maxY.toInt());

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (counts.length - 1).toDouble(),
          minY: 0,
          maxY: (maxY + 2).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY <= 5 ? 1 : (maxY / 4).ceilToDouble()),
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();

                  final text = _prettyDateLabel(index: i, labels: labels, fulls: fullDates);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FittedBox(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: avgY,
              color: const Color(0xFF9B51E0).withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [6, 6],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9B51E0), fontWeight: FontWeight.w700),
                labelResolver: (_) => '평균 ${avgY.toStringAsFixed(1)}',
              ),
            ),
          ]),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.78),
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.toInt();
                final label = _prettyDateLabel(index: i, labels: labels, fulls: fullDates);
                return LineTooltipItem(
                  '$label\n${s.y.toInt()}건',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3.2,
              gradient: const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFF2F80ED).withOpacity(0.22), const Color(0xFF56CCF2).withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final highlight = index == maxIndex;
                  return FlDotCirclePainter(
                    radius: highlight ? 4.4 : 3.0,
                    color: Colors.white,
                    strokeWidth: highlight ? 2.6 : 2.2,
                    strokeColor: const Color(0xFF2F80ED),
                  );
                },
              ),
              spots: [for (int i = 0; i < counts.length; i++) FlSpot(i.toDouble(), counts[i].toDouble())],
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== 시간대별 라인차트 (23시 라벨 보장) =====================
class _HourlyLineChartFancy extends StatelessWidget {
  const _HourlyLineChartFancy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    List<int> counts = [];
    List<String> labels = [];
    try {
      final dvm = vm as dynamic;
      if (dvm.hourlyCounts is List) counts = List<int>.from(dvm.hourlyCounts);
      if (dvm.hourlyLabels is List) labels = List<String>.from(dvm.hourlyLabels);
    } catch (_) {}

    if (counts.isEmpty || labels.length != counts.length || counts.every((e) => e == 0)) {
      return const Center(child: Text("데이터 없음", style: TextStyle(color: Colors.black87)));
    }

    final maxY = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (counts.length - 1).toDouble(),
          minY: 0,
          maxY: (maxY + 2).toDouble(),
          rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: [
            VerticalRangeAnnotation(x1: 9, x2: 18, color: const Color(0xFF2F80ED).withOpacity(0.06)),
          ]),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY <= 5 ? 1 : (maxY / 4).ceilToDouble()),
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [4, 4]),
            getDrawingVerticalLine: (v) => FlLine(color: Colors.black.withOpacity(0.05), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();

                  // 3시간 간격 + 마지막(23시) 강제 표시
                  final isTick = (i % 3 == 0) || (i == labels.length - 1);
                  if (!isTick) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FittedBox(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${labels[i]}시',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.78),
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.x.toInt();
                final hour = (i >= 0 && i < labels.length) ? labels[i] : i.toString();
                return LineTooltipItem(
                  '$hour시\n${s.y.toInt()}건',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3.2,
              gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [const Color(0xFF2575FC).withOpacity(0.20), const Color(0xFF6A11CB).withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 3.0, color: Colors.white, strokeWidth: 2.0, strokeColor: const Color(0xFF6A11CB)),
              ),
              spots: [for (int i = 0; i < counts.length; i++) FlSpot(i.toDouble(), counts[i].toDouble())],
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== 사진: 3분할 투명 오버레이 (← 이전 / [중앙 탭=전체화면] / → 다음) =====================
class _ImageCard extends StatefulWidget {
  const _ImageCard({Key? key}) : super(key: key);

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  int _index = 0;

  void _showFullscreen(BuildContext context, String url) {
    // 전체 화면: 검은 반투명 배경 + 라운드 박스 형태(공통 반경)로 최대 크기(4:3) 표시
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fullscreen',
      barrierColor: Colors.black.withOpacity(0.65),
      pageBuilder: (_, __, ___) {
        final size = MediaQuery.of(context).size;
        // 4:3 비율로 화면 안에 최대 크기 계산
        final w = size.width;
        final h = size.height;
        final maxWidthByHeight = h * (4 / 3);
        final boxWidth = w < maxWidthByHeight ? w : maxWidthByHeight;
        final boxHeight = boxWidth * (3 / 4);

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kImageRadius),
            child: Container(
              width: boxWidth,
              height: boxHeight,
              color: Colors.black, // 이미지 로딩 전 배경
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.cover, // 라운드 상자 안을 꽉 채우기
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: ScaleTransition(scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic), child: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    List<String> urls = [];
    try {
      final dvm = vm as dynamic;
      if (dvm.imageUrls is List<String>) {
        urls = dvm.imageUrls;
      } else if (dvm.imageUrls is List) {
        urls = List<String>.from(dvm.imageUrls);
      }
    } catch (_) {}

    if (urls.isEmpty) {
      urls = ['https://picsum.photos/seed/dash0/1200/800'];
    }
    _index = _index.clamp(0, urls.length - 1);

    final url = urls[_index];

    void prev() => setState(() => _index = (_index - 1 + urls.length) % urls.length);
    void next() => setState(() => _index = (_index + 1) % urls.length);
    void full() => _showFullscreen(context, url);

    return ClipRRect(
      borderRadius: BorderRadius.circular(kImageRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 실제 이미지
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          ),

          // 투명 오버레이 3분할 (아이콘 제거, 기능만)
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverlayTapZone(
                  onTap: prev,
                  child: const SizedBox.shrink(), // ← 아이콘 제거
                  align: Alignment.centerLeft,
                  flex: 1,
                ),
                _OverlayTapZone(
                  onTap: full,
                  child: const SizedBox.shrink(), // ● 아이콘 제거 (기능만 유지)
                  align: Alignment.center,
                  flex: 2, // 가운데는 넓게
                ),
                _OverlayTapZone(
                  onTap: next,
                  child: const SizedBox.shrink(), // → 아이콘 제거
                  align: Alignment.centerRight,
                  flex: 1,
                ),
              ],
            ),
          ),

          // 하단 인덱스 표시(선택 사항)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_index + 1} / ${urls.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayTapZone extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Alignment align;
  final int flex;

  const _OverlayTapZone({
    Key? key,
    required this.onTap,
    required this.child,
    required this.align,
    this.flex = 1,
  }) : super(key: key);

  @override
  State<_OverlayTapZone> createState() => _OverlayTapZoneState();
}

class _OverlayTapZoneState extends State<_OverlayTapZone> {
  double _opacity = 0.10;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: MouseRegion(
        onEnter: (_) => setState(() => _opacity = 0.16),
        onExit: (_) => setState(() => _opacity = 0.10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            alignment: widget.align,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.black.withOpacity(_opacity), // 투명 레이어
            child: widget.child, // 지금은 비어 있음(아이콘 제거)
          ),
        ),
      ),
    );
  }
}

/// ===================== 성별·연령 분할 패널 =====================
class _DemographicsSplitPanel extends StatelessWidget {
  const _DemographicsSplitPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    final int male = (vm.maleCount >= 0) ? vm.maleCount : 0;
    final int female = (vm.femaleCount >= 0) ? vm.femaleCount : 0;
    final int totalMF = (male + female);

    final double malePct = totalMF == 0 ? 0 : (male / totalMF * 100.0);
    final double femalePct = totalMF == 0 ? 0 : (female / totalMF * 100.0);

    final Map<String, int> ageData = vm.ageDistributionData;

    return Row(
      children: [
        Expanded(child: _GenderRatioCard(malePercent: malePct, femalePercent: femalePct)),
        const SizedBox(width: 16),
        Expanded(child: _AgeDistributionMiniBarChart(data: ageData)),
      ],
    );
  }
}

class _GenderRatioCard extends StatelessWidget {
  final double malePercent;
  final double femalePercent;

  const _GenderRatioCard({
    Key? key,
    required this.malePercent,
    required this.femalePercent,
  }) : super(key: key);

  String _fmt(double v) => '${v.round()}%';

  @override
  Widget build(BuildContext context) {
    const maleColor = Color(0xFF15B8B3);
    const femaleColor = Color(0xFFE74C3C);

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 260;
        final iconSize = compact ? 48.0 : 60.0;
        final percentSize = compact ? 18.0 : 20.0;
        final chipTextSize = compact ? 11.0 : 12.0;

        Widget pillar({
          required Color color,
          required IconData icon,
          required String label,
          required String percentText,
        }) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(percentText,
                  style: TextStyle(
                    fontSize: percentSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
              const SizedBox(height: 6),
              Icon(icon, size: iconSize, color: color.withOpacity(0.85)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: TextStyle(
                      fontSize: chipTextSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    )),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            pillar(
              color: maleColor,
              icon: Icons.male,
              label: '남',
              percentText: _fmt(malePercent),
            ),
            pillar(
              color: femaleColor,
              icon: Icons.female,
              label: '여',
              percentText: _fmt(femalePercent),
            ),
          ],
        );
      },
    );
  }
}

class _AgeDistributionMiniBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _AgeDistributionMiniBarChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("데이터 없음", style: TextStyle(color: Colors.black87)));
    }

    final labels = data.keys.toList();
    final values = data.values.toList();
    double maxY = values.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxY < 5) maxY = 5;
    maxY += 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: FittedBox(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(labels[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(labels.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  color: Colors.deepPurple,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// ===================== 영상 타입 비율 (파이/도넛 차트) =====================
class _VideoTypePieChart extends StatelessWidget {
  const _VideoTypePieChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    Map<String, num> data = {};
    try {
      final dvm = vm as dynamic;
      if (dvm.videoTypeRatio is Map) {
        final m = Map<String, dynamic>.from(dvm.videoTypeRatio as Map);
        data = m.map((k, v) => MapEntry(k, (v as num)));
      }
    } catch (_) {}

    if (data.isEmpty) {
      return const Center(child: Text('데이터 없음'));
    }

    final total = data.values.fold<num>(0, (p, c) => p + c).toDouble();
    if (total <= 0) {
      return const Center(child: Text('데이터 없음'));
    }

    final keys = data.keys.toList();
    final colors = <Color>[const Color(0xFF2F80ED), const Color(0xFFF2994A)];

    final sections = List.generate(keys.length, (i) {
      final value = data[keys[i]]!.toDouble();
      return PieChartSectionData(
        value: value,
        title: '${((value / total) * 100).round()}%',
        radius: 70,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        color: colors[i % colors.length],
      );
    });

    final chart = Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 44,
            sections: sections,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: const Text('총', style: TextStyle(fontSize: 11, color: Colors.black87)),
            ),
            const SizedBox(height: 6),
            Text(
              '${total.toInt()}건',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
          ],
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey('video-${keys.map((k) => '$k:${data[k]}').join(",")}'),
              child: chart,
            ),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate(keys.length, (i) {
            final k = keys[i];
            final v = data[k]!.toDouble();
            final pct = (v / total * 100).toStringAsFixed(0);
            return _LegendDot(color: colors[i % colors.length], label: '$k ${v.toInt()}건 ($pct%)');
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({Key? key, required this.color, required this.label}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
