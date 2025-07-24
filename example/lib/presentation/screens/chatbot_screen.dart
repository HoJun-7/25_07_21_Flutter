import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    await Provider.of<ChatbotViewModel>(context, listen: false)
        .sendMessage(message);

    _controller.clear();
    _scrollToBottom();
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
    final messages = context.watch<ChatbotViewModel>().messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text("챗봇"),
        backgroundColor: const Color(0xFF3869A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '대화 초기화',
            onPressed: () {
              context.read<ChatbotViewModel>().clearMessages();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.role == 'user';
                  final imageUrls = message.imageUrls;

                  // ✅ 키 → 한글 라벨 맵
                  const labelMap = {
                    "model1": "충치/치주염/치은염",
                    "model2": "치석/보철물",
                    "model3": "치아번호",
                    "original": "원본"
                  };

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Material(
                            borderRadius: BorderRadius.circular(8.0),
                            color: isUser ? Colors.green[200] : Colors.blue[200],
                            elevation: 2.0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 15.0),
                              child: Text(
                                message.content,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          if (imageUrls != null && imageUrls.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: imageUrls.entries
                                    .map((entry) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              labelMap[entry.key] ??
                                                  entry.key,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                            Image.network(
                                              entry.value,
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: progress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? progress
                                                                .cumulativeBytesLoaded /
                                                            progress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Text(
                                                    '이미지를 불러올 수 없습니다.');
                                              },
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
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
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
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
