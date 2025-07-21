import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // HTTP 통신을 위해 필요
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 필요
import 'package:flutter/foundation.dart' show kDebugMode; // kDebugMode를 위해 필요

class ChatbotViewModel extends ChangeNotifier {
  // ✅ 생성자를 통해 주입받도록 변경
  final String _baseUrl; 

  // ✅ 생성자 추가: baseUrl을 필수 매개변수로 받습니다.
  ChatbotViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage(String message) async { // 비동기 함수로 변경
    _messages.add(ChatMessage(role: 'user', content: message));
    notifyListeners();

    try {
      // TODO: 실제 챗봇 API 호출로 대체
      // 예시: Flask 백엔드의 챗봇 엔드포인트 호출
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot/predict'), // 챗봇 API 엔드포인트 (예시)
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['response'] ?? '응답을 받을 수 없습니다.';
        _messages.add(ChatMessage(role: 'bot', content: botResponse));
      } else {
        if (kDebugMode) {
          print('챗봇 API 서버 응답 오류: StatusCode=${response.statusCode}, Body=${response.body}');
        }
        _messages.add(ChatMessage(role: 'bot', content: '서버 오류 발생. 잠시 후 다시 시도해주세요.'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('챗봇 API 호출 중 네트워크 오류: $e');
      }
      _messages.add(ChatMessage(role: 'bot', content: '서버와 연결할 수 없습니다. 네트워크 상태를 확인해주세요.'));
    } finally {
      notifyListeners(); // 메시지 추가 후 UI 업데이트
    }
  }
}

class ChatMessage {
  final String role; // 'user' or 'bot'
  final String content;

  ChatMessage({required this.role, required this.content});
}