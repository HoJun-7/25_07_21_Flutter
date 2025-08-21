import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
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

  /// 모바일 여부 (웹은 무조건 false로 둬서 웹 레이아웃 그대로 유지)
  bool _isMobile(BuildContext context) =>
      !kIsWeb && MediaQuery.of(context).size.width < 600;

  /// ✅ 웹에서만 콘텐츠 최소 (너비/높이) 보장: 작아지면 해당 축으로 스크롤 생성
  Widget _minSizeOnWeb(Widget child, {double minWidth = 1000, double minHeight = 720}) {
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final needsH = constraints.maxWidth < minWidth;
        final needsV = constraints.maxHeight < minHeight;

        final hCtrl = ScrollController();
        final vCtrl = ScrollController();

        Widget content = child;

        if (needsV) {
          content = Scrollbar(
            controller: vCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: vCtrl,
              scrollDirection: Axis.vertical,
              child: SizedBox(height: minHeight, child: content),
            ),
          );
        }
        if (needsH) {
          content = Scrollbar(
            controller: hCtrl,
            thumbVisibility: true,
            notificationPredicate: (notif) => notif.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: hCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: minWidth, child: content),
            ),
          );
        }

        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    // ───────────── 모바일 전용: 앱바 + 드로어 + 세로 스택 ─────────────
    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('MediTooth'),
          backgroundColor: const Color(0xFF2D9CDB),
        ),
        drawer: DoctorDrawer(baseUrl: widget.baseUrl),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 상단 KPI 카드 3개 (한 줄에 꽉 차면 줄바꿈)
              _KpiWrap(onGo: (tab) => context.push('/d_telemedicine_application', extra: {'initialTab': tab})),
              const SizedBox(height: 12),

              // 가운데 상태 카드
              _MobileCard(
                child: SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconStat(Icons.cloud, "단체", 13680, Colors.blue),
                      _buildIconStat(Icons.check_circle, "정상", 10470, Colors.green),
                      Consumer<DoctorDashboardViewModel>(
                        builder: (_, vm, __) => _buildIconStat(
                          Icons.warning,
                          "위험",
                          vm.unreadNotifications.clamp(0, 9999).toInt(),
                          Colors.red,
                        ),
                      ),
                      _buildIconStat(Icons.remove_circle_outline, "의사 수", 3208, Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 최근 7일
              _MobileCard(
                title: const _SubChartTitle(text: "최근 7일 신청 건수", color: Color(0xFFEB5757)),
                child: const SizedBox(height: 220, child: _Last7DaysLineChartFancy()),
              ),
              const SizedBox(height: 12),

              // 시간대별
              _MobileCard(
                title: const _SubChartTitle(text: "시간대별 건수", color: Color(0xFF2F80ED)),
                child: const SizedBox(height: 200, child: _HourlyLineChartFancy()),
              ),
              const SizedBox(height: 12),

              // 사진(원본+오버레이 순환) — 썸네일/메타 포함
              _MobileCard(
                titleText: "사진",
                child: const SizedBox(height: 280, child: _ImageCard()),
              ),
              const SizedBox(height: 12),

              // 성별/연령
              _MobileCard(
                titleText: "성별 · 연령대",
                child: const SizedBox(height: 220, child: _DemographicsSplitPanel()),
              ),
              const SizedBox(height: 12),

              // 영상 타입 비율
              _MobileCard(
                titleText: "영상 타입 비율",
                child: const SizedBox(height: 260, child: _VideoTypePieChart()),
              ),
              const SizedBox(height: 12),

              // 알림 + 캘린더
              _MobileCard(
                titleText: "읽지 않은 알림",
                child: Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.warning, color: Colors.red),
                            title: Text("위험 알림 ${index + 1}"),
                            subtitle: const Text("상세 내용 표시"),
                            dense: true,
                            onTap: () {
                              context.push('/d_telemedicine_application', extra: {'initialTab': 1});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 340, child: _buildCalendar()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ───────────── 웹: 기존 레이아웃 유지 ─────────────
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: DoctorDrawer(baseUrl: widget.baseUrl),
      body: _minSizeOnWeb(
        Row(
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
        minWidth: 1000,
        minHeight: 720,
      ),
    );
  }

  // ===================== 좌측 메뉴 (웹) =====================
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
          _sideMenuItem(Icons.dashboard, "통합 대시보드", () => context.go('/d_home')),
          _sideMenuItem(Icons.history, "진료 현황", () => context.go('/d_dashboard')),
          _sideMenuItem(Icons.notifications, "알림", () {
            context.push('/d_telemedicine_application', extra: {'initialTab': 1});
          }),
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

  // ===================== 상단 상태바 (웹) =====================
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Consumer<DoctorDashboardViewModel>(
        builder: (context, vm, _) {
          return Row(
            children: [
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
                      _buildIconStat(Icons.warning, "위험", vm.unreadNotifications.clamp(0, 9999).toInt(), Colors.red),
                      _buildIconStat(Icons.remove_circle_outline, "의사 수", 3208, Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    Text("2025. 8. 17  AM 10:23", style: TextStyle(color: Colors.white, fontSize: 12)),
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

  // ===================== 중앙 차트 영역 (웹) =====================
  Widget _buildChartsArea() {
    return Column(
      children: [
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

  // ===================== 우측 알림 패널 (웹) =====================
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
          const Text("읽지 않은 알림", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text("위험 알림 ${index + 1}"),
                  subtitle: const Text("상세 내용 표시"),
                  dense: true,
                  onTap: () {
                    context.push('/d_telemedicine_application', extra: {'initialTab': 1});
                  },
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

/// ───────────────────────── 모바일 전용 보조 위젯들 ─────────────────────────
class _MobileCard extends StatelessWidget {
  final Widget child;
  final Widget? title;
  final String? titleText;
  const _MobileCard({Key? key, required this.child, this.title, this.titleText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          if (title != null) title!,
          if (title == null && titleText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(titleText!, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          child,
        ],
      ),
    );
  }
}

class _KpiWrap extends StatelessWidget {
  final void Function(int tab) onGo;
  const _KpiWrap({Key? key, required this.onGo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorDashboardViewModel>(
      builder: (_, vm, __) {
        final items = [
          ("오늘의 진료", vm.requestsToday, 0),
          ("진단 대기", vm.unreadNotifications, 1),
          ("진단 완료", vm.answeredToday, 2),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((e) {
            return GestureDetector(
              onTap: () => onGo(e.$3),
              child: Container(
                width: (MediaQuery.of(context).size.width - 12 * 2 - 8 * 2) / 3, // 3칸 균등
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 200, minHeight: 72),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${e.$2}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(e.$1, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// ───────────────────────── 공용/기존 위젯들 ─────────────────────────

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

/// ▼ 추가: 좁은 폭에서 사용되는 간략 포맷들
String _shortDateLabel({
  required int index,
  required List<String> labels,        // 'MM-DD'
  required List<String>? fulls,        // 'YYYY-MM-DD'
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
  return '${dt.month}/${dt.day}';
}

String _veryShortDateLabel({
  required int index,
  required List<String> labels,
  required List<String>? fulls,
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
  final w = _weekdayKr(dt.weekday % 7);
  return '${dt.day}($w)';
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

    // ▼ 카드 폭에 맞춰 라벨 형식/간격/높이를 자동 조정
    return LayoutBuilder(
      builder: (context, cons) {
        final width = cons.maxWidth;
        final n = counts.length.clamp(1, 100);
        final per = width / n; // 포인트당 가용 폭

        // 기본값
        int step = 1;                 // 라벨 표시 간격
        double reserved = 42;         // 라벨 영역 높이
        bool useChip = true;          // 칩 배경 사용 여부
        String Function(int) fmt = (i) =>
            _prettyDateLabel(index: i, labels: labels, fulls: fullDates);

        // 폭이 좁아질수록 더 짧은 포맷/간격으로
        if (per < 84 && per >= 56) {
          // 중간 폭: 'M/D'
          reserved = 32;
          useChip = false;
          fmt = (i) => _shortDateLabel(index: i, labels: labels, fulls: fullDates);
        } else if (per < 56 && per >= 36) {
          // 좁음: 2칸 간격 + 'M/D'
          step = 2;
          reserved = 28;
          useChip = false;
          fmt = (i) => _shortDateLabel(index: i, labels: labels, fulls: fullDates);
        } else if (per < 36) {
          // 아주 좁음: 3칸 간격 + 'D(목)'
          step = 3;
          reserved = 24;
          useChip = false;
          fmt = (i) => _veryShortDateLabel(index: i, labels: labels, fulls: fullDates);
        }

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
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, // 두 번째 코드 기준 유지 (라벨 표시)
                    reservedSize: reserved,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();

                      // 마지막 tick은 무조건 보이도록, 나머지는 step 간격에 맞춰 표시
                      final isLast = i == labels.length - 1;
                      if (!isLast && (i % step != 0)) return const SizedBox.shrink();

                      final text = fmt(i);

                      final label = Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (reserved <= 24) ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      );

                      return Padding(
                        padding: EdgeInsets.only(top: (reserved <= 28) ? 4 : 8),
                        child: FittedBox(
                          child: useChip
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: label,
                                )
                              : label,
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
                  spots: [
                    for (int i = 0; i < counts.length; i++) FlSpot(i.toDouble(), counts[i].toDouble())
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ===================== 시간대별 라인차트 =====================
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

/// ===================== 사진 카드(원본 + 오버레이 순환 + 썸네일/설명) =====================
class _ImageCard extends StatefulWidget {
  const _ImageCard({Key? key}) : super(key: key);

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  int _caseIndex = 0;
  int _layerIndex = 0;
  Timer? _auto;
  DateTime? _pausedUntil;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  void _startAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_pausedUntil != null && DateTime.now().isBefore(_pausedUntil!)) return;

      final vm = context.read<DoctorDashboardViewModel>();
      final items = vm.imageItems;

      if (items.isEmpty) return;

      final current = items[_caseIndex.clamp(0, items.length - 1)];
      final layers = vm.layerKeysFor(current);
      if (layers.isEmpty || layers.length == 1) return;

      setState(() {
        _layerIndex = (_layerIndex + 1) % layers.length;
      });
    });
  }

  void _pauseAuto({int seconds = 6}) {
    _pausedUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  void _showFullscreen(BuildContext context, String url) {
    _pauseAuto(seconds: 8);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fullscreen',
      barrierColor: Colors.black.withOpacity(0.65),
      pageBuilder: (_, __, ___) {
        final size = MediaQuery.of(context).size;
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
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DoctorDashboardViewModel>(context);

    final items = vm.imageItems;
    String currentUrl;
    int casesCount;
    int layersCountForCurrent = 1;

    if (items.isNotEmpty) {
      _caseIndex = _caseIndex.clamp(0, items.length - 1);
      final item = items[_caseIndex];

      final layers = vm.layerKeysFor(item);
      if (layers.isEmpty) {
        layersCountForCurrent = 1;
        _layerIndex = 0;
        currentUrl = vm.resolveUrl(item, 'original');
      } else {
        layersCountForCurrent = layers.length;
        _layerIndex = _layerIndex.clamp(0, layers.length - 1);
        final layerKey = layers[_layerIndex];
        currentUrl = vm.resolveUrl(item, layerKey);
      }
      casesCount = items.length;
    } else {
      final urls = (vm.imageUrls.isNotEmpty)
          ? vm.imageUrls
          : <String>['https://picsum.photos/seed/dash0/1200/800'];
      _caseIndex = _caseIndex.clamp(0, urls.length - 1);
      _layerIndex = 0;
      layersCountForCurrent = 1;
      currentUrl = urls[_caseIndex];
      casesCount = urls.length;
    }

    void prevCase() {
      if (casesCount <= 0) return;
      _pauseAuto();
      setState(() {
        _caseIndex = (_caseIndex - 1 + casesCount) % casesCount;
        _layerIndex = 0;
      });
    }

    void nextCase() {
      if (casesCount <= 0) return;
      _pauseAuto();
      setState(() {
        _caseIndex = (_caseIndex + 1) % casesCount;
        _layerIndex = 0;
      });
    }

    void openFull() => _showFullscreen(context, currentUrl);

    // ---- 메인 뷰어(큰 이미지 + 3분할 탭 + 인덱스 배지)
    Widget buildMainViewer() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(kImageRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey<String>(
                    'case$_caseIndex-layer$_layerIndex-$currentUrl'),
                child: Image.network(
                  currentUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),

            // 좌/중앙/우 탭
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OverlayTapZone(
                      onTap: prevCase,
                      child: const SizedBox.shrink(),
                      align: Alignment.centerLeft,
                      flex: 1),
                  _OverlayTapZone(
                      onTap: openFull,
                      child: const SizedBox.shrink(),
                      align: Alignment.center,
                      flex: 2),
                  _OverlayTapZone(
                      onTap: nextCase,
                      child: const SizedBox.shrink(),
                      align: Alignment.centerRight,
                      flex: 1),
                ],
              ),
            ),

            // 하단 인덱스
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_caseIndex + 1} / $casesCount'
                    '${layersCountForCurrent > 1 ? ' • layer ${_layerIndex + 1}/$layersCountForCurrent' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ---- 썸네일 스트립
    Widget buildThumbnails() {
      return SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: casesCount,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final thumbUrl = (items.isNotEmpty)
                ? vm.resolveUrl(items[i], 'original')
                : vm.imageUrls[i];
            return GestureDetector(
              onTap: () {
                _pauseAuto();
                setState(() {
                  _caseIndex = i;
                  _layerIndex = 0;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  thumbUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        size: 24, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // ---- 메타 텍스트(예시)
    Widget buildMeta() {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          "촬영일: 2025-08-17 | 설명: 치아 상태 점검",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    // ---- 최종 레이아웃: 큰 이미지 + 썸네일 + 메타
    return Column(
      children: [
        Expanded(child: buildMainViewer()),
        const SizedBox(height: 8),
        buildThumbnails(),
        buildMeta(),
      ],
    );
  }
}

/// ===================== Overlay Tap Zone =====================
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
            color: Colors.black.withOpacity(_opacity),
            child: widget.child,
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
