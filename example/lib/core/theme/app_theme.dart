// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // 💡 앱 전체의 기본 Scaffold 배경색을 지정
        scaffoldBackgroundColor: const Color(0xFF5F97F7), // <-- 이 부분을 변경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // <-- 이 부분도 변경하거나
          elevation: 0, // <-- 그림자도 제거
          foregroundColor: Colors.white, // <-- 텍스트/아이콘 색상도 배경에 맞게 변경
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // <-- 추가: headlineSmall 색상도 여기서 정의 가능
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // <-- 추가: titleMedium 색상도 여기서 정의 가능
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70), // <-- 추가: bodyMedium 색상도 여기서 정의 가능
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
}