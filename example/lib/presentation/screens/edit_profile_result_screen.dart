import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⬅ 웹 폭 고정용
import 'package:go_router/go_router.dart';

class EditProfileResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const EditProfileResultScreen({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  static const Color primaryBlue = Color(0xFF3869A8);
  static const Color pageBg = Color(0xFFEAF4FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('프로필 수정 결과'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: kIsWeb
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600), // ⬅ 웹에서 폭 고정
                          child: _ResultCard(
                            isSuccess: isSuccess,
                            message: message,
                          ),
                        )
                      : _ResultCard(
                          isSuccess: isSuccess,
                          message: message,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const _ResultCard({
    required this.isSuccess,
    required this.message,
  });

  static const Color primaryBlue = Color(0xFF3F8CD4);

  @override
  Widget build(BuildContext context) {
    final Color accent = isSuccess ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 100,
            color: accent,
          ),
          const SizedBox(height: 24),

          // 타이틀
          Text(
            isSuccess ? '성공' : '실패',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),

          // 메시지
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 32),

          // 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (isSuccess) {
                  context.go('/mypage');
                } else {
                  context.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isSuccess ? '마이페이지로 돌아가기' : '다시 시도하기',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
