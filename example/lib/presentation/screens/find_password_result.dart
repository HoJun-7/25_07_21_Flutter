import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FindPasswordResultScreen extends StatelessWidget {
  const FindPasswordResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: const Text('비밀번호 찾기 결과', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5F97F7),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints:
                  kIsWeb ? const BoxConstraints(maxWidth: 450) : const BoxConstraints(),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/tooth_character.png', height: 150),
                    const SizedBox(height: 30),
                    const Icon(Icons.mark_email_read, size: 80, color: Color(0xFF5F97F7)),
                    const SizedBox(height: 30),
                    const Text(
                      '비밀번호 재설정 링크가\n이메일로 전송되었습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            return states.contains(WidgetState.pressed)
                                ? Colors.white
                                : const Color(0xFF5F97F7);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            return states.contains(WidgetState.pressed)
                                ? const Color(0xFF5F97F7)
                                : Colors.white;
                          }),
                          elevation: WidgetStateProperty.all(5),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        child: const Text(
                          '로그인 화면으로 돌아가기',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
