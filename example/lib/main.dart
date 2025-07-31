import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodel/clinics_viewmodel.dart';
import 'presentation/viewmodel/userinfo_viewmodel.dart';
import 'services/router.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_consultation_record_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart'; // ✅ 유지
import '/presentation/viewmodel/chatbot_viewmodel.dart'; // ✅ 추가
import 'my_http_overrides.dart'; // ✅ https
import 'package:flutter/foundation.dart';        // ✅ https, kIsWeb
import 'dart:io' if (dart.library.html) 'stub.dart'; // ✅ https, HttpOverrides (웹 회피)

import 'core/theme/app_theme.dart';

void main() {
  const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api";
  // "https://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; flutter build web 할때
  // "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; A100 서버
  // "http://192.168.0.19:5000/api"; 학원pc
  // "https://bc0d6ba8d2d1.ngrok-free.app/api"; 집컴
  
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides(); // ✅ 웹이 아닐 때만 실행
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => UserInfoViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DPatientViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => ClinicsViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsultationRecordViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorDashboardViewModel(), // ✅ 단 하나만 등록
        ),
        ChangeNotifierProvider( // ✅ ChatbotViewModel 등록
          create: (_) => ChatbotViewModel(baseUrl: globalBaseUrl),
        ),
      ],
      child: YOLOExampleApp(baseUrl: globalBaseUrl),
    ),
  );
}

class YOLOExampleApp extends StatelessWidget {
  final String baseUrl;

  const YOLOExampleApp({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MediTooth',
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(baseUrl),
      theme: AppTheme.lightTheme,
    );
  }
}
