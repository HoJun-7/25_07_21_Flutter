import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';

// ▼ 추가: 전국 날씨 카드
import '../../widgets/national_weather_card.dart';

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

  // ✅ 주기적 새로고침 타이머
  Timer? _refreshTimer;

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
      vm.loadAgeDistributionData(widget.baseUrl, day: selectedDay);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<DoctorDashboardViewModel>();
      _loadAll(vm);
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final vm = context.read<DoctorDashboardViewModel>();
      _loadAll(vm);
    });
  }

  void _loadAll(DoctorDashboardViewModel vm) {
    vm.loadDashboardData(widget.baseUrl);
    vm.loadRecent7DaysData(widget.baseUrl);
    vm.loadAgeDistributionData(widget.baseUrl, day: _focusedDay);
    vm.loadHourlyStats(widget.baseUrl, day: _focusedDay);
    vm.loadImagesByDate(widget.baseUrl, day: _focusedDay, limit: 9);
    vm.loadVideoTypeRatio(widget.baseUrl, day: _focusedDay);
  }

  bool _isMobile(BuildContext context) =>
      !kIsWeb && MediaQuery.of(context).size.width < 600;

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
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    // ───────────── 모바일 ─────────────
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
              _KpiWrap(onGo: (tab) => context.push('/d_telemedicine_application', extra: {'initialTab': tab})),
              const SizedBox(height: 12),

              // ▼ 변경된 4개 지표 (등록의사/전체 응답/알림/달력)
              _MobileCard(
                child: SizedBox(
                  height: 100,
                  child: Consumer<DoctorDashboardViewModel>(
                    builder: (_, vm, __) {
                      final int registeredDoctors = (() {
                        try {
                          final d = vm as dynamic;
                          if (d.registeredDoctors is int) return d.registeredDoctors as int;
                        } catch (_) {}
                        return 3208;
                      })();

                      final int totalAnswers = (() {
                        try {
                          final d = vm as dynamic;
                          if (d.totalAnswers is int) return d.totalAnswers as int;
                        } catch (_) {}
                        return vm.answeredToday;
                      })();

                      final int alerts = vm.unreadNotifications.clamp(0, 9999).toInt();
                      final int todaysEvents = _getEventsForDay(_focusedDay).length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildIconStat(Icons.medical_services_outlined, "등록의사", registeredDoctors, Colors.blue),
                          _buildIconStat(Icons.mark_chat_read_outlined, "전체 응답", totalAnswers, Colors.green),
                          _buildIconStat(Icons.notifications_active_outlined, "알림", alerts, Colors.red),
                          _buildIconStat(Icons.calendar_month_outlined, "달력", todaysEvents, Colors.orange),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "최근 7일 신청 건수", color: Color(0xFFEB5757)),
                child: const SizedBox(height: 220, child: _Last7DaysLineChartFancy()),
              ),
              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "시간대별 건수", color: Color(0xFF2F80ED)),
                child: const SizedBox(height: 200, child: _HourlyLineChartFancy()),
              ),
              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "사진", color: Colors.orange),
                child: const SizedBox(height: 280, child: _ImageCard()),
              ),
              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "성별 · 연령대", color: Colors.green),
                child: const SizedBox(height: 220, child: _DemographicsSplitPanel()),
              ),
              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "영상 타입 비율", color: Colors.purple),
                child: const SizedBox(height: 260, child: _VideoTypePieChart()),
              ),
              const SizedBox(height: 12),
              _MobileCard(
                title: const _SubChartTitle(text: "읽지 않은 알림", color: Colors.red),
                child: Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(
                              Icons.notifications_active_outlined, // ← KPI와 동일
                              color: Colors.red,
                              size: 22,
                            ),
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
                    SizedBox(
                      height: 340,
                      child: _CalendarCore(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (f) => setState(() => _calendarFormat = f),
                        onDaySelected: _onDaySelected,
                        getEventsForDay: _getEventsForDay,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ───────────── 웹 ─────────────
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
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Expanded(child: _alertsCard()),
                                const SizedBox(height: 16),
                                Expanded(child: _calendarCard()),
                              ],
                            ),
                          ),
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

  // ===================== 공통: 라벨 칩 =====================
  Widget _chipLabel(String text, {bool onDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: onDark ? Colors.white : Colors.black87,
        ),
      ),
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
              // 좌측 KPI (오늘의 진료/진단 대기/진단 완료) — 칩 스타일 라벨 onDark 적용
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
                        onDark: true,
                      ),
                      _buildClickableNumber(
                        "진단 대기",
                        vm.unreadNotifications,
                        Colors.white,
                        () => context.push('/d_telemedicine_application', extra: {'initialTab': 1}),
                        onDark: true,
                      ),
                      _buildClickableNumber(
                        "진단 완료",
                        vm.answeredToday,
                        Colors.white,
                        () => context.push('/d_telemedicine_application', extra: {'initialTab': 2}),
                        onDark: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ▼ 등록의사/전체 응답/알림/달력 — 칩 스타일 라벨 (라이트)
              Expanded(
                flex: 3,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Consumer<DoctorDashboardViewModel>(
                    builder: (_, vm, __) {
                      final int registeredDoctors = (() {
                        try {
                          final d = vm as dynamic;
                          if (d.registeredDoctors is int) return d.registeredDoctors as int;
                        } catch (_) {}
                        return 3208;
                      })();

                      final int totalAnswers = (() {
                        try {
                          final d = vm as dynamic;
                          if (d.totalAnswers is int) return d.totalAnswers as int;
                        } catch (_) {}
                        return vm.answeredToday;
                      })();

                      final int alerts = vm.unreadNotifications.clamp(0, 9999).toInt();
                      final int todaysEvents = _getEventsForDay(_focusedDay).length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildIconStat(Icons.medical_services_outlined, "등록의사", registeredDoctors, Colors.blue),
                          _buildIconStat(Icons.mark_chat_read_outlined, "전체 응답", totalAnswers, Colors.green),
                          _buildIconStat(Icons.notifications_active_outlined, "알림", alerts, Colors.red),
                          _buildIconStat(Icons.calendar_month_outlined, "달력", todaysEvents, Colors.orange),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 실시간 전국 날씨 카드
              SizedBox(
                width: 200,
                child: const NationalWeatherCard(height: 80),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClickableNumber(
    String label,
    int value,
    Color color,
    VoidCallback onTap, {
    bool onDark = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$value", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          _chipLabel(label, onDark: onDark), // ← 칩 스타일 라벨
        ],
      ),
    );
  }

  // ▼ 글씨/아이콘 크기 통일 + 라벨 칩 적용
  Widget _buildIconStat(IconData icon, String label, int value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text("$value", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        _chipLabel(label), // ← 칩 스타일 라벨
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
              Expanded(child: _chartCard(const _SubChartTitle(text: "사진", color: Colors.orange), const _ImageCard())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _chartCard(const _SubChartTitle(text: "성별 · 연령대", color: Colors.green), const _DemographicsSplitPanel())),
              const SizedBox(width: 16),
              Expanded(child: _chartCard(const _SubChartTitle(text: "영상 타입 비율", color: Colors.purple), const _VideoTypePieChart())),
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
      clipBehavior: Clip.hardEdge,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _chartCard(Widget title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
    );
  }

  // ===================== 우측 알림 카드 =====================
  Widget _alertsCard() {
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
          const _SubChartTitle(text: "읽지 않은 알림", color: Colors.red),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined, // ← KPI와 동일
                    color: Colors.red,
                    size: 22,
                  ),
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
        ],
      ),
    );
  }

  // ===================== 우측 캘린더 카드 =====================
  Widget _calendarCard() {
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
          const _SubChartTitle(text: "캘린더", color: Color(0xFF2F80ED)),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // 가용 공간이 작으면 컴팩트 모드(2주 보기)로
                final compact = c.maxHeight < 320;
                return _CalendarCore(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (f) => setState(() => _calendarFormat = f),
                  onDaySelected: _onDaySelected,
                  getEventsForDay: _getEventsForDay,
                  compact: compact, // ★ 추가
                );
              },
            ),
          ),
        ],
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
                width: (MediaQuery.of(context).size.width - 12 * 2 - 8 * 2) / 3,
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
                    const SizedBox(height: 4),
                    // 모바일 KPI는 가독성 위해 기본 텍스트 유지
                    const SizedBox.shrink(),
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

