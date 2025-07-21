//C:\Users\302-1\Desktop\yolo-flutter-app\example\lib\presentation\screens\web_placeholder_screen.dart
import 'package:flutter/material.dart';

class WebPlaceholderScreen extends StatelessWidget {
  const WebPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          '이 기능은 웹에서는 지원되지 않습니다.\n모바일에서 실행해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
