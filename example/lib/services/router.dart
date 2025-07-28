import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/presentation/screens/doctor/d_inference_result_screen.dart';
import '/presentation/screens/doctor/d_real_home_screen.dart';
import '/presentation/screens/doctor/d_telemedicine_application_screen.dart';
import '/presentation/screens/doctor/d_calendar_screen.dart';
import '/presentation/screens/main_scaffold.dart';
import '/presentation/screens/login_screen.dart';
import '/presentation/screens/register_screen.dart';
import '/presentation/screens/home_screen.dart';
import '/presentation/screens/camera_inference_screen.dart';
import '/presentation/screens/web_placeholder_screen.dart';
import '/presentation/screens/upload_result_detail_screen.dart';
import '/presentation/screens/history_result_detail_screen.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

import '/presentation/screens/chatbot_screen.dart';
import '/presentation/screens/mypage_screen.dart';
import '/presentation/screens/reauth_screen.dart';
import '/presentation/screens/edit_profile_screen.dart';
import '/presentation/screens/edit_profile_result_screen.dart';
import '/presentation/screens/upload_screen.dart';
import '/presentation/screens/history_screen.dart';
import '/presentation/screens/clinics_screen.dart';

import '/presentation/screens/doctor/doctor_drawer.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/screens/multimodal_response_screen.dart';

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
        builder: (context, state) => RegisterScreen(baseUrl: baseUrl),
      ),
      GoRoute(
        path: '/web',
        builder: (context, state) => const WebPlaceholderScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => child,
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

      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          child: child,
          currentLocation: state.uri.toString(),
        ),
        routes: [
          GoRoute(
            path: '/chatbot',
            builder: (context, state) => const ChatbotScreen(),
          ),
          GoRoute(
            path: '/multimodal-ressult',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final responseText = extra?['responseText'] ?? '응답이 없습니다.';
              return MultimodalResponseScreen(responseText: responseText);  // ✅ 이 부분만 multimodal로
            },
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
            path: '/reauth',
            builder: (context, state) => const ReauthScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/edit_profile_result',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return EditProfileResultScreen(
                isSuccess: extra['isSuccess'] as bool,
                message: extra['message'] as String,
              );
            },
          ),
          GoRoute(
            path: '/upload',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return UploadScreen(baseUrl: passedBaseUrl);
            },
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final passedBaseUrl = extra['baseUrl'] as String? ?? baseUrl;
              final userId = extra['userId'] as String? ?? 'guest'; // ✅ 인증된 사용자 정보도 전달

              return HistoryScreen(baseUrl: passedBaseUrl);
              // 만약 userId 도 필요하면 HistoryScreen 생성자 수정 필요
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
          GoRoute(
            path: '/upload_result_detail',
            name: 'uploadResultDetail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return UploadResultDetailScreen(
                originalImageUrl: extra['originalImageUrl'],
                processedImageUrls: Map<int, String>.from(extra['processedImageUrls']),
                modelInfos: Map<int, Map<String, dynamic>>.from(extra['modelInfos']),
                userId: extra['userId'],
                inferenceResultId: extra['inferenceResultId'],
                baseUrl: extra['baseUrl'],
              );
            },
          ),
          GoRoute(
            path: '/history_result_detail',
            name: 'historyResultDetail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return HistoryResultDetailScreen(
                originalImageUrl: extra['originalImageUrl'],
                processedImageUrls: Map<int, String>.from(extra['processedImageUrls']),
                modelInfos: Map<int, Map<String, dynamic>>.from(extra['modelInfos']),
                userId: extra['userId'],
                inferenceResultId: extra['inferenceResultId'],
                baseUrl: extra['baseUrl'],
              );
            },
          ),
        ],
      ),
    ],
  );
}