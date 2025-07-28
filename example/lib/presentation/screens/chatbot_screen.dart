import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'package:flutter/services.dart';

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
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    await Provider.of<ChatbotViewModel>(context, listen: false)
        .sendMessage(trimmed);

    _scrollToBottom();
  }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart'; // 이 경로는 실제 프로젝트에 맞게 조정해주세요.
import '/presentation/viewmodel/chatbot_viewmodel.dart'; // 이 경로는 실제 프로젝트에 맞게 조정해주세요.
import 'package:flutter/services.dart';

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
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    await Provider.of<ChatbotViewModel>(context, listen: false)
        .sendMessage(trimmed);

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
    final isLoading = context.watch<ChatbotViewModel>().isLoading;
    final String? currentUserName =
        Provider.of<AuthViewModel>(context, listen: false).currentUser?.name ??
            '사용자';

    const Map<String, String> labelMap = {
      'model1': '충치/치주염/치은염',
      'model2': '치석/보철물',
      'model3': '치아번호',
      'original': '원본',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('앱 종료'),
                content: const Text('앱을 종료하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('종료'),
                  ),
                ],
              ),
            ) ??
            false;
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFADD8E6),
          centerTitle: true,
          title: const Text(
            'Denti',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: '대화 초기화',
            onPressed: () {
              context.read<ChatbotViewModel>().clearMessages();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              tooltip: '알림',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 아직 개발 중입니다.')),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            /// ✅ 덴티봇 첫 인사
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column( // 덴티봇 캐릭터와 말풍선 간격을 위해 Column 추가
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFADD8E6), // TopBar 색상
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Image.asset(
                                'images/dentibot.png', // 이미지 경로 확인
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 말풍선을 캐릭터 아래로 이동시키기 위한 간격 추가
                      const SizedBox(height: 10), // 이전 12에서 10으로 약간 조정
                    ],
                  ),
                  // 말풍선을 캐릭터의 꼬리가 향하는 쪽으로 약간 더 가깝게
                  const SizedBox(width: 4), // 8에서 4로 줄여 캐릭터에 더 가깝게
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FF),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(0), // 덴티봇 첫 인사 말풍선 꼬리 (위로, 더 뾰족하게)
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                            color: const Color(0xFFC0E6FF), width: 1.0),
                      ),
                      child: Text(
                        '$currentUserName님 안녕하세요!\n'
                        'Meditooth의 치아 요정 덴티라고 해요.\n'
                        '어떤 문의사항이 있으신가요?',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Colors.grey),

            /// ✅ 메시지 목록
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message.role == 'user';
                  final imageUrls = message.imageUrls;

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
                          Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Column( // 덴티봇 캐릭터와 말풍선 간격을 위해 Column 추가
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipOval(
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        color: const Color(0xFFADD8E6),
                                        child: Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Image.asset(
                                              'images/dentibot.png', // 이미지 경로 확인
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 말풍선을 캐릭터 아래로 이동시키기 위한 간격 추가
                                    const SizedBox(height: 6), // 이전 8에서 6으로 약간 조정
                                  ],
                                ),
                              const SizedBox(width: 4), // 8에서 4로 줄여 캐릭터에 더 가깝게
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 14.0),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color(0xFFAAD9FF)
                                        : const Color(0xFFE0F2FF),
                                    borderRadius: isUser
                                        ? const BorderRadius.only(
                                            topLeft: Radius.circular(14.0),
                                            bottomLeft: Radius.circular(14.0),
                                            topRight: Radius.circular(14.0),
                                            bottomRight: Radius.circular(
                                                2.0), // 사용자 말풍선 꼬리 (아래)
                                          )
                                        : const BorderRadius.only(
                                            topLeft: Radius.circular(
                                                0), // 덴티봇 개별 메시지 말풍선 꼬리 (위로, 더 뾰족하게)
                                            bottomLeft: Radius.circular(14.0),
                                            topRight: Radius.circular(14.0),
                                            bottomRight: Radius.circular(14.0),
                                          ),
                                    border: Border.all(
                                      color: isUser
                                          ? const Color(0xFF7EB7E6) // 사용자 메시지 테두리 색상
                                          : const Color(0xFFC0E6FF), // 덴티봇 메시지 테두리 색상
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    message.content,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (imageUrls != null && imageUrls.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: imageUrls.entries
                                    .map(
                                      (entry) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            labelMap[entry.key] ?? entry.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Image.network(
                                            entry.value,
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            loadingBuilder:
                                                (context, child, progress) {
                                              if (progress == null) {
                                                return child;
                                              }
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
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Text(
                                                    '이미지를 불러올 수 없습니다.'),
                                          ),
                                        ],
                                      ),
                                    )
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

            /// ✅ 로딩 상태
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFADD8E6)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '덴티가 생각 중이에요...',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

            /// ✅ 메시지 입력창
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '메시지를 작성해주세요',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: const BorderSide(
                                color: Color(0xFFC0E6FF), width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: const BorderSide(
                                color: Color(0xFF7EB7E6), width: 2.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                        ),
                        onSubmitted: (text) {
                          FocusScope.of(context).unfocus();
                          _sendMessage(text);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFADD8E6),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _sendMessage(_controller.text);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
