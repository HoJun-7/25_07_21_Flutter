import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Screens
import '/presentation/screens/doctor/d_real_home_screen.dart';
import '/presentation/screens/doctor/d_telemedicine_application_screen.dart';
import '/presentation/screens/doctor/d_result_detail_screen.dart';
import '/presentation/screens/doctor/d_calendar_screen.dart';
import '/presentation/screens/doctor/doctor_drawer.dart';
import '/presentation/screens/main_scaffold.dart';
import '/presentation/screens/login_screen.dart';
import '/presentation/screens/register_screen.dart';
import '/presentation/screens/home_screen.dart';
import '/presentation/screens/camera_inference_screen.dart';
import '/presentation/screens/web_placeholder_screen.dart';
import '/presentation/screens/consult_result.dart';
import '/presentation/screens/upload_result_detail_screen.dart';
import '/presentation/screens/upload_xray_result_detail_screen.dart'; // ✅ 추가
import '/presentation/screens/history_result_detail_screen.dart';
import '/presentation/screens/history_xray_result_detail_screen.dart'; // ✅ 추가
import '/presentation/screens/multimodal_response_screen.dart';
import '/presentation/screens/chatbot_screen.dart';
import '/presentation/screens/mypage_screen.dart';
import '/presentation/screens/reauth_screen.dart';
import '/presentation/screens/edit_profile_screen.dart';
import '/presentation/screens/edit_profile_result_screen.dart';
import '/presentation/screens/dental_survey_screen.dart';
import '/presentation/screens/upload_screen.dart';
import '/presentation/screens/history_screen.dart';
import '/presentation/screens/clinics_screen.dart';
import '/presentation/screens/find_id_screen.dart';
import '/presentation/screens/find_id_result.dart';
import '/presentation/screens/find_password_screen.dart';
import '/presentation/screens/find_password_result.dart';
import '/presentation/screens/agreement_screen.dart'; // ✅ 약관 동의 추가

// ViewModels
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/viewmodel/find_id_viewmodel.dart';

GoRouter createRouter(String baseUrl) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(baseUrl: baseUrl),
      ),
      GoRoute(
        path: '/agreement',
        builder: (context, state) => AgreementScreen(baseUrl: baseUrl),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(baseUrl: baseUrl),
      ),
      GoRoute(
        path: '/find_id',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => FindIdViewModel(baseUrl: baseUrl),
          child: FindIdScreen(baseUrl: baseUrl),
        ),
      ),
      GoRoute(
        path: '/find-id-result',
        builder: (context, state) {
          final userId = state.extra as String;
          return FindIdResultScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/find_password',
        builder: (context, state) => FindPasswordScreen(baseUrl: baseUrl),
      ),
            GoRoute(
        path: '/find-password-result',
        builder: (context, state) => const FindPasswordResultScreen(),
      ),
      GoRoute(
        path: '/web',
        builder: (context, state) => const WebPlaceholderScreen(),
      ),

      // Doctor Shell
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
          GoRoute(
            path: '/d_result_detail', // ✅ 이름 없이 path만 사용
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;

              if (extra == null ||
                  !extra.containsKey('userId') ||
                  !extra.containsKey('imagePath') ||
                  !extra.containsKey('baseUrl')) {
                return const Scaffold(
                  body: Center(child: Text('잘못된 접근입니다')),
                );
              }

              return DResultDetailScreen(
                userId: extra['userId'] as String,
                originalImageUrl: extra['imagePath'] as String,
                baseUrl: extra['baseUrl'] as String,
              );
            },
          ),
          GoRoute(
            path: '/d_telemedicine_application',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final initialTab = extra['initialTab'] as int? ?? 0;
              final passedBaseUrl = extra['baseUrl'] as String? ?? baseUrl;

              return DTelemedicineApplicationScreen(
                baseUrl: passedBaseUrl,
                initialTab: initialTab,
              );
            },
          ),
        ],
      ),

      // User Shell
      ShellRoute(
        builder: (context, state, child) => MainScaffold(
          child: child,
          currentLocation: state.uri.toString(),
        ),
        routes: [
          GoRoute(path: '/chatbot', 
          builder: (context, state) => const ChatbotScreen()
          ),
          GoRoute(
            path: '/multimodal_result',
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
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return MyPageScreen(baseUrl: passedBaseUrl);
            },
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
            path: '/survey',
            builder: (context, state) {
              final passedBaseUrl = state.extra as String? ?? baseUrl;
              return DentalSurveyScreen(baseUrl: passedBaseUrl);
            },
          ),
          GoRoute(
            path: '/upload',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final baseUrl = extra['baseUrl'] as String? ?? '';
              final survey = extra['survey'] as Map<String, dynamic>? ?? {};
              return UploadScreen(baseUrl: baseUrl, survey: survey);
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
            path: '/consult_success',
            builder: (context, state) {
              final type = state.extra is Map ? (state.extra as Map)['type'] as String? : null;
              return ConsultResultScreen(type: type);
            },
          ),
          GoRoute(path: '/clinics', builder: (context, state) => const ClinicsScreen()),
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
            path: '/upload_xray_result_detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return UploadXrayResultDetailScreen(
                originalImageUrl: extra['originalImageUrl'],
                model1ImageUrl: extra['model1ImageUrl'],
                model2ImageUrl: extra['model2ImageUrl'],
                model1Result: Map<String, dynamic>.from(extra['model1Result']),
                userId: extra['userId'],
                inferenceResultId: extra['inferenceResultId'],
                baseUrl: extra['baseUrl'],
              );
            },
          ),
          GoRoute(
            path: '/history_result_detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return HistoryResultDetailScreen(
                originalImageUrl: extra['originalImageUrl'],
                processedImageUrls: Map<int, String>.from(extra['processedImageUrls']),
                modelInfos: Map<int, Map<String, dynamic>>.from(extra['modelInfos']),
                userId: extra['userId'],
                inferenceResultId: extra['inferenceResultId'],
                baseUrl: extra['baseUrl'],
                isRequested: extra['isRequested'],
                isReplied: extra['isReplied'],
              );
            },
          ),
          GoRoute(
            path: '/history_xray_result_detail',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;

              final processedImageUrlsRaw = extra['processedImageUrls'] as Map;
              final modelInfosRaw = extra['modelInfos'] as Map;

              final processedImageUrls = processedImageUrlsRaw.map<int, String>(
                (key, value) => MapEntry(int.parse(key.toString()), value.toString()),
              );

              final modelInfos = modelInfosRaw.map<int, Map<String, dynamic>>(
                (key, value) => MapEntry(int.parse(key.toString()), Map<String, dynamic>.from(value)),
              );

              // ✅ 문자열로 명확히 변환
              final String isRequested = (extra['isRequested'] ?? 'N').toString();
              final String isReplied = (extra['isReplied'] ?? 'N').toString();

              return HistoryXrayResultDetailScreen(
                originalImageUrl: extra['originalImageUrl'],
                model1ImageUrl: processedImageUrls[1] ?? '',
                model2ImageUrl: processedImageUrls[2] ?? '',
                model1Result: modelInfos[1] ?? {},
                userId: extra['userId'],
                inferenceResultId: extra['inferenceResultId'],
                baseUrl: extra['baseUrl'],
                isRequested: isRequested,
                isReplied: isReplied,
              );
            },
          ),
        ],
      ),
    ],
  );
}



