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

  //const String globalBaseUrl = "http://127.0.0.1:5000/api";
  //const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //A100 서버
  // const String globalBaseUrl = "https://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; //flutter build Web 할때
  // const String globalBaseUrl = "http://ayjsdtzsnbrsrgfj.tunnel.elice.io/api"; 
  // const String globalBaseUrl = "http://192.168.0.19:5000/api"; // 학원pc
  //const String globalBaseUrl = "http://192.168.0.19:5000/api"; //JH_computer 기준 학원 주소 
  const String globalBaseUrl = "http://192.168.0.48:5000/api"; //HJ_computer 기준 학원 주소
  //const String globalBaseUrl = "http://192.168.0.15:5000/api"; //HJ_computer 기준 집 주소

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

// ▼▼▼ 위쪽 코드의 SplashScreen 이식 (애니메이션 포함) ▼▼▼

class SplashScreen extends StatefulWidget {
  final String baseUrl;
  const SplashScreen({super.key, required this.baseUrl});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 흔들림/확대 축소
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 깜빡임 효과
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Image.asset(
              'assets/logo.png', // 앱 로고 경로
              width: 150,
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
}

// ▼▼▼ 아래쪽 코드 구조 유지: 단, 스플래시 → 라우터 전환을 YOLOExampleApp 내부에서 처리 ▼▼▼

class YOLOExampleApp extends StatefulWidget {
  final String baseUrl;

  const YOLOExampleApp({super.key, required this.baseUrl});

  @override
  State<YOLOExampleApp> createState() => _YOLOExampleAppState();
}

class _YOLOExampleAppState extends State<YOLOExampleApp>
    with SingleTickerProviderStateMixin {
  bool _showRouter = false;

  @override
  void initState() {
    super.initState();
    // 2초 후 MaterialApp.router 화면으로 전환
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showRouter = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showRouter) {
      // 스플래시 구간: MaterialApp로 감싸 동일한 테마/로케일을 적용
      return MaterialApp(
        title: 'MediTooth',
        debugShowCheckedModeBanner: false,
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
        home: SplashScreen(baseUrl: widget.baseUrl),
      );
    }

    // 스플래시 종료 후: 기존 아래쪽 코드의 MaterialApp.router 그대로 반환
    return MaterialApp.router(
      title: 'MediTooth',
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(widget.baseUrl),
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