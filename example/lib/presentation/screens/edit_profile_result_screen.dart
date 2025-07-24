import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditProfileResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const EditProfileResultScreen({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정 결과'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 100,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? '성공' : '실패',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (isSuccess) {
                    context.go('/mypage');
                  } else {
                    context.pop(); // 다시 edit_profile_screen.dart로 돌아감
                  }
                },
                child: Text(isSuccess ? '마이페이지로 돌아가기' : '다시 시도하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