// ---- 캘린더 코어 위젯(웹/모바일 공용) ----
class _CalendarCore extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final void Function(DateTime, DateTime) onDaySelected;
  final List<dynamic> Function(DateTime) getEventsForDay;
  final bool compact; // ★ 추가

  const _CalendarCore({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onFormatChanged,
    required this.onDaySelected,
    required this.getEventsForDay,
    this.compact = false, // 기본 false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        // 가용 높이에 따라 포맷/행 높이 자동 조정
        final effectiveFormat = compact && calendarFormat == CalendarFormat.month
            ? CalendarFormat.twoWeeks
            : calendarFormat;

        // 헤더/요일영역/여백 반영 후 rowHeight 계산
        const headerH = 52.0;
        final dowH = compact ? 18.0 : 22.0;
        final weeks = (effectiveFormat == CalendarFormat.month) ? 6 : 2;
        final usable = (cons.maxHeight - headerH - dowH - 16).clamp(120.0, 1000.0);
        final rowH = (usable / weeks).clamp(22.0, compact ? 30.0 : 44.0);

        return TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: effectiveFormat,
          onFormatChanged: onFormatChanged,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          eventLoader: getEventsForDay,

          // 동적 높이
          daysOfWeekHeight: dowH,
          rowHeight: rowH,

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.blue),
            rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.blue),
          ),
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

