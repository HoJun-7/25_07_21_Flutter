import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsultResultScreen extends StatelessWidget {
  const ConsultResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        title: const Text("진료 신청 결과", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3869A8),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF3869A8), size: 80),
              const SizedBox(height: 20),
              const Text(
                '진료 신청이 완료되었습니다!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                '담당 의사가 확인 후 빠르게\n진료를 진행해드릴 예정입니다.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3869A8),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('홈으로 돌아가기', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
