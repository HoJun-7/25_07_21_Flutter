import 'package:flutter/material.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  // 예시 환자 데이터
  final List<Map<String, dynamic>> patients = const [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 목록'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.separated(
        itemCount: patients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = patients[index];
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
              // TODO: 환자 상세 페이지로 이동 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${patient['name']} 상세보기 준비 중')),
              );
            },
          );
        },
      ),
    );
  }
}