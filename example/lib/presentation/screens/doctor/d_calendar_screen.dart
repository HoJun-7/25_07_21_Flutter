import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'd_calendar_placeholder.dart';

// ===== 공통: 드로어 여백 예약 값 =====
const double _kDrawerGutterExtra = 16.0; // 드로어와 본문 사이 시각적 간격

double _drawerReservedWidth(BuildContext context) {
  final themeWidth = DrawerTheme.of(context).width;
  // Material 기본 드로어 폭: 304
  final base = themeWidth ?? 304.0;
  return base + _kDrawerGutterExtra;
}

enum AppointmentStatus { pending, confirmed, completed, canceled }

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return '대기';
      case AppointmentStatus.confirmed:
        return '확정';
      case AppointmentStatus.completed:
        return '완료';
      case AppointmentStatus.canceled:
        return '취소';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.canceled:
        return Colors.red;
    }
  }
}

class Appointment {
  final String id;
  final String title;
  final String? patientName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final AppointmentStatus status;
  final String? location;
  final String? notes;

  Appointment({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.patientName,
    this.location,
    this.notes,
    this.status = AppointmentStatus.pending,
  });

  DateTime get startDateTime =>
      DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
  DateTime get endDateTime =>
      DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);

  Appointment copyWith({
    String? id,
    String? title,
    String? patientName,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    AppointmentStatus? status,
    String? location,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      patientName: patientName ?? this.patientName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}

class DCalendarScreen extends StatefulWidget {
  const DCalendarScreen({super.key});

  @override
  State<DCalendarScreen> createState() => _DCalendarScreenState();
}

class _DCalendarScreenState extends State<DCalendarScreen> {
  final DateFormat _hm = DateFormat('HH:mm');
  final TextEditingController _searchCtr = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final Map<DateTime, List<Appointment>> _events = {};
  final Map<DateTime, String> _holidayNames = {};

  final Set<AppointmentStatus> _selectedStatuses = {
    AppointmentStatus.pending,
    AppointmentStatus.confirmed,
    AppointmentStatus.completed,
    AppointmentStatus.canceled,
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalize(DateTime.now());
    _seedSample();
    _rebuildHolidaysForYear(_focusedDay.year);
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  // 샘플 일정
  void _seedSample() {
    final today = _normalize(DateTime.now());
    final tomorrow = _normalize(DateTime.now().add(const Duration(days: 1)));
    _addToEvents(
      Appointment(
        id: _genId(),
        title: '치아 스케일링',
        patientName: '김영희',
        date: today,
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        status: AppointmentStatus.confirmed,
        location: '진료실 2',
        notes: '치은염 의심',
      ),
    );
    _addToEvents(
      Appointment(
        id: _genId(),
        title: '충치 치료',
        patientName: '홍길동',
        date: today,
        startTime: const TimeOfDay(hour: 11, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 40),
        status: AppointmentStatus.pending,
        location: '진료실 1',
      ),
    );
    _addToEvents(
      Appointment(
        id: _genId(),
        title: '임플란트 상담',
        patientName: '이순신',
        date: tomorrow,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 30),
        status: AppointmentStatus.completed,
        location: '상담실',
      ),
    );
  }

  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _addToEvents(Appointment a) {
    final day = _normalize(a.date);
    final list = _events[day] ?? [];
    _events[day] = [...list, a]..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  void _updateInEvents(Appointment updated) {
    for (final entry in _events.entries.toList()) {
      _events[entry.key] = entry.value.where((e) => e.id != updated.id).toList();
      if (_events[entry.key]!.isEmpty) _events.remove(entry.key);
    }
    _addToEvents(updated);
  }

  /// ✅ 삭제 버튼 누른 "그 일정 한 개만" 삭제
  void _deleteFromEvents(Appointment appt) {
    final key = _normalize(appt.date);
    final list = _events[key];
    if (list == null) return;

    _events[key] = list.where((e) => e.id != appt.id).toList();
    if (_events[key]!.isEmpty) {
      _events.remove(key);
    }
    setState(() {}); // 화면 갱신
  }

  List<Appointment> _eventsForDay(DateTime day) {
    final key = _normalize(day);
    final raw = _events[key] ?? const <Appointment>[];
    final query = _searchCtr.text.trim();
    return raw.where((a) {
      final okStatus = _selectedStatuses.contains(a.status);
      final okQuery = query.isEmpty
          ? true
          : [
              a.title,
              a.patientName ?? '',
              a.location ?? '',
              a.notes ?? '',
              a.status.label,
            ].any((t) => t.toLowerCase().contains(query.toLowerCase()));
      return okStatus && okQuery;
    }).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  // 공휴일 (간단: 양력 고정 + 일요일 대체)
  void _addHoliday(DateTime date, String name) {
    _holidayNames[_normalize(date)] = name;
  }

  List<(DateTime, String)> _fixedSolarHolidays(int year) => [
        (DateTime(year, 1, 1), '신정'),
        (DateTime(year, 3, 1), '삼일절'),
        (DateTime(year, 5, 5), '어린이날'),
        (DateTime(year, 6, 6), '현충일'),
        (DateTime(year, 8, 15), '광복절'),
        (DateTime(year, 10, 3), '개천절'),
        (DateTime(year, 10, 9), '한글날'),
        (DateTime(year, 12, 25), '성탄절'),
      ];

  void _rebuildHolidaysForYear(int year) {
    _holidayNames.clear();
    for (final (d, name) in _fixedSolarHolidays(year)) {
      _addHoliday(d, name);
    }
    // 대체공휴일(간단): 일요일이면 다음 비공휴일 평일
    final base = _holidayNames.keys.toList()..sort();
    for (final d in base) {
      if (d.weekday == DateTime.sunday) {
        var sub = d.add(const Duration(days: 1));
        while (_holidayNames.containsKey(sub) || sub.weekday == DateTime.sunday) {
          sub = sub.add(const Duration(days: 1));
        }
        _addHoliday(sub, '${_holidayNames[d]} (대체)');
      }
    }
    setState(() {});
  }

  bool _isHoliday(DateTime day) => _holidayNames.containsKey(_normalize(day));

  Future<void> _pickAdd() async {
    final created = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AppointmentEditor(
        date: _selectedDay ?? _normalize(DateTime.now()),
      ),
    );
    if (created != null) setState(() => _addToEvents(created));
  }

  Future<void> _pickEdit(Appointment appt) async {
    final edited = await showModalBottomSheet<Appointment?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AppointmentEditor(existing: appt),
    );
    if (edited == null) return;

    if (edited.title == '__DELETE__') {
      _deleteFromEvents(appt);
    } else {
      setState(() => _updateInEvents(edited));
    }
  }

  /// 왼쪽 칩, 오른쪽 검색창
  Widget _buildFilters() {
    final chips = AppointmentStatus.values.map((s) {
      final selected = _selectedStatuses.contains(s);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: selected,
          label: Text(s.label),
          onSelected: (v) {
            setState(() {
              if (v) {
                _selectedStatuses.add(s);
              } else {
                _selectedStatuses.remove(s);
              }
            });
          },
          avatar: CircleAvatar(
            backgroundColor: s.color.withOpacity(0.15),
            child: Icon(Icons.circle, size: 12, color: s.color),
          ),
        ),
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double searchWidth =
            constraints.maxWidth < 600 ? constraints.maxWidth * 0.45 : 320;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chips),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: searchWidth.clamp(200, 360),
                child: TextField(
                  controller: _searchCtr,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: '이름/제목/위치/메모 검색',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay ?? _normalize(DateTime.now());
    final dayEvents = _eventsForDay(selectedDay);

    // 와이드/웹이면 드로어 폭만큼 항상 비움
    final isWide = kIsWeb || MediaQuery.of(context).size.width >= 1000;
    final reserved = isWide ? _drawerReservedWidth(context) : 0.0;

    // 폰트 통일(크기/굵기)
    const TextStyle kDowStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    const TextStyle kDayStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    const TextStyle kSelectedText = TextStyle(color: Colors.white, fontWeight: FontWeight.w700);

    final calendarBody = Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TableCalendar<Appointment>(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                calendarFormat: _calendarFormat,
                eventLoader: (day) => _events[_normalize(day)] ?? const [],
                startingDayOfWeek: StartingDayOfWeek.sunday,

                rowHeight: 46,
                daysOfWeekHeight: 28,

                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: kDowStyle,
                  weekendStyle: kDowStyle,
                ),

                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (d, l) => DateFormat('yyyy년 M월', l).format(d),
                  titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                holidayPredicate: (day) => _isHoliday(day),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: kDayStyle,
                  weekendTextStyle: kDayStyle,
                  outsideDaysVisible: false,

                  todayDecoration: const BoxDecoration(),
                  todayTextStyle: kDayStyle.copyWith(
                    color: const Color.fromARGB(255, 146, 157, 161),
                  ),

                  selectedDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 73, 129, 248),
                  ),
                  selectedTextStyle: kSelectedText,

                  holidayDecoration: const BoxDecoration(),
                  holidayTextStyle: kDayStyle.copyWith(color: Colors.redAccent),

                  markerDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                ),

                calendarBuilders: CalendarBuilders<Appointment>(
                  dowBuilder: (context, day) {
                    final label = DateFormat.E('ko_KR').format(day);
                    Color? color;
                    if (day.weekday == DateTime.sunday) color = Colors.red;
                    if (day.weekday == DateTime.saturday) color = Colors.blue;
                    return Center(child: Text(label, style: kDowStyle.copyWith(color: color)));
                  },
                  defaultBuilder: (context, day, focused) {
                    if (isSameDay(day, _selectedDay) ||
                        _isHoliday(day) ||
                        isSameDay(day, DateTime.now())) {
                      return null;
                    }
                    Color? color;
                    if (day.weekday == DateTime.sunday) color = Colors.red;
                    if (day.weekday == DateTime.saturday) color = Colors.blue;
                    if (color != null) {
                      return Center(
                        child: Text('${day.day}', style: kDayStyle.copyWith(color: color)),
                      );
                    }
                    return null;
                  },
                ),

                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = _normalize(selected);
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  final prevYear = _focusedDay.year;
                  _focusedDay = focused;
                  if (prevYear != focused.year) {
                    _rebuildHolidaysForYear(focused.year);
                  }
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildFilters(),
        const SizedBox(height: 8),
        Expanded(
          child: dayEvents.isEmpty
              ? DCalendarPlaceholder(
                  message: '선택한 날짜에 일정이 없습니다.',
                  buttonLabel: '새 일정 만들기',
                  onPressed: _pickAdd,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  itemCount: dayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final a = dayEvents[i];
                    return InkWell(
                      onTap: () => _pickEdit(a),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 56,
                              decoration: BoxDecoration(
                                color: a.status.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '${_hm.format(a.startDateTime)} - ${_hm.format(a.endDateTime)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: a.status.color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: a.status.color.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          a.status.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: a.status.color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (a.patientName != null && a.patientName!.isNotEmpty) ...[
                                        const Icon(Icons.person, size: 16),
                                        const SizedBox(width: 4),
                                        Text(a.patientName!),
                                        const SizedBox(width: 12),
                                      ],
                                      if (a.location != null && a.location!.isNotEmpty) ...[
                                        const Icon(Icons.place, size: 16),
                                        const SizedBox(width: 4),
                                        Text(a.location!),
                                      ],
                                    ],
                                  ),
                                  if ((a.notes ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      a.notes!,
                                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '상태 변경',
                              icon: const Icon(Icons.more_vert),
                              onPressed: () async {
                                final newStatus = await showMenu<AppointmentStatus>(
                                  context: context,
                                  position: const RelativeRect.fromLTRB(200, 200, 0, 0),
                                  items: AppointmentStatus.values
                                      .map(
                                        (s) => PopupMenuItem(
                                          value: s,
                                          child: Row(
                                            children: [
                                              Icon(Icons.circle, color: s.color, size: 12),
                                              const SizedBox(width: 8),
                                              Text(s.label),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                                if (newStatus != null) {
                                  setState(() => _updateInEvents(a.copyWith(status: newStatus)));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    // ✅ 웹/와이드에선 드로어 폭만큼 공간을 항상 비워서 겹침 방지 (딤은 Scaffold가 처리)
    return SafeArea(
      child: isWide
          ? Row(
              children: [
                SizedBox(width: reserved),
                Expanded(child: calendarBody),
              ],
            )
          : calendarBody,
    );
  }
}

/// 일정 생성/수정 바텀시트 (변경 없음)
class _AppointmentEditor extends StatefulWidget {
  final Appointment? existing;
  final DateTime? date;
  const _AppointmentEditor({this.existing, this.date});
  @override
  State<_AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends State<_AppointmentEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtr;
  late TextEditingController _patientCtr;
  late TextEditingController _locationCtr;
  late TextEditingController _notesCtr;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  AppointmentStatus _status = AppointmentStatus.pending;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtr = TextEditingController(text: e?.title ?? '');
    _patientCtr = TextEditingController(text: e?.patientName ?? '');
    _locationCtr = TextEditingController(text: e?.location ?? '');
    _notesCtr = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? widget.date ?? DateTime.now();
    _start = e?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _end = e?.endTime ?? const TimeOfDay(hour: 9, minute: 30);
    _status = e?.status ?? AppointmentStatus.pending;
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _patientCtr.dispose();
    _locationCtr.dispose();
    _notesCtr.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final startDT = DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endDT = DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute);
    if (!endDT.isAfter(startDT)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('종료시간은 시작시간 이후여야 합니다.')));
      return;
    }

    final id = widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final result = Appointment(
      id: id,
      title: _titleCtr.text.trim(),
      patientName: _patientCtr.text.trim().isEmpty ? null : _patientCtr.text.trim(),
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: _start,
      endTime: _end,
      status: _status,
      location: _locationCtr.text.trim().isEmpty ? null : _locationCtr.text.trim(),
      notes: _notesCtr.text.trim().isEmpty ? null : _notesCtr.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  void _delete() {
    if (widget.existing == null) return;
    Navigator.of(context).pop(widget.existing!.copyWith(title: '__DELETE__'));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final dateFmt = DateFormat('yyyy.MM.dd (E)', 'ko_KR');
    final hm = DateFormat('HH:mm');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Text(isEdit ? '일정 수정' : '새 일정',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (isEdit)
                      IconButton(
                        onPressed: _delete,
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtr,
                        decoration: const InputDecoration(
                          labelText: '제목 *',
                          hintText: '예) 충치 치료, 임플란트 상담 등',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '제목을 입력하세요.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _patientCtr,
                        decoration: const InputDecoration(
                          labelText: '환자명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '날짜',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(dateFmt.format(_date)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickStart,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '시작',
                                  border: OutlineInputBorder(),
                                ),
                                child:
                                    Text(hm.format(DateTime(0, 1, 1, _start.hour, _start.minute))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickEnd,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: '종료',
                                  border: OutlineInputBorder(),
                                ),
                                child:
                                    Text(hm.format(DateTime(0, 1, 1, _end.hour, _end.minute))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AppointmentStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: '상태',
                          border: OutlineInputBorder(),
                        ),
                        items: AppointmentStatus.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, size: 12, color: s.color),
                                    const SizedBox(width: 8),
                                    Text(s.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationCtr,
                        decoration: const InputDecoration(
                          labelText: '위치(진료실 등)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtr,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '메모',
                          hintText: '주의사항, 준비물 등',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(isEdit ? '저장' : '등록'),
                          onPressed: _submit,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
