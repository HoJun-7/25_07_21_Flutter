import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FindIdResultScreen extends StatelessWidget {
  final String userId;

  const FindIdResultScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이디 찾기 결과')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '찾은 아이디:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              userId,
              style: const TextStyle(fontSize: 24, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                context.go('/login', extra: userId); // ✅ userId를 extra로 전달
              },
              child: const Text('로그인하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
