import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Provider is used for ChangeNotifierProvider

// 필요한 화면들 임포트
import '/presentation/screens/doctor/d_inference_result_screen.dart';
import '/presentation/screens/doctor/d_real_home_screen.dart'; // 의사 첫 홈
import '/presentation/screens/doctor/d_telemedicine_application_screen.dart'; // 새로 추가된 비대면 진료 신청 화면
import '/presentation/screens/doctor/d_calendar_screen.dart';
import '/presentation/screens/main_scaffold.dart'; // 일반 사용자용 스캐폴드
import '/presentation/screens/login_screen.dart';
import '/presentation/screens/register_screen.dart';
import '/presentation/screens/home_screen.dart';
import '/presentation/screens/camera_inference_screen.dart';
import '/presentation/screens/web_placeholder_screen.dart';
import '/presentation/screens/telemedicine_apply_screen.dart';
import '/presentation/viewmodel/auth_viewmodel.dart'; // 사용자 로그인 정보 접근

// 하단 탭 바 화면들
import '/presentation/screens/chatbot_screen.dart';
import '/presentation/screens/mypage_screen.dart';
import '/presentation/screens/upload_screen.dart';
import '/presentation/screens/history_screen.dart';
import '/presentation/screens/clinics_screen.dart';

// DoctorDrawer는 반드시 이 경로에서만 임포트합니다.
import '/presentation/screens/doctor/doctor_drawer.dart';

// DoctorDashboardViewModel은 이 경로에서만 임포트합니다.
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart'; // ViewModel의 정식 경로

GoRouter createRouter(String baseUrl) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(baseUrl: baseUrl),
      ),
      GoRoute(
        path: '/register',
<<<<<<< HEAD
        // baseUrl 매개변수를 RegisterScreen에 전달합니다.
        builder: (context, state) => RegisterScreen(baseUrl: baseUrl),
=======
        builder: (context, state) => const RegisterScreen(),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
      ),
      GoRoute(
        path: '/web',
        builder: (context, state) => const WebPlaceholderScreen(),
      ),

      // 의사 전용 ShellRoute: Drawer 유지
      ShellRoute(
        builder: (context, state, child) {
          // DRealHomeScreen, DTelemedicineApplicationScreen 등 각 화면에서 Scaffold 및 DoctorDrawer를 직접 처리합니다.
          // 여기서 ShellRoute의 builder는 단순히 child를 반환하여 하위 라우트에서 Scaffold를 구성할 수 있도록 합니다.
          return child;
        },
        routes: [
          GoRoute(
            path: '/d_home',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return ChangeNotifierProvider(
                create: (_) => DoctorDashboardViewModel(),
                child: DRealHomeScreen(baseUrl: passedBaseUrl),
              );
            },
          ),

          GoRoute(
            path: '/d_dashboard',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final passedBaseUrl = extra['baseUrl'] as String? ?? baseUrl;
              final initialTab = extra['initialTab'] as int? ?? 0;
              return DTelemedicineApplicationScreen(
                baseUrl: passedBaseUrl,
                initialTab: initialTab,
              );
            },
          ),

          GoRoute(
            path: '/d_appointments',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return Scaffold(
                appBar: AppBar(title: const Text('예약 현황')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl),
                body: const Center(child: Text('예약 현황 화면입니다.')),
              );
            },
          ),

          GoRoute(
            path: '/d_inference_result',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return Scaffold(
                appBar: AppBar(title: const Text('진료 결과')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl),
                body: DInferenceResultScreen(baseUrl: passedBaseUrl),
              );
            },
          ),

          GoRoute(
            path: '/d_calendar',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return Scaffold(
                appBar: AppBar(title: const Text('진료 캘린더')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl),
<<<<<<< HEAD
                // DCalendarScreen은 baseUrl 매개변수가 필요 없으므로 제거
=======
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                body: const DCalendarScreen(),
              );
            },
          ),

          GoRoute(
            path: '/d_patients',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return Scaffold(
                appBar: AppBar(title: const Text('환자 목록')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl),
                body: const Center(child: Text('환자 목록 화면입니다.')),
              );
            },
          ),
        ],
      ),

      // 일반 사용자 ShellRoute
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(
            child: child,
            currentLocation: state.uri.toString(),
          );
        },
        routes: [
          GoRoute(
            path: '/chatbot',
            builder: (context, state) => const ChatbotScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) {
              final authViewModel = state.extra as Map<String, dynamic>?; // 예시
              final userId = authViewModel?['userId'] ?? 'guest';
              return HomeScreen(baseUrl: baseUrl, userId: userId);
            },
          ),
          GoRoute(
            path: '/mypage',
            builder: (context, state) => const MyPageScreen(),
          ),
          GoRoute(
            path: '/upload',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return UploadScreen(baseUrl: passedBaseUrl);
            },
          ),
          GoRoute(
            path: '/diagnosis/realtime',
            builder: (context, state) {
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              final currentUser = authViewModel.currentUser;
              final realUserId = currentUser?.registerId ?? 'guest';
              final data = state.extra as Map<String, dynamic>? ?? {};
              final baseUrlFromData = data['baseUrl'] ?? '';
              return CameraInferenceScreen(
                baseUrl: baseUrlFromData,
                userId: realUserId,
              );
            },
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return HistoryScreen(baseUrl: passedBaseUrl);
            },
          ),
          GoRoute(
            path: '/apply',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>? ?? {};
              return TelemedicineApplyScreen(
                userId: args['userId'],
                inferenceResultId: args['inferenceResultId'],
                baseUrl: args['baseUrl'],
                diagnosisClassName: args['className'],
                confidence: args['confidence'],
                modelUsed: args['modelUsed'],
                patientName: args['name'],
                patientPhone: args['phone'],
                patientBirth: args['birth'],
              );
            },
          ),
          GoRoute(
            path: '/clinics',
            builder: (context, state) => const ClinicsScreen(),
          ),
          GoRoute(
            path: '/camera',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>? ?? {};
              return CameraInferenceScreen(
                baseUrl: data['baseUrl'] ?? '',
                userId: data['userId'] ?? 'guest',
              );
            },
          ),
        ],
      ),
    ],
  );
}