import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';

class DRealHomeScreen extends StatefulWidget {
  final String baseUrl;
  const DRealHomeScreen({super.key, required this.baseUrl});

  @override
  State<DRealHomeScreen> createState() => _DRealHomeScreenState();
}

class _DRealHomeScreenState extends State<DRealHomeScreen> {
  // 캘린더 상태 관리를 위한 변수 추가
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 가상의 이벤트 데이터
  Map<DateTime, List<dynamic>> _events = {
    DateTime.utc(2025, 8, 10): ['Event A', 'Event B'],
    DateTime.utc(2025, 8, 12): ['Event C'],
    DateTime.utc(2025, 8, 15): ['Event D', 'Event E', 'Event F'],
    DateTime.utc(2025, 8, 20): ['Event G'],
  };

  @override
  void initState() {
    super.initState();
    final vm = context.read<DoctorDashboardViewModel>();
    vm.loadDashboardData(widget.baseUrl);
    vm.loadRecent7DaysData(widget.baseUrl);
    vm.loadAgeDistributionData(widget.baseUrl);
    
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }
  
  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
  
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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

  // 좌측 메뉴
  Widget _buildSideMenu() {
    return Container(
      width: 220,
      color: const Color(0xFF2D9CDB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "The More·Care",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _sideMenuItem(Icons.dashboard, "통합 대시보드"),
          _sideMenuItem(Icons.health_and_safety, "환자 모니터링"),
          _sideMenuItem(Icons.history, "진료 이력"),
          _sideMenuItem(Icons.notifications, "알림"),
        ],
      ),
    );
  }

  Widget _sideMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }

  // 상단 상태바
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Consumer<DoctorDashboardViewModel>(
        builder: (context, vm, _) {
          return Row(
            children: [
              // 왼쪽 큰 카드 (등록 환자 / 전체 기기)
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
                        "오늘의 요청",
                        vm.requestsToday,
                        Colors.white,
                        () => context.go('/patients'),
                      ),
                      _buildClickableNumber(
                        "오늘의 응답",
                        3451,
                        Colors.white,
                        () => context.go('/devices'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 가운데 상태 카드
              Expanded(
                flex: 3,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconStat(Icons.cloud, "단체", 13680, Colors.blue),
                      _buildIconStat(Icons.check_circle, "정상", 10470, Colors.green),
                      _buildIconStat(Icons.warning, "위험", 2, Colors.red),
                      _buildIconStat(Icons.remove_circle_outline, "의사 수", 3208, Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 오른쪽 날씨 카드
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
                  children: [
                    Text(
                      "2024. 5. 17  AM 10:23",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "서울시 서대문구",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              "미세먼지 보통",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                        const Text(
                          "20°C",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
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
          Text(
            "$value",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
          ),
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
        Text(
          "$value",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  // 중앙 차트 영역
  Widget _buildChartsArea() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _chartCard("최근 7일 신청 건수", Colors.red, _buildLineChart())),
              const SizedBox(width: 16),
              Expanded(child: _chartCard("시간", Colors.blue, _buildLineChart())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _chartCard("사진", Colors.orange, _buildBarChart())),
              const SizedBox(width: 16),
              Expanded(child: _chartCard("연령대", Colors.green, _buildBarChart())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartCard(String title, Color color, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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

  // 라인 차트
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 4),
              FlSpot(2, 5),
              FlSpot(3, 7),
              FlSpot(4, 6),
              FlSpot(5, 8),
            ],
            isCurved: true,
            color: Colors.blueAccent,
            dotData: const FlDotData(show: true),
          )
        ],
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(show: false),
      ),
    );
  }

  // 바 차트
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.orange)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3, color: Colors.orange)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4, color: Colors.orange)]),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
  
  // 캘린더 위젯
  Widget _buildCalendar() {
    return TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
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
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // 오른쪽 알림 패널
  Widget _buildAlertsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
          // 여기에 캘린더를 추가합니다.
          const SizedBox(height: 16),
          _buildCalendar(),
        ],
      ),
    );
  }
}