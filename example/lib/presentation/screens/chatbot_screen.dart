import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart'; // Provider 임포트
import '/presentation/viewmodel/auth_viewmodel.dart'; // AuthViewModel 임포트 경로 확인

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    final String? currentUserId =
        Provider.of<AuthViewModel>(context, listen: false).currentUser?.registerId;

    setState(() {
      _messages.add({'role': 'user', 'message': message});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.19:5000/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': currentUserId ?? 'guest',
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final botMessage = responseData['response'] ?? '응답이 없습니다.';

        setState(() {
          _messages.add({'role': 'bot', 'message': botMessage});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'message': '챗봇 서버 오류 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'message': '네트워크 오류: 챗봇 서버에 연결할 수 없습니다. ($e)'});
      });
    } finally {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("챗봇"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Material(
                        borderRadius: BorderRadius.circular(8.0),
                        color: isUser ? Colors.green[200] : Colors.blue[200],
                        elevation: 2.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                          child: Text(
                            message['message'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "질문을 입력하세요...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

