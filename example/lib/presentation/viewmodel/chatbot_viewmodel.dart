import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;

class ChatMessage {
  final String role; // 'user' or 'bot'
  final String content;
  final String? imageUrl; // ✅ 이미지 URL 필드 추가

  ChatMessage({
    required this.role,
    required this.content,
    this.imageUrl,
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

  Future<void> sendMessage(String message, String patientId) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'patient_id': patientId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['response'] ?? '응답을 받을 수 없습니다.';
        final imageUrl = data['image_url']; // ✅ image_url 추출

        _messages.add(ChatMessage(
          role: 'bot',
          content: botResponse,
          imageUrl: imageUrl,
        ));
      } else {
        if (kDebugMode) {
          print('챗봇 API 오류: ${response.statusCode}, ${response.body}');
        }
        _messages.add(ChatMessage(role: 'bot', content: '서버 오류 발생. 다시 시도해주세요.'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('챗봇 네트워크 오류: $e');
      }
      _messages.add(ChatMessage(role: 'bot', content: '서버와 연결할 수 없습니다.'));
    } finally {
      notifyListeners();
    }
  }
}
