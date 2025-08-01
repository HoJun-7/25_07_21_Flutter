import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

class DCalendarScreen extends StatefulWidget {
  const DCalendarScreen({super.key});

  @override
  State<DCalendarScreen> createState() => _DCalendarScreenState();
}

class _DCalendarScreenState extends State<DCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 테스트용 예약 데이터. 실제 앱에서는 백엔드에서 데이터를 불러올 것입니다.
  final Map<DateTime, List<String>> _appointments = {
    DateTime.utc(2025, 7, 17): ['오전 10:00 홍길동 환자 진료', '오후 2:00 김영희 환자 진료'],
    DateTime.utc(2025, 7, 18): ['오전 09:00 이순신 환자 진료'],
    DateTime.utc(2025, 7, 30): ['오전 11:30 박철수 환자 상담'], // 오늘 날짜 예약 추가
  };

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  List<String> _getEventsForDay(DateTime day) {
    return _appointments[_normalizeDate(day)] ?? [];
  }

  void _addAppointment() {
    // 실제 예약 추가 로직을 구현할 곳
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 추가 화면으로 이동합니다.')),
    );
    // 예: context.go('/add_appointment_screen');
  }

  void _deleteAppointment() {
    // 실제 예약 삭제 로직을 구현할 곳
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 삭제 기능을 구현해야 합니다.')),
    );
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _selectedDay = _normalizeDate(DateTime.now()); // 초기 선택 날짜를 오늘로 설정
  }

  @override
  Widget build(BuildContext context) {
    // _selectedDay가 null이 아님을 보장 (initState에서 초기화했으므로)
    final selectedDateForDisplay = _selectedDay!;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/d_home');
        }
      },
      child: Container( // ✨ 전체 화면의 배경색을 위한 Container 추가
        color: const Color(0xFFE3F2FD), // 연한 하늘색 배경 (기존의 푸른색 계열과 잘 어울림)
        child: Column(
          children: [
            // 캘린더 컨테이너는 그대로 유지합니다.
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8), // 내부 패딩 조정
              decoration: BoxDecoration(
                color: Colors.white, // 달력 부분의 배경색을 흰색으로 유지
                borderRadius: BorderRadius.circular(16), // 모서리 둥글기 증가
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // 그림자 강도 조정
                    blurRadius: 15, // 그림자 블러 증가
                    offset: const Offset(0, 6), // 그림자 위치 조정
                  ),
                ],
              ),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = _normalizeDate(selectedDay); // 선택된 날짜도 정규화
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFC7E0FF), // 오늘 날짜 배경색 (라이트 블루)
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Color(0xFF3869A8), // 오늘 날짜 텍스트 색상
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF3869A8), // 선택된 날짜 배경색 (진한 블루)
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white, // 선택된 날짜 텍스트 색상
                    fontWeight: FontWeight.bold,
                  ),
                  defaultDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  weekendDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.redAccent, // 이벤트 마커 색상
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.black87),
                  weekendTextStyle: TextStyle(color: Colors.black54),
                  outsideTextStyle: TextStyle(color: Colors.grey),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w700, // 더 굵게
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.w700, // 더 굵게
                    fontSize: 14,
                    color: Colors.black54, // 주말 텍스트 색상 약간 어둡게
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final text = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7]; // 한글 요일
                    Color textColor = Colors.black87;

                    if (day.weekday == DateTime.sunday) {
                      textColor = Colors.redAccent; // 일요일 빨간색
                    } else if (day.weekday == DateTime.saturday) {
                      textColor = Colors.blueAccent; // 토요일 파란색
                    }

                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 4, // 마커 위치 조정
                        child: Container(
                          width: 5, // 마커 크기 조정
                          height: 5, // 마커 크기 조정
                          decoration: const BoxDecoration(
                            color: Colors.red, // 더 진한 빨강
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
                  titleTextStyle: TextStyle(
                    fontSize: 20, // 헤더 타이틀 폰트 크기
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3869A8), // 헤더 타이틀 색상
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF3869A8)),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF3869A8)),
                  headerPadding: EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${selectedDateForDisplay.year}년 ${selectedDateForDisplay.month}월 ${selectedDateForDisplay.day}일 예약 목록',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _getEventsForDay(selectedDateForDisplay).isEmpty
                  ? const Center(
                      child: Text(
                        '선택된 날짜에 예약이 없습니다.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _getEventsForDay(selectedDateForDisplay).length,
                      itemBuilder: (context, index) {
                        final event = _getEventsForDay(selectedDateForDisplay)[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            leading: const Icon(
                              Icons.event,
                              color: Color(0xFF3869A8),
                              size: 28,
                            ),
                            title: Text(
                              event,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$event 예약이 삭제될 예정입니다.')),
                                );
                              },
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$event 상세 정보 보기')),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}




