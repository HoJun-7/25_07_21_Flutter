import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'd_calendar_placeholder.dart';

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
  final DateTime date; // 날짜(일 단위)
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

  DateTime get startDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );

  DateTime get endDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

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

  // 달력 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 일정 저장소 (날짜별 그룹)
  final Map<DateTime, List<Appointment>> _events = {};

  // 필터
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
    _seedSample(); // 샘플 데이터 (원치 않으면 제거)
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

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

  void _deleteFromEvents(String id) {
    for (final entry in _events.entries.toList()) {
      _events[entry.key] = entry.value.where((e) => e.id != id).toList();
      if (_events[entry.key]!.isEmpty) _events.remove(entry.key);
    }
    setState(() {});
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

  Future<void> _pickAdd() async {
    final created = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AppointmentEditor(
        date: _selectedDay ?? _normalize(DateTime.now()),
      ),
    );
    if (created != null) {
      setState(() => _addToEvents(created));
    }
  }

  Future<void> _pickEdit(Appointment appt) async {
    final edited = await showModalBottomSheet<Appointment?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AppointmentEditor(existing: appt),
    );
    if (edited == null) return;
    if (edited.title == '__DELETE__') {
      _deleteFromEvents(appt.id);
    } else {
      setState(() => _updateInEvents(edited));
    }
  }

  Widget _buildFilters() {
    final chips = AppointmentStatus.values.map((s) {
      final selected = _selectedStatuses.contains(s);
      return FilterChip(
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
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ...chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)),
          const SizedBox(width: 8),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchCtr,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: '이름/제목/위치/메모 검색',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay ?? _normalize(DateTime.now());
    final dayEvents = _eventsForDay(selectedDay);

    return Scaffold(
      // 🔹 AppBar 제거됨 — 부모 Scaffold가 TopBar를 담당
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAdd,
        label: const Text('새 일정'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // 캘린더
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
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = _normalize(selected);
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) {
                    _focusedDay = focused;
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildFilters(),
          const SizedBox(height: 8),
          // 일자별 일정 목록
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
                                    Text(
                                      a.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
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
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
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
                                    position: RelativeRect.fromLTRB(200, 200, 0, 0),
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
      ),
    );
  }
}

/// 일정 생성/수정 바텀시트
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('종료시간은 시작시간 이후여야 합니다.')));
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
                    Text(
                      isEdit ? '일정 수정' : '새 일정',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요.' : null,
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
                                child: Text(hm.format(DateTime(0, 1, 1, _start.hour, _start.minute))),
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
                                child: Text(hm.format(DateTime(0, 1, 1, _end.hour, _end.minute))),
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
