import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FindIdResultScreen extends StatelessWidget {
  final String userId;

  const FindIdResultScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB4D4FF),
      appBar: AppBar(
        title: const Text('아이디 찾기 결과', style: TextStyle(color: Colors.white)),
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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: kIsWeb ? const BoxConstraints(maxWidth: 450) : const BoxConstraints(),
              child: Container(
                padding: const EdgeInsets.all(30),
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
                    Image.asset('assets/images/tooth_character.png', height: 140),
                    const SizedBox(height: 30),
                    const Text(
                      '찾은 아이디:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userId,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Color(0xFF3060C0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login', extra: userId),
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
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        child: const Text(
                          '로그인하러 가기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
