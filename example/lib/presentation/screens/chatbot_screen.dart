import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart'; // AuthViewModel 임포트
import '/presentation/viewmodel/chatbot_viewmodel.dart'; // ChatbotViewModel 임포트
import 'package:flutter/services.dart';
import 'chat_bubble.dart'; // ChatBubble 위젯 임포트 (이 파일이 프로젝트에 있어야 함)
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

    // ChatbotViewModel이 초기 메시지를 스스로 관리하므로,
    // 이곳에서 WidgetsBinding.instance.addPostFrameCallback 블록을 제거합니다.
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
    // 메시지 전송 전에 스크롤을 맨 아래로 이동
    _scrollToBottom();
    await Provider.of<ChatbotViewModel>(context, listen: false)
        .sendMessage(trimmed);
    // 챗봇 응답 후 다시 스크롤을 맨 아래로 이동
    _scrollToBottom();
  }

  // 수정: isUser 인자를 추가하여 봇과 사용자 아바타를 구분합니다.
  Widget _buildProfileAvatar({required bool isUser}) {
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;

    String? userNameInitial;
    if (isUser && currentUser != null && currentUser.name != null && currentUser.name!.isNotEmpty) {
      userNameInitial = currentUser.name![0].toUpperCase();
    }

    return ClipOval(
      child: Container(
        width: profileImageSize,
        height: profileImageSize,
        decoration: BoxDecoration( // BoxDecoration 사용
          color: isUser ? const Color(0xFFC9F1DE) : const Color(0xFFADD8E6), // 사용자/봇에 따라 다른 배경색 (기존 연한 색상 유지)
          shape: BoxShape.circle,
          border: Border.all(
            // ✅ 테두리 색상만 요청에 따라 변경 (하늘색, 연두색)
            color: isUser ? const Color(0xFF9CCC65) : const Color(0xFF87CEEB), // 사용자: 연두색, 봇: 하늘색
            width: 2.5, // 테두리 두께는 유지
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
                  'images/dentibot.png', // 봇 아바타 이미지
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
    // ChatbotViewModel의 messages 리스트를 watch하여 변경 시 UI 업데이트
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
                itemCount: messages.length, // ViewModel의 메시지 목록 길이를 사용
                itemBuilder: (_, idx) {
                  final msg = messages[idx];
                  final isUser = msg.role == 'user';
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end // 사용자 메시지는 오른쪽 정렬
                          : MainAxisAlignment.start, // 봇 메시지는 왼쪽 정렬
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ 사용자 메시지일 때: Spacer -> 메시지 버블 -> 여백 -> 아바타
                        if (isUser) const Spacer(), // 남은 공간을 모두 차지하여 오른쪽으로 밀어냄
                        if (isUser)
                          Flexible(
                            child: ChatBubble(
                              message: msg.content,
                              isUser: isUser,
                              bubbleColor: const Color(0xFFAAD9FF), // 사용자 메시지 버블 색상
                              borderColor: const Color(0xFF7EB7E6), // 사용자 메시지 테두리 색상
                              textStyle: GoogleFonts.notoSansKr(
                                  fontSize: 15, color: Colors.black),
                            ),
                          ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser) _buildProfileAvatar(isUser: true), // 사용자 아바타

                        // ✅ 봇 메시지일 때: 아바타 -> 여백 -> 메시지 버블 -> Spacer
                        if (!isUser) _buildProfileAvatar(isUser: false), // 봇 아바타
                        if (!isUser) const SizedBox(width: 8),
                        if (!isUser)
                          Flexible(
                            child: ChatBubble(
                              message: msg.content,
                              isUser: isUser,
                              bubbleColor: const Color(0xFFE0F2FF), // 봇 메시지 버블 색상
                              borderColor: const Color(0xFFC0E6FF), // 봇 메시지 테두리 색상
                              textStyle: GoogleFonts.notoSansKr(
                                  fontSize: 15, color: Colors.black),
                            ),
                          ),
                        if (!isUser) const Spacer(), // 남은 공간을 모두 차지하여 왼쪽으로 밀어냄
                      ],
                    ),
                  );
                },
              ),
            ),
            // 챗봇이 응답을 로딩 중일 때 표시되는 부분
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    _buildProfileAvatar(isUser: false), // 봇이 생각 중이므로 봇 아바타 표시
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: Listenable.merge([]),
                      builder: (context, child) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 1),
                          builder: (_, value, __) {
                            final dots = '.' * ((value * 4).floor() % 4);
                            return Text('덴티가 생각 중이에요$dots',
                                style: GoogleFonts.notoSansKr(
                                    color: Colors.black54, fontSize: 15));
                          },
                          onEnd: () => setState(() {}),
                        );
                      },
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
                      onTapDown: (_) => _sendBtnAnimCtr.forward(), // 버튼 눌릴 때 애니메이션 시작
                      onTapUp: (_) => _sendBtnAnimCtr.reverse(), // 버튼 떼어질 때 애니메이션 복귀
                      onTapCancel: () => _sendBtnAnimCtr.reverse(), // 탭 취소 시 애니메이션 복귀
                      onTap: () {
                        FocusScope.of(context).unfocus(); // 키보드 내리기
                        _sendMessage(_controller.text); // 메시지 전송
                      },
                      child: ScaleTransition(
                        scale: _sendBtnScale, // 전송 버튼 스케일 애니메이션 적용
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
