import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DCalendarScreen extends StatefulWidget {
  const DCalendarScreen({super.key});

  @override
  State<DCalendarScreen> createState() => _DCalendarScreenState();
}

class _DCalendarScreenState extends State<DCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<String>> _appointments = {
    DateTime.utc(2025, 7, 17): ['홍길동 환자 진료 10:00', '김영희 환자 진료 14:00'],
    DateTime.utc(2025, 7, 18): ['이순신 환자 진료 09:00'],
  };

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  List<String> _getEventsForDay(DateTime day) {
    return _appointments[_normalizeDate(day)] ?? [];
  }

  // TODO: 예약 추가 기능 (예시)
  void _addAppointment() {
    // 실제 예약 추가 로직 구현 (예: 다이얼로그를 띄워 예약 정보 입력받기)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 추가 버튼이 눌렸습니다.')),
    );
    // 예시: 선택된 날짜에 예약 추가
    // setState(() {
    //   final normalizedSelectedDay = _normalizeDate(_selectedDay ?? _focusedDay);
    //   _appointments.update(normalizedSelectedDay, (list) {
    //     list.add('새로운 예약 ${DateTime.now().second}:00');
    //     return list;
    //   }, ifAbsent: () => ['새로운 예약 ${DateTime.now().second}:00']);
    // });
  }

  // TODO: 예약 삭제 기능 (예시)
  void _deleteAppointment() {
    // 실제 예약 삭제 로직 구현 (예: 선택된 예약을 삭제하거나, 다이얼로그를 띄워 선택)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 삭제 버튼이 눌렸습니다.')),
    );
    // 예시: 선택된 날짜의 첫 번째 예약 삭제
    // setState(() {
    //   final normalizedSelectedDay = _normalizeDate(_selectedDay ?? _focusedDay);
    //   if (_appointments.containsKey(normalizedSelectedDay) && _appointments[normalizedSelectedDay]!.isNotEmpty) {
    //     _appointments[normalizedSelectedDay]!.removeAt(0);
    //     if (_appointments[normalizedSelectedDay]!.isEmpty) {
    //       _appointments.remove(normalizedSelectedDay);
    //     }
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;

    return Scaffold(
      backgroundColor: const Color(0xFFAAD0F8), // 배경색 추가
      // 요청에 따라 AppBar 섹션 전체가 삭제되었습니다.
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(color: Colors.black),
                weekendTextStyle: TextStyle(color: Colors.black),
                outsideTextStyle: TextStyle(color: Colors.grey),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일 예약 목록',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _getEventsForDay(selectedDate).isEmpty
                ? const Center(
                    child: Text(
                      '예약이 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _getEventsForDay(selectedDate).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(selectedDate)[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(
                            event,
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            // TODO: 예약 상세 페이지로 이동
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _addAppointment,
            label: const Text('예약 추가'),
            icon: const Icon(Icons.add),
            heroTag: 'addAppointment', // Hero 애니메이션 충돌 방지
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: _deleteAppointment,
            label: const Text('예약 삭제'),
            icon: const Icon(Icons.delete),
            backgroundColor: Colors.redAccent,
            heroTag: 'deleteAppointment', // Hero 애니메이션 충돌 방지
          ),
        ],
      ),
    );
  }
}