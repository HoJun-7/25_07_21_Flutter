// lib/presentation/viewmodel/chatbot_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode; // debugPrint 사용을 위해 임포트
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

// ChatMessage 모델
class ChatMessage {
  final String role; // 'user' or 'bot'
  final String content;
  final Map<String, String>? imageUrls; // ✅ 여러 이미지 URL 저장
  final String? inferenceResultId; // ✅ 추가: 관련 진단 결과 ID

  ChatMessage({
    required this.role,
    required this.content,
    this.imageUrls,
    this.inferenceResultId, // ✅ 추가
  });

  // ChatMessage를 JSON으로 직렬화/역직렬화하는 메서드 추가 (저장/로드 시 필요)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      imageUrls: (json['imageUrls'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      inferenceResultId: json['inferenceResultId'] as String?, // ✅ 추가
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'imageUrls': imageUrls,
      'inferenceResultId': inferenceResultId, // ✅ 추가
    };
  }
}

class ChatbotViewModel extends ChangeNotifier {
  final String _baseUrl;
  final AuthViewModel _authViewModel;

  final List<ChatMessage> _messages = []; // ✅ final로 변경하고 초기화
  bool _isLoading = false;
  String? _currentUserId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatbotViewModel({required String baseUrl, required AuthViewModel authViewModel})
      : _baseUrl = baseUrl,
        _authViewModel = authViewModel {
    _currentUserId = _authViewModel.currentUser?.registerId;
    _authViewModel.addListener(_onAuthChanged);
    _addInitialGreeting();
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final newUserId = _authViewModel.currentUser?.registerId;
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _messages.clear();
      _addInitialGreeting();
      notifyListeners();
    }
  }

  void _addInitialGreeting() {
    if (_messages.isEmpty || (_messages.first.role != 'bot' || !_messages.first.content.contains('안녕하세요'))) {
      final userName = _authViewModel.currentUser?.name ?? '사용자';
      _messages.insert(0, ChatMessage(
        role: 'bot',
        content: '$userName님 안녕하세요!\nMeditooth의 치아 요정 덴티라고 해요.\n어떤 문의사항이 있으신가요?',
      ));
    }
  }

  void clearMessages() {
    _messages.clear();
    _addInitialGreeting();
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    _isLoading = true;
    notifyListeners();

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final userId = _currentUserId ?? 'guest';

      // ✅ token이 null이 아닐 때만 API 호출을 시도합니다.
      //    이렇게 하면 Dart 분석기가 이 블록 내에서 token이 String 타입임을 확실히 알게 됩니다.
      if (token != null) {
        final response = await http.post(
          Uri.parse('$_baseUrl/chatbot'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // ✅ 이 시점에서는 token이 String 타입이므로 오류가 발생하지 않습니다.
          },
          body: jsonEncode({
            'user_id': userId,
            'message': message,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final botResponse = data['response'] ?? '응답을 받을 수 없습니다.';
          Map<String, String>? imageUrls;
          String? inferenceResultId;

          if (data['image_urls'] != null && data['image_urls'] is Map<String, dynamic>) {
            imageUrls = Map<String, String>.from(data['image_urls']);
          }

          inferenceResultId = data['inference_result_id'] as String?;

          if (inferenceResultId != null) {
            if (imageUrls == null ||
                !imageUrls.containsKey('masked_cavity_image_path') ||
                !imageUrls.containsKey('masked_calculus_image_path') ||
                !imageUrls.containsKey('masked_tooth_number_image_path')) {
              
              debugPrint('🔎 마스킹 이미지 URL이 부족하여 추가 호출 시도: $inferenceResultId');
              final fullImageUrls = await _fetchFullImageUrlsForInference(inferenceResultId, token);
              if (fullImageUrls != null) {
                imageUrls ??= {};
                imageUrls.addAll(fullImageUrls);
                debugPrint('✅ 마스킹 이미지 URL 추가 로드 성공');
              } else {
                debugPrint('❌ 마스킹 이미지 URL 추가 로드 실패');
              }
            }
          }

          _messages.add(ChatMessage(
            role: 'bot',
            content: botResponse,
            imageUrls: imageUrls,
            inferenceResultId: inferenceResultId,
          ));
        } else {
          if (kDebugMode) {
            debugPrint('챗봇 API 오류: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}');
          }
          _messages.add(ChatMessage(
            role: 'bot',
            content: '서버 오류 발생. 다시 시도해주세요.',
          ));
        }
      } else {
        // ✅ token이 null인 경우의 메시지 처리
        _messages.add(ChatMessage(
          role: 'bot',
          content: '사용자 인증 정보가 없습니다. 다시 로그인 해주세요.',
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('챗봇 네트워크 오류: $e');
      }
      _messages.add(ChatMessage(
        role: 'bot',
        content: '서버와 연결할 수 없습니다.',
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> _fetchFullImageUrlsForInference(String inferenceResultId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inference_results/$inferenceResultId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['image_urls'] != null && data['image_urls'] is Map<String, dynamic>) {
          return Map<String, String>.from(data['image_urls']);
        }
      } else {
        if (kDebugMode) {
          debugPrint('전체 이미지 URL 요청 실패: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('전체 이미지 URL 로딩 중 네트워크 오류: $e');
      }
    }
    return null;
  }
}
