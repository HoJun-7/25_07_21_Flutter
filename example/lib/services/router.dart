import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Provider is used for ChangeNotifierProvider

// 필요한 화면들 임포트
import '/presentation/screens/doctor/d_inference_result_screen.dart';
import '/presentation/screens/doctor/d_real_home_screen.dart'; // 의사 첫 홈 (DoctorDrawer 포함)
import '/presentation/screens/doctor/d_telemedicine_application_screen.dart'; // ✅ 새로 추가된 비대면 진료 신청 화면
import '/presentation/screens/doctor/d_calendar_screen.dart';
import '/presentation/screens/main_scaffold.dart'; // 일반 사용자용 스캐폴드
import '/presentation/screens/login_screen.dart';
import '/presentation/screens/register_screen.dart';
import '/presentation/screens/home_screen.dart';
import '/presentation/screens/camera_inference_screen.dart';
import '/presentation/screens/web_placeholder_screen.dart';
import '/presentation/screens/telemedicine_apply_screen.dart';
import '/presentation/viewmodel/auth_viewmodel.dart'; // ✅ 사용자 로그인 정보 접근

// 하단 탭 바 화면들
import '/presentation/screens/chatbot_screen.dart';
import '/presentation/screens/mypage_screen.dart';
import '/presentation/screens/upload_screen.dart';
import '/presentation/screens/history_screen.dart';
import '/presentation/screens/clinics_screen.dart';

// DoctorDashboardViewModel은 전용 파일에서만 임포트합니다.
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
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/web',
        builder: (context, state) => const WebPlaceholderScreen(),
      ),

      // ✅ 의사 전용 ShellRoute 추가: 이 ShellRoute 내의 모든 화면은 Drawer를 유지합니다.
      ShellRoute(
        builder: (context, state, child) {
          return child; // 자식 위젯을 그대로 반환
        },
        routes: [
          // ✅ 의사 로그인 후 메인 홈
          GoRoute(
            path: '/d_home',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return ChangeNotifierProvider(
                create: (_) => DoctorDashboardViewModel(),
                // DRealHomeScreen은 이미 DoctorDrawer를 포함하고 있습니다.
                child: DRealHomeScreen(baseUrl: passedBaseUrl),
              );
            },
          ),

          // ✅ 의사 메뉴: 비대면 진료 신청 화면 (이제 별도 파일로 분리)
          GoRoute(
            path: '/d_dashboard',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final passedBaseUrl = extra['baseUrl'] as String? ?? baseUrl; // ✅ 수정 완료
              final initialTab = extra['initialTab'] as int? ?? 0;
              return DTelemedicineApplicationScreen(
                baseUrl: passedBaseUrl,
                initialTab: initialTab,
              );
            },
          ),
          // ✅ 의사 메뉴: 예약 현황
          GoRoute(
            path: '/d_appointments',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              // TODO: 실제 예약 현황 화면 위젯으로 교체하세요. (이 화면도 Scaffold를 포함하고 DoctorDrawer를 사용해야 합니다.)
              return Scaffold(
                appBar: AppBar(title: const Text('예약 현황')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl), // DoctorDrawer 적용
                body: const Center(child: Text('예약 현황 화면입니다.')),
              );
            },
          ),

          // ✅ 의사 메뉴: 진료 결과 (기존 DInferenceResultScreen을 재사용하거나, 필요시 별도 화면 생성)
          GoRoute(
            path: '/d_inference_result',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              // DInferenceResultScreen에 Drawer를 추가해야 합니다.
              // 현재 DInferenceResultScreen의 코드를 알 수 없으므로,
              // 임시로 Scaffold로 감싸고 DoctorDrawer를 추가합니다.
              // 실제 DInferenceResultScreen 파일에서 Scaffold와 Drawer를 구현해야 합니다.
              return Scaffold(
                appBar: AppBar(title: const Text('진료 결과')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl), // DoctorDrawer 적용
                body: DInferenceResultScreen(baseUrl: passedBaseUrl),
              );
            },
          ),

          // ✅ 의사 메뉴: 진료 캘린더
          GoRoute(
            path: '/d_calendar',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return Scaffold(
                appBar: AppBar(title: const Text('진료 캘린더')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl),
                body: const DCalendarScreen(), // ✅ 실제 달력 화면 연결
              );
            },
          ),

          // ✅ 의사 메뉴: 환자 목록
          GoRoute(
            path: '/d_patients',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              // TODO: 실제 환자 목록 화면 위젯으로 교체하세요. (이 화면도 Scaffold를 포함하고 DoctorDrawer를 사용해야 합니다.)
              return Scaffold(
                appBar: AppBar(title: const Text('환자 목록')),
                drawer: DoctorDrawer(baseUrl: passedBaseUrl), // DoctorDrawer 적용
                body: const Center(child: Text('환자 목록 화면입니다.')),
              );
            },
          ),
        ],
      ),

      // ✅ 일반 사용자 ShellRoute (기존 유지)
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
              final authViewModel = state.extra as Map<String, dynamic>?;
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
              // ✅ 로그인된 사용자 정보 가져오기
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              final currentUser = authViewModel.currentUser;
              final realUserId = currentUser?.registerId ?? 'guest'; // ← 여기서 선언
              // ✅ 전달된 baseUrl만 extra로 받기
              final data = state.extra as Map<String, dynamic>? ?? {};
              final baseUrl = data['baseUrl'] ?? '';
              return CameraInferenceScreen(
                baseUrl: baseUrl,
                userId: realUserId, // ✅ 정상 전달
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
