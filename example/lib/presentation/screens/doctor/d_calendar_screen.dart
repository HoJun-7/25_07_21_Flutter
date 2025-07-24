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

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFAAD0F8), // 배경색 추가
      appBar: AppBar(
        title: const Text('진료 캘린더', style: TextStyle(color: Colors.white)), // 타이틀 추가 및 흰색으로 변경
        centerTitle: true,
        backgroundColor: const Color(0xFF4386DB), // 파란색 배경으로 변경
        leading: Builder( // 햄버거 메뉴 아이콘 추가
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white), // 아이콘 색상 흰색으로 변경
              onPressed: () {
                // TODO: Drawer 열기 기능 추가
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
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
                // 날짜 텍스트 색상을 검은색으로 설정하여 가시성 향상
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
    );
  }
}