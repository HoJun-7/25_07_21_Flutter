import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    notifyListeners();

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
      notifyListeners();
    }
  }
}