/// ===================== 유틸: 날짜 라벨 포맷 =====================
String _weekdayKr(int w) => const ['일', '월', '화', '수', '목', '금', '토'][w % 7];

String _prettyDateLabel({
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
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final w = _weekdayKr(dt.weekday % 7);
  return '$mm/$dd ($w)';
}

String _shortDateLabel({
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

    return LayoutBuilder(
      builder: (context, cons) {
        final width = cons.maxWidth;
        final n = counts.length.clamp(1, 100);
        final per = width / n;

        int step = 1;
        double reserved = 42;
        bool useChip = true;
        String Function(int) fmt = (i) =>
            _prettyDateLabel(index: i, labels: labels, fulls: fullDates);

        if (per < 84 && per >= 56) {
          reserved = 32;
          useChip = false;
          fmt = (i) => _shortDateLabel(index: i, labels: labels, fulls: fullDates);
        } else if (per < 56 && per >= 36) {
          step = 2;
          reserved = 28;
          useChip = false;
          fmt = (i) => _shortDateLabel(index: i, labels: labels, fulls: fullDates);
        } else if (per < 36) {
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
                    showTitles: true,
                    reservedSize: reserved,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();

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
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipMargin: 8,
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
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipMargin: 8,
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

/// ===================== 사진 카드 =====================
class _ImageCard extends StatefulWidget {
  const _ImageCard({Key? key}) : super(key: key);

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> with TickerProviderStateMixin {
  int _caseIndex = 0;
  int _layerIndex = 0;
  Timer? _auto;
  DateTime? _pausedUntil;

  bool _showDetails = true;
  final double _thumbBarHeight = 60.0;

  double? _imgW;
  double? _imgH;
  String? _lastOriginalUrl;

  void _ensureOriginalSize(String url) {
    if (_lastOriginalUrl == url && _imgW != null && _imgH != null) return;

    _lastOriginalUrl = url;
    _imgW = null;
    _imgH = null;

    final stream = Image.network(url).image.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      _imgW = info.image.width.toDouble();
      _imgH = info.image.height.toDouble();
      setState(() {});
      stream.removeListener(listener);
    }, onError: (_, __) {
      _imgW = 1200;
      _imgH = 900;
      setState(() {});
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

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
      final overlays = vm.layerKeysFor(current).where((k) => k != 'original').toList();
      if (overlays.length <= 1) return;

      setState(() {
        _layerIndex = (_layerIndex + 1) % overlays.length;
      });
    });
  }

  void _pauseAuto({int seconds = 6}) {
    _pausedUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  void _toggleDetails() {
    _pauseAuto(seconds: 2);
    setState(() => _showDetails = !_showDetails);
  }

  void _showFullscreen(BuildContext context) {
    _pauseAuto(seconds: 8);

    final vm = context.read<DoctorDashboardViewModel>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fullscreen',
      barrierColor: Colors.black.withOpacity(0.65),
      pageBuilder: (_, __, ___) {
        return _FullscreenSlideViewer(
          vm: vm,
          initialIndex: _caseIndex,
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

    String originalUrl;
    String? overlayUrl;
    int casesCount;
    List<String> overlayKeys = const [];

    if (items.isNotEmpty) {
      _caseIndex = _caseIndex.clamp(0, items.length - 1);
      final item = items[_caseIndex];

      originalUrl = vm.resolveUrl(item, 'original');

      overlayKeys = vm.layerKeysFor(item).where((k) => k != 'original').toList();

      if (overlayKeys.isNotEmpty) {
        _layerIndex = _layerIndex.clamp(0, overlayKeys.length - 1);
        overlayUrl = vm.resolveUrl(item, overlayKeys[_layerIndex]);
      } else {
        _layerIndex = 0;
        overlayUrl = null;
      }
      casesCount = items.length;
    } else {
      final urls = (vm.imageUrls.isNotEmpty)
          ? vm.imageUrls
          : <String>['https://picsum.photos/seed/dash0/1200/800'];
      _caseIndex = _caseIndex.clamp(0, urls.length - 1);
      originalUrl = urls[_caseIndex];
      overlayUrl = null;
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

    void openFull() => _showFullscreen(context);

    Widget buildMainViewer() {
      _ensureOriginalSize(originalUrl);

      final hasSize = _imgW != null && _imgH != null;

      return ClipRRect(
        borderRadius: BorderRadius.circular(kImageRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: hasSize ? _imgW! : 1200,
                  height: hasSize ? _imgH! : 900,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        originalUrl,
                        width: _imgW,
                        height: _imgH,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey, size: 48),
                        ),
                      ),
                      if (overlayUrl != null)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey<String>('overlay-$_caseIndex-$_layerIndex-$overlayUrl'),
                            child: Image.network(
                              overlayUrl!,
                              width: _imgW,
                              height: _imgH,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OverlayTapZone(onTap: prevCase, child: const SizedBox.shrink(), align: Alignment.centerLeft, flex: 1),
                  _OverlayTapZone(onTap: openFull, child: const SizedBox.shrink(), align: Alignment.center, flex: 2),
                  _OverlayTapZone(onTap: nextCase, child: const SizedBox.shrink(), align: Alignment.centerRight, flex: 1),
                ],
              ),
            ),

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
                    '${_caseIndex + 1} / $casesCount'
                    '${overlayKeys.length > 1 ? ' • layer ${_layerIndex + 1}/${overlayKeys.length}' : ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: _toggleDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showDetails ? Icons.expand_less : Icons.expand_more,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(_showDetails ? '접기' : '펼치기',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildThumbnails() {
      return SizedBox(
        height: _thumbBarHeight,
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
                  width: _thumbBarHeight,
                  height: _thumbBarHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: _thumbBarHeight,
                    height: _thumbBarHeight,
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

    Widget buildMeta() {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          "촬영일: 2025-08-17 | 설명: 치아 상태 점검",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    return Column(
      children: [
        Expanded(flex: _showDetails ? 9 : 12, child: buildMainViewer()),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: _showDetails
              ? Column(
                  children: [
                    buildThumbnails(),
                    buildMeta(),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// ===================== 풀스크린 뷰어 =====================
class _FullscreenSlideViewer extends StatefulWidget {
  final DoctorDashboardViewModel vm;
  final int initialIndex;
  const _FullscreenSlideViewer({Key? key, required this.vm, required this.initialIndex}) : super(key: key);

  @override
  State<_FullscreenSlideViewer> createState() => _FullscreenSlideViewerState();
}

class _FullscreenSlideViewerState extends State<_FullscreenSlideViewer> {
  late int _caseIndex;
  int _layerIndex = 0;
  Timer? _auto;
  DateTime? _pausedUntil;

  @override
  void initState() {
    super.initState();
    _caseIndex = widget.initialIndex;
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

      final items = widget.vm.imageItems;
      if (items.isEmpty) return;

      final current = items[_caseIndex.clamp(0, items.length - 1)];
      final overlays = widget.vm.layerKeysFor(current).where((k) => k != 'original').toList();
      if (overlays.length <= 1) return;

      setState(() {
        _layerIndex = (_layerIndex + 1) % overlays.length;
      });
    });
  }

  void _pauseAuto({int seconds = 6}) {
    _pausedUntil = DateTime.now().add(Duration(seconds: seconds));
  }

  void _prev() {
    final items = widget.vm.imageItems;
    if (items.isEmpty) return;
    _pauseAuto();
    setState(() {
      _caseIndex = (_caseIndex - 1 + items.length) % items.length;
      _layerIndex = 0;
    });
  }

  void _next() {
    final items = widget.vm.imageItems;
    if (items.isEmpty) return;
    _pauseAuto();
    setState(() {
      _caseIndex = (_caseIndex + 1) % items.length;
      _layerIndex = 0;
    });
  }

  void _nextLayer() {
    final items = widget.vm.imageItems;
    if (items.isEmpty) return;
    final current = items[_caseIndex];
    final overlays = widget.vm.layerKeysFor(current).where((k) => k != 'original').toList();
    if (overlays.isEmpty) return;
    _pauseAuto();
    setState(() {
      _layerIndex = (_layerIndex + 1) % overlays.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.vm.imageItems;
    String originalUrl;
    String? overlayUrl;
    List<String> overlayKeys = const [];

    if (items.isNotEmpty) {
      _caseIndex = _caseIndex.clamp(0, items.length - 1);
      final item = items[_caseIndex];
      originalUrl = widget.vm.resolveUrl(item, 'original');
      overlayKeys = widget.vm.layerKeysFor(item).where((k) => k != 'original').toList();
      if (overlayKeys.isNotEmpty) {
        _layerIndex = _layerIndex.clamp(0, overlayKeys.length - 1);
        overlayUrl = widget.vm.resolveUrl(item, overlayKeys[_layerIndex]);
      } else {
        overlayUrl = null;
        _layerIndex = 0;
      }
    } else {
      originalUrl = (widget.vm.imageUrls.isNotEmpty)
          ? widget.vm.imageUrls.first
          : 'https://picsum.photos/seed/dash0/1200/800';
      overlayUrl = null;
    }

    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final maxWidthByHeight = h * (4 / 3);
    final boxWidth = w < maxWidthByHeight ? w : maxWidthByHeight;
    final boxHeight = boxWidth * (3 / 4);

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kImageRadius),
                child: Container(
                  width: boxWidth,
                  height: boxHeight,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                originalUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                ),
                              ),
                              if (overlayUrl != null)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: KeyedSubtree(
                                    key: ValueKey<String>('fs-overlay-$_caseIndex-$_layerIndex-$overlayUrl'),
                                    child: Image.network(
                                      overlayUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _OverlayTapZone(onTap: _prev, child: const SizedBox.shrink(), align: Alignment.centerLeft, flex: 1),
                            _OverlayTapZone(onTap: _nextLayer, child: const SizedBox.shrink(), align: Alignment.center, flex: 2),
                            _OverlayTapZone(onTap: _next, child: const SizedBox.shrink(), align: Alignment.centerRight, flex: 1),
                          ],
                        ),
                      ),

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
                              '${items.isEmpty ? 0 : (_caseIndex + 1)} / ${items.isEmpty ? 0 : items.length}'
                              '${overlayKeys.length > 1 ? ' • layer ${_layerIndex + 1}/${overlayKeys.length}' : ''}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              right: 24,
              top: 24,
              child: IconButton(
                iconSize: 28,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
                splashRadius: 24,
                tooltip: '닫기',
              ),
            ),
          ],
        ),
      ),
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
