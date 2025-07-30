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
  late AnimationController _sendBtnAnimCtr;
  late Animation<double> _sendBtnScale;

  static const double profileImageSize = 40.0;

  @override
  void initState() {
    super.initState();
    _sendBtnAnimCtr = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: _sendBtnAnimCtr, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sendBtnAnimCtr.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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

  Widget _buildProfileAvatar({required bool isUser}) {
    final currentUser =
        Provider.of<AuthViewModel>(context, listen: false).currentUser;
    String? userNameInitial;
    if (isUser &&
        currentUser != null &&
        currentUser.name != null &&
        currentUser.name!.isNotEmpty) {
      userNameInitial = currentUser.name![0].toUpperCase();
    }

    return ClipOval(
      child: Container(
        width: profileImageSize,
        height: profileImageSize,
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFC9F1DE) : const Color(0xFFADD8E6),
          shape: BoxShape.circle,
          border: Border.all(
            color: isUser ? const Color(0xFF9CCC65) : const Color(0xFF87CEEB),
            width: 2.5,
          ),
        ),
        child: Center(
          child: isUser && userNameInitial != null
              ? Text(
                  userNameInitial,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : Image.asset(
                  'images/dentibot.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  width: profileImageSize * .8,
                  height: profileImageSize * .8,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChatbotViewModel>().messages;
    final isLoading = context.watch<ChatbotViewModel>().isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('앱 종료',
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
              content: Text('앱을 종료하시겠습니까?',
                  style: GoogleFonts.notoSansKr()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('취소',
                        style: GoogleFonts.notoSansKr(
                            color: const Color(0xFFADD8E6)))),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('종료',
                        style: GoogleFonts.notoSansKr(
                            color: const Color(0xFFADD8E6)))),
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
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 아직 준비 중입니다.')),
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (_, idx) {
                  final msg = messages[idx];
                  final isUser = msg.role == 'user';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
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
                            if (!isUser) _buildProfileAvatar(isUser: false),
                            if (!isUser) const SizedBox(width: 8),
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
                                textStyle: GoogleFonts.notoSansKr(
                                    fontSize: 15, color: Colors.black),
                              ),
                            ),
                            if (isUser) const SizedBox(width: 8),
                            if (isUser) _buildProfileAvatar(isUser: true),
                          ],
                        ),
                        if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: msg.imageUrls!.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        entry.value,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _buildProfileAvatar(isUser: false),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      builder: (_, value, __) {
                        final dots = '.' * ((value * 4).floor() % 4);
                        return Text('덴티가 생각 중이에요$dots',
                            style: GoogleFonts.notoSansKr(
                                color: Colors.black54, fontSize: 15));
                      },
                      onEnd: () => setState(() {}),
                    ),
                  ],
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(
                                  color: Color(0xFFC0E6FF), width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: const BorderSide(
                                  color: Color(0xFF7EB7E6), width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
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
                      onTapDown: (_) => _sendBtnAnimCtr.forward(),
                      onTapUp: (_) => _sendBtnAnimCtr.reverse(),
                      onTapCancel: () => _sendBtnAnimCtr.reverse(),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _sendMessage(_controller.text);
                      },
                      child: ScaleTransition(
                        scale: _sendBtnScale,
                        child: Container(
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFADD8E6),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2)),
                              ]),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 24),
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
