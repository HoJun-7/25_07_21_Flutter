import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'presentation/viewmodel/clinics_viewmodel.dart';
import 'presentation/viewmodel/userinfo_viewmodel.dart';
import 'services/router.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/history_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import 'presentation/viewmodel/doctor/d_history_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart'; // ✅ 유지
import '/presentation/viewmodel/chatbot_viewmodel.dart'; // ✅ 추가
import 'my_http_overrides.dart'; // ✅ https
import 'package:flutter/foundation.dart'; // ✅ https, kIsWeb
import 'dart:io' if (dart.library.html) 'stub.dart'; // ✅ https, HttpOverrides (웹 회피)

import 'core/theme/app_theme.dart';

// ======================= ▼ 추가: 로케일/intl 초기화 관련 =======================
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ 로컬라이제이션 델리게이트
import 'package:intl/intl.dart'; // ✅ Intl.defaultLocale
import 'package:intl/date_symbol_data_local.dart'; // ✅ initializeDateFormatting
// ============================================================================

// ================ ▼ ① Google Fonts 런타임 다운로드 금지 (추가된 부분) ================
import 'package:google_fonts/google_fonts.dart';
// ============================================================================

Future<void> main() async {
  // --------------------- ▼ intl 로케일 초기화 (에러 원인 해결) ---------------------
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ko_KR';
  await initializeDateFormatting('ko_KR', null);
  // -----------------------------------------------------------------------------

  // --------------------- ▼ ① Google Fonts 런타임 다운로드 금지 ---------------------
  // 폰트를 assets로 번들한 상태에서 런타임 네트워크 페치 비활성화
  GoogleFonts.config.allowRuntimeFetching = false;
  // -----------------------------------------------------------------------------

  //const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //A100 서버
  // const String globalBaseUrl = "https://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //flutter build Web 할때
  // const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; 
  const String globalBaseUrl = "http://192.168.0.19:5000/api"; // 학원pc

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
          create: (_) => HistoryViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorHistoryViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorDashboardViewModel(), // ✅ 단 하나만 등록
        ),
        // ✅ ChatbotViewModel 등록 부분을 ChangeNotifierProxyProvider로 변경
        ChangeNotifierProxyProvider<AuthViewModel, ChatbotViewModel>(
          // AuthViewModel이 변경될 때 ChatbotViewModel을 생성/업데이트
          create: (context) => ChatbotViewModel(
            baseUrl: globalBaseUrl,
            authViewModel: context.read<AuthViewModel>(), // AuthViewModel 주입
          ),
          update: (context, authViewModel, previousChatbotViewModel) {
            // 대부분의 경우 이전 인스턴스를 반환하면 됩니다.
            return previousChatbotViewModel ??
                ChatbotViewModel(
                  baseUrl: globalBaseUrl,
                  authViewModel: authViewModel,
                );
          },
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

      // ================= ▼ 추가: 로케일 설정 (TableCalendar/DatePicker/Intl 모두 OK) =================
      locale: const Locale('ko', 'KR'), // ✅ 기본 로케일
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,   // ✅ 머티리얼 위젯 현지화
        GlobalWidgetsLocalizations.delegate,    // ✅ 기본 위젯 현지화
        GlobalCupertinoLocalizations.delegate,  // ✅ 쿠퍼티노 위젯 현지화
      ],
      // ================================================================================================
    );
  }
}