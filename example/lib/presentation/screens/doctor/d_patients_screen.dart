import 'package:flutter/material.dart';
import '/presentation/screens/doctor/d_patients_screen.dart';

class DPatientsScreen extends StatefulWidget {
  final String baseUrl;
  const DPatientsScreen({super.key, required this.baseUrl});

  @override
  State<DPatientsScreen> createState() => _DPatientsScreenState();
}

class _DPatientsScreenState extends State<DPatientsScreen> {
  // 예시 환자 데이터
  final List<Map<String, dynamic>> patients = [
    {
      'name': '홍길동',
      'lastVisit': '2025-07-15',
      'age': 29,
      'phone': '010-1234-5678',
    },
    {
      'name': '김영희',
      'lastVisit': '2025-07-10',
      'age': 34,
      'phone': '010-9876-5432',
    },
    {
      'name': '이순신',
      'lastVisit': '2025-06-28',
      'age': 45,
      'phone': '010-5555-5555',
    },
  ];

  String searchQuery = '';
  String sortCriteria = '최근 방문순';

  // 검색 필터링
  List<Map<String, dynamic>> get filteredPatients {
    if (searchQuery.isEmpty) return patients;
    return patients
        .where((p) => p['name'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  // 정렬 적용
  List<Map<String, dynamic>> get sortedPatients {
    List<Map<String, dynamic>> list = filteredPatients;
    if (sortCriteria == '이름순') {
      list.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (sortCriteria == '최근 방문순') {
      list.sort((a, b) => DateTime.parse(b['lastVisit']).compareTo(DateTime.parse(a['lastVisit'])));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 목록'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '환자 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),

          // 정렬 기준 선택
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('정렬 기준:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: sortCriteria,
                  items: ['최근 방문순', '이름순']
                      .map((criteria) => DropdownMenuItem(
                            value: criteria,
                            child: Text(criteria),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        sortCriteria = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 환자 리스트
          Expanded(
            child: sortedPatients.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : ListView.separated(
                    itemCount: sortedPatients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final patient = sortedPatients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade300,
                          child: Text(
                            patient['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(patient['name']),
                        subtitle: Text('최근 방문: ${patient['lastVisit']}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DPatientDetailScreen(patient: patient),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DPatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;
  const DPatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient['name']),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이름: ${patient['name']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('나이: ${patient['age']}세', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('전화번호: ${patient['phone']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('최근 방문: ${patient['lastVisit']}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}