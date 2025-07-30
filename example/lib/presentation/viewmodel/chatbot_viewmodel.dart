// lib/presentation/viewmodel/chatbot_viewmodel.dart
import 'package:flutter/material.dart'; // ChangeNotifier는 Material.dart에 포함
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/presentation/viewmodel/auth_viewmodel.dart'; // AuthViewModel 임포트

// ChatMessage 모델 (변경 없음, 그대로 유지)
class ChatMessage {
  final String role; // 'user' or 'bot'
  final String content;
  final Map<String, String>? imageUrls; // ✅ 여러 이미지 URL 저장

  ChatMessage({
    required this.role,
    required this.content,
    this.imageUrls,
  });

  // ChatMessage를 JSON으로 직렬화/역직렬화하는 메서드 추가 (저장/로드 시 필요)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      imageUrls: (json['imageUrls'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'imageUrls': imageUrls,
    };
  }
}

class ChatbotViewModel extends ChangeNotifier {
  final String _baseUrl;
  final AuthViewModel _authViewModel; // AuthViewModel 의존성 주입

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentUserId; // 현재 뷰모델이 관리하는 사용자 ID

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatbotViewModel({required String baseUrl, required AuthViewModel authViewModel})
      : _baseUrl = baseUrl,
        _authViewModel = authViewModel {
    _currentUserId = _authViewModel.currentUser?.registerId; // 초기 사용자 ID 설정
    _authViewModel.addListener(_onAuthChanged); // AuthViewModel 변경 리스너 등록
    _addInitialGreeting(); // ✅ 뷰모델 초기화 시 첫 인사 추가
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthChanged); // 리스너 제거
    super.dispose();
  }

  // AuthViewModel의 사용자 변경을 감지하는 콜백
  void _onAuthChanged() {
    final newUserId = _authViewModel.currentUser?.registerId;
    if (newUserId != _currentUserId) {
      // 사용자 ID가 변경되면 메시지 초기화
      _currentUserId = newUserId;
      _messages.clear();
      _addInitialGreeting(); // 새 사용자를 위한 첫 인사 추가
      notifyListeners(); // UI 업데이트
    }
  }

  // 덴티봇의 초기 인사 메시지를 추가하는 헬퍼 메서드
  void _addInitialGreeting() {
    // 메시지 목록이 비어 있을 때만 초기 인사를 추가하여 중복 방지
    // (AuthViewModel 변경 시 clearMessages에서 호출될 때도 중복 방지)
    if (_messages.isEmpty || (_messages.first.role != 'bot' || !_messages.first.content.contains('안녕하세요'))) {
      final userName = _authViewModel.currentUser?.name ?? '사용자';
      _messages.insert(0, ChatMessage( // 목록의 맨 앞에 추가
        role: 'bot',
        content: '$userName님 안녕하세요!\nMeditooth의 치아 요정 덴티라고 해요.\n어떤 문의사항이 있으신가요?',
      ));
    }
  }

  void clearMessages() {
    _messages.clear();
    _addInitialGreeting(); // ✅ 메시지 초기화 후 첫 인사 다시 추가
    notifyListeners();
    // TODO: 로컬 저장소 또는 서버에서 해당 사용자 메시지 삭제 로직 추가 (필요시)
  }

  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    _isLoading = true; // ✅ 로딩 시작
    notifyListeners(); // 로딩 시작 및 사용자 메시지 추가 후 UI 업데이트

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final userId = _currentUserId ?? 'guest'; // 현재 사용자 ID 사용

      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId, // ✅ 사용자 ID를 백엔드로 전달
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // 한글 깨짐 방지
        final botResponse = data['response'] ?? '응답을 받을 수 없습니다.';
        Map<String, String>? imageUrls;

        if (data['image_urls'] != null &&
            data['image_urls'] is Map<String, dynamic>) {
          imageUrls = Map<String, String>.from(data['image_urls']);
        }

        _messages.add(ChatMessage(
          role: 'bot',
          content: botResponse,
          imageUrls: imageUrls,
        ));
      } else {
        if (kDebugMode) {
          print('챗봇 API 오류: ${response.statusCode}, ${utf8.decode(response.bodyBytes)}'); // 한글 깨짐 방지
        }
        _messages.add(ChatMessage(
          role: 'bot',
          content: '서버 오류 발생. 다시 시도해주세요.',
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('챗봇 네트워크 오류: $e');
      }
      _messages.add(ChatMessage(
        role: 'bot',
        content: '서버와 연결할 수 없습니다.',
      ));
    } finally {
      _isLoading = false; // ✅ 로딩 종료
      notifyListeners(); // 로딩 종료 및 챗봇 응답 후 UI 업데이트
    }
  }
}