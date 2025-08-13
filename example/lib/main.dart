import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:intl/date_symbol_data_local.dart'; // ✅ 로케일 데이터
import 'package:intl/intl.dart';                   // ✅ 기본 로케일 설정용
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ 위젯 한글화

import 'presentation/viewmodel/clinics_viewmodel.dart';
import 'presentation/viewmodel/userinfo_viewmodel.dart';
import 'services/router.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/history_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import 'presentation/viewmodel/doctor/d_history_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'my_http_overrides.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'stub.dart';

import 'core/theme/app_theme.dart';

Future<void> main() async {
  // ✅ Flutter 바인딩 + 로케일 데이터 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  Intl.defaultLocale = 'ko_KR'; // (선택) DateFormat 기본 로케일

  //const String globalBaseUrl = "http://127.0.0.1:5000/api";
  const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //A100 서버
  // const String globalBaseUrl = "https://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //flutter build Web 할때
  // const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; 
  // const String globalBaseUrl = "http://192.168.0.19:5000/api"; // 학원pc
  //const String globalBaseUrl = "http://192.168.0.19:5000/api"; //JH_computer 기준 학원 주소 
  //const String globalBaseUrl = "http://192.168.0.48:5000/api"; //HJ_computer 기준 학원 주소
  //const String globalBaseUrl = "http://192.168.0.15:5000/api"; //HJ_computer 기준 집 주소

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (_) => UserInfoViewModel()),
        ChangeNotifierProvider(create: (_) => DPatientViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (_) => ClinicsViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (_) => DoctorHistoryViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (_) => DoctorDashboardViewModel()),
        ChangeNotifierProxyProvider<AuthViewModel, ChatbotViewModel>(
          create: (context) => ChatbotViewModel(
            baseUrl: globalBaseUrl,
            authViewModel: context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previous) =>
              previous ?? ChatbotViewModel(baseUrl: globalBaseUrl, authViewModel: authViewModel),
        ),
      ],
      child: const YOLOExampleApp(baseUrl: globalBaseUrl),
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

      // ✅ 한글 로컬라이제이션
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
