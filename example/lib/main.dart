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
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'my_http_overrides.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'stub.dart';

import 'core/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:google_fonts/google_fonts.dart';

// ✅ 추가된 import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '/presentation/screens/message_page.dart';
import '/presentation/screens/home_page.dart';
import '/services/local_push_notification.dart';

// ✅ navigatorKey 및 알림 플러그인
final navigatorKey = GlobalKey<NavigatorState>();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ko_KR';
  await initializeDateFormatting('ko_KR', null);

  GoogleFonts.config.allowRuntimeFetching = false;

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

  // ✅ 로컬 푸시 알림 초기화
  await LocalPushNotifications.init();

  // ✅ 앱이 종료된 상태에서 푸시 알림을 탭했을 때
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    Future.delayed(const Duration(seconds: 1), () {
      navigatorKey.currentState!.pushNamed(
        '/message',
        arguments: notificationAppLaunchDetails?.notificationResponse?.payload,
      );
    });
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
          create: (_) => DoctorDashboardViewModel(),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, ChatbotViewModel>(
          create: (context) => ChatbotViewModel(
            baseUrl: globalBaseUrl,
            authViewModel: context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previousChatbotViewModel) {
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
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ 알림 라우팅을 위해 navigatorKey 적용
      title: 'MediTooth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/': (context) => SplashScreen(baseUrl: baseUrl),
        '/message': (context) => const MessagePage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

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

    // 2초 후 MaterialApp.router 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MaterialApp.router(
            title: 'MediTooth',
            debugShowCheckedModeBanner: false,
            routerConfig: createRouter(widget.baseUrl),
            theme: AppTheme.lightTheme,
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      );
    });
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
