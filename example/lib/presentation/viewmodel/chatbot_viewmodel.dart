import 'package:flutter/material.dart'; // 이미 여기에 ChangeNotifier 포함됨
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, ChangeNotifier; // ✅ ChangeNotifier 명시적 임포트 (더 명확하게)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ChatMessage 모델은 그대로 유지
class ChatMessage {
  final String role; // 'user' or 'bot'
  final String content;
  final Map<String, String>? imageUrls; // ✅ 여러 이미지 URL 저장

  ChatMessage({
    required this.role,
    required this.content,
    this.imageUrls,
  });
}

class ChatbotViewModel extends ChangeNotifier {
  final String _baseUrl;

  ChatbotViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false; // ✅ 로딩 상태 추가

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading; // ✅ isLoading getter 추가

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    _isLoading = true; // ✅ 로딩 시작
    notifyListeners(); // 로딩 시작 및 사용자 메시지 추가 후 UI 업데이트

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

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
          print('챗봇 API 오류: ${response.statusCode}, ${response.body}');
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
