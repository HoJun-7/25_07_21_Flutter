import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsultResultScreen extends StatelessWidget {
  final String? type; // 'apply' or 'cancel'

  const ConsultResultScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final isCancel = type == 'cancel';

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        title: Text(
          isCancel ? "신청 취소 완료" : "진료 신청 결과",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3869A8),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCancel ? Icons.cancel : Icons.check_circle,
                color: const Color(0xFF3869A8),
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                isCancel
                    ? '진단 신청이 취소되었습니다.'
                    : '진료 신청이 완료되었습니다!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                isCancel
                    ? '해당 신청은 더 이상 진행되지 않습니다.'
                    : '담당 의사가 확인 후 빠르게\n진료를 진행해드릴 예정입니다.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => context.pushReplacement('/history'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3869A8),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '진료 기록 돌아가기',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}