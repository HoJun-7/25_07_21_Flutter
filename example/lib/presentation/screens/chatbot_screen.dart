import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
<<<<<<< HEAD
import 'package:provider/provider.dart'; // Provider 임포트
import '/presentation/viewmodel/auth_viewmodel.dart'; // AuthViewModel 임포트 경로 확인
=======
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
<<<<<<< HEAD
  final List<Map<String, String>> _messages = [];
=======
  final List<Map<String, String?>> _messages = []; // Map<String, String> -> Map<String, String?>

>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
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
<<<<<<< HEAD
      _messages.add({'role': 'user', 'message': message});
=======
      _messages.add({'role': 'user', 'message': message, 'image_url': null}); // 사용자 메시지는 이미지 없음
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
<<<<<<< HEAD
        Uri.parse('http://192.168.0.19:5000/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': currentUserId ?? 'guest',
=======
        Uri.parse('http://192.168.0.19:5000/api/chatbot'), 
        //Uri.parse('http://192.168.0.19:5000/api/chat-medgemma'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_id': currentUserId ?? 'guest', // 'user_id'를 'patient_id'로 변경
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final botMessage = responseData['response'] ?? '응답이 없습니다.';
<<<<<<< HEAD

        setState(() {
          _messages.add({'role': 'bot', 'message': botMessage});
=======
        final imageUrl = responseData['image_url']; // 백엔드에서 받은 image_url

        setState(() {
          _messages.add({
            'role': 'bot',
            'message': botMessage,
            'image_url': imageUrl as String?, // 이미지 URL 추가
          });
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'message': '챗봇 서버 오류 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
<<<<<<< HEAD
=======
            'image_url': null,
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
          });
        });
      }
    } catch (e) {
      setState(() {
<<<<<<< HEAD
        _messages.add({'role': 'bot', 'message': '네트워크 오류: 챗봇 서버에 연결할 수 없습니다. ($e)'});
=======
        _messages.add({
          'role': 'bot',
          'message': '네트워크 오류: 챗봇 서버에 연결할 수 없습니다. ($e)',
          'image_url': null,
        });
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
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
<<<<<<< HEAD
=======
        backgroundColor: const Color(0xFF3869A8),
        foregroundColor: Colors.white,
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
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
<<<<<<< HEAD
=======
                  final imageUrl = message['image_url']; // 이미지 URL 가져오기

>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
<<<<<<< HEAD
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
=======
                      child: Column( // 이미지를 추가하기 위해 Column 사용
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Material(
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
                          if (imageUrl != null && imageUrl.isNotEmpty) // 이미지 URL이 있을 경우
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.network(
                                imageUrl,
                                width: 200, // 이미지 너비 조절
                                height: 200, // 이미지 높이 조절
                                fit: BoxFit.cover,
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text('이미지를 불러올 수 없습니다.');
                                },
                              ),
                            ),
                        ],
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
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
<<<<<<< HEAD

=======
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
