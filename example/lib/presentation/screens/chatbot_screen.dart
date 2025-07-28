import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'package:flutter/services.dart';
import 'chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _sendButtonAnimationController;
  late final Animation<double> _sendButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _sendButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sendButtonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sendButtonAnimationController.dispose();
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
    final currentUserName =
        Provider.of<AuthViewModel>(context, listen: false).currentUser?.name ?? '사용자';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                '앱 종료',
                style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
              ),
              content: Text('앱을 종료하시겠습니까?', style: GoogleFonts.notoSansKr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('취소',
                      style: GoogleFonts.notoSansKr(color: const Color(0xFFADD8E6))),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('종료',
                      style: GoogleFonts.notoSansKr(color: const Color(0xFFADD8E6))),
                ),
              ],
            ),
          );
          if (shouldExit == true) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Text('Denti',
              style: GoogleFonts.notoSansKr(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: '대화 초기화',
            onPressed: () => context.read<ChatbotViewModel>().clearMessages(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              tooltip: '알림',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('알림 기능은 아직 개발 중입니다.',
                      style: GoogleFonts.notoSansKr()),
                ));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // 첫 인사
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFADD8E6),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Image.asset('images/dentibot.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChatBubble(
                      message:
                          '$currentUserName님 안녕하세요!\nMeditooth의 치아 요정 덴티라고 해요.\n어떤 문의사항이 있으신가요?',
                      isUser: false,
                      bubbleColor: const Color(0xFFE0F2FF),
                      borderColor: const Color(0xFFC0E6FF),
                      textStyle: GoogleFonts.notoSansKr(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = messages[idx];
                  final isUser = msg.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Row(
                        mainAxisAlignment:
                            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            ClipOval(
                              child: Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFFADD8E6),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child:
                                        Image.asset('images/dentibot.png', fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ChatBubble(
                              message: msg.content,
                              isUser: isUser,
                              bubbleColor: isUser
                                  ? const Color(0xFFAAD9FF)
                                  : const Color(0xFFE0F2FF),
                              borderColor: isUser
                                  ? const Color(0xFF7EB7E6)
                                  : const Color(0xFFC0E6FF),
                              textStyle: GoogleFonts.notoSansKr(fontSize: 15, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 로딩 타이핑
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        width: 36,
                        height: 36,
                        color: const Color(0xFFADD8E6),
                        child: Center(
                          child:
                              SizedBox(width: 28, height: 28, child: Image.asset('images/dentibot.png', fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC0E6FF), width: 1),
                      ),
                      child: Text('덴티가 생각 중이에요',
                          style: GoogleFonts.notoSansKr(color: Colors.black54, fontSize: 15)),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 3.0),
                      duration: const Duration(seconds: 1),
                      builder: (ctx, val, child) {
                        final dots = '.' * (val.floor() % 4);
                        return Text(dots,
                            style:
                                GoogleFonts.notoSansKr(color: Colors.black54, fontSize: 15));
                      },
                      onEnd: () {},
                    ),
                  ],
                ),
              ),

            // 입력창 + 전송 버튼
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '메시지를 작성해주세요',
                          hintStyle:
                              GoogleFonts.notoSansKr(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28.0),
                            borderSide: const BorderSide(color: Color(0xFFC0E6FF), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28.0),
                            borderSide: const BorderSide(color: Color(0xFF7EB7E6), width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                        ),
                        style: GoogleFonts.notoSansKr(fontSize: 16),
                        onSubmitted: (txt) {
                          FocusScope.of(context).unfocus();
                          _sendMessage(txt);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTapDown: (_) => _sendButtonAnimationController.forward(),
                      onTapUp: (_) => _sendButtonAnimationController.reverse(),
                      onTapCancel: () => _sendButtonAnimationController.reverse(),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _sendMessage(_controller.text);
                      },
                      child: ScaleTransition(
                        scale: _sendButtonScaleAnimation,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFADD8E6),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child:
                              const Icon(Icons.send, color: Colors.white, size: 24),
                        ),
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
