// chatbot_screen.dart
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

  // 마스킹 스위치 상태를 관리할 Map 추가
  // 모든 스위치 기본값을 false로 설정하여, 아무것도 선택되지 않았을 때 원본 이미지가 보이도록 합니다.
  final Map<String, bool> _currentMaskSettings = {
    '충치/치아/위생 관련': false,
    '치석/보철물': false,
    '치아번호': false,
  };


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

  // ✅ 마스크 설정 스위치 UI를 만드는 위젯
  Widget _buildMaskSettingSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.notoSansKr(fontSize: 14, color: Colors.grey[700])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFADD8E6), // 활성 색상
            inactiveThumbColor: Colors.grey[300], // 비활성 시 엄지 색상
            inactiveTrackColor: Colors.grey[200], // 비활성 시 트랙 색상
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChatbotViewModel>().messages;
    final isLoading = context.watch<ChatbotViewModel>().isLoading;

    // 화면 너비의 절반을 계산 (예: 챗봇 말풍선의 최대 너비가 화면의 70-80% 정도라면, 그 절반)
    // 정확한 말풍선 너비를 알 수 없으므로, 대략적인 화면 너비의 비율로 설정합니다.
    // 여기서는 화면 너비의 60%를 이미지 컨테이너의 최대 너비로 설정해 보겠습니다.
    final screenWidth = MediaQuery.of(context).size.width;
    final imageContainerWidth = screenWidth * 0.6; // 화면 너비의 60%

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

                  // ✅ 이미지 URL을 결정하는 로직을 수정합니다.
                  String? imageUrlToDisplay;
                  if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
                    print('수신된 메시지의 imageUrls: ${msg.imageUrls}');
                    print('현재 충치/치아/위생 관련 마스크 설정: ${_currentMaskSettings['충치/치아/위생 관련']}');
                    print('현재 치석/보철물 마스크 설정: ${_currentMaskSettings['치석/보철물']}');
                    print('현재 치아번호 마스크 설정: ${_currentMaskSettings['치아번호']}');

                    if (_currentMaskSettings['충치/치아/위생 관련'] == true) {
                      imageUrlToDisplay = msg.imageUrls!['model1'];
                      print('--> 모델1 이미지 (충치/치아/위생) 선택: $imageUrlToDisplay');
                    } else if (_currentMaskSettings['치석/보철물'] == true) {
                      imageUrlToDisplay = msg.imageUrls!['model2'];
                      print('--> 모델2 이미지 (치석/보철물) 선택: $imageUrlToDisplay');
                    } else if (_currentMaskSettings['치아번호'] == true) {
                      imageUrlToDisplay = msg.imageUrls!['model3'];
                      print('--> 모델3 이미지 (치아번호) 선택: $imageUrlToDisplay');
                    }

                    // 선택된 마스크 이미지가 없거나 해당 URL이 null이면 원본 이미지 사용
                    imageUrlToDisplay ??= msg.imageUrls!['original'];
                    print('--> 원본 이미지 (original) 선택: $imageUrlToDisplay');
                    
                    // 그럼에도 불구하고 null이면, 맵의 첫 번째 이미지 표시 (최후의 fallback)
                    imageUrlToDisplay ??= msg.imageUrls!.values.first;
                    if (imageUrlToDisplay == msg.imageUrls!.values.first && imageUrlToDisplay != msg.imageUrls!['original'] && imageUrlToDisplay != msg.imageUrls!['model1'] && imageUrlToDisplay != msg.imageUrls!['model2'] && imageUrlToDisplay != msg.imageUrls!['model3']) {
                        print('--> Fallback 이미지 선택 (최후): $imageUrlToDisplay');
                    }
                  }


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
                        // ✅ 이미지 및 마스킹 설정 UI 추가
                        if (imageUrlToDisplay != null) // Display image if URL is determined
                          Align( // 이미지와 마스킹 UI를 가운데 정렬 또는 봇 메시지 위치에 맞춤
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              // ✅ 너비 제약 추가
                              width: imageContainerWidth, // 계산된 너비 적용
                              margin: EdgeInsets.only(
                                  top: 10,
                                  left: isUser ? 0 : profileImageSize + 8, // 봇 프로필 아바타 공간 고려
                                  right: isUser ? profileImageSize + 8 : 0, // 사용자 프로필 아바타 공간 고려
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC0E6FF), width: 1),
                                boxShadow: const [ // prefer_const_constructors 경고 해결
                                  BoxShadow(
                                    color: Color.fromARGB(13, 0, 0, 0),
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '진단 사진 (${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일 ${DateTime.now().hour}시 ${DateTime.now().minute}분 촬영)', // 실제 촬영 시간으로 변경 필요
                                    style: GoogleFonts.notoSansKr(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 10),
                                  // 이미지 표시
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrlToDisplay, // Use the determined image URL
                                      width: imageContainerWidth - 24, // 컨테이너 패딩 제외
                                      height: imageContainerWidth - 24, // 1:1 비율 유지를 위해 너비와 동일하게 설정
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(
                                          width: imageContainerWidth - 24,
                                          height: imageContainerWidth - 24,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return SizedBox(
                                          width: imageContainerWidth - 24,
                                          height: imageContainerWidth - 24,
                                          child: Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // 마스크 설정 섹션
                                  Text(
                                    '마스크 설정',
                                    style: GoogleFonts.notoSansKr(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[800]),
                                  ),
                                  const Divider(color: Colors.grey, thickness: 0.5),
                                  _buildMaskSettingSwitch(
                                    '충치/치아/위생 관련',
                                    _currentMaskSettings['충치/치아/위생 관련']!,
                                    (bool newValue) {
                                      setState(() {
                                        _currentMaskSettings['충치/치아/위생 관련'] = newValue;
                                        if (newValue) { // 활성화 시 다른 스위치 비활성화
                                          _currentMaskSettings['치석/보철물'] = false;
                                          _currentMaskSettings['치아번호'] = false;
                                        }
                                        print('충치/치아/위생 관련 스위치 상태: $newValue');
                                      });
                                    },
                                  ),
                                  _buildMaskSettingSwitch(
                                    '치석/보철물',
                                    _currentMaskSettings['치석/보철물']!,
                                    (bool newValue) {
                                      setState(() {
                                        _currentMaskSettings['치석/보철물'] = newValue;
                                        if (newValue) { // 활성화 시 다른 스위치 비활성화
                                          _currentMaskSettings['충치/치아/위생 관련'] = false;
                                          _currentMaskSettings['치아번호'] = false;
                                        }
                                        print('치석/보철물 스위치 상태: $newValue');
                                      });
                                    },
                                  ),
                                  _buildMaskSettingSwitch(
                                    '치아번호',
                                    _currentMaskSettings['치아번호']!,
                                    (bool newValue) {
                                      setState(() {
                                        _currentMaskSettings['치아번호'] = newValue;
                                        if (newValue) { // 활성화 시 다른 스위치 비활성화
                                          _currentMaskSettings['충치/치아/위생 관련'] = false;
                                          _currentMaskSettings['치석/보철물'] = false;
                                        }
                                        print('치아번호 스위치 상태: $newValue');
                                      });
                                    },
                                  ),
                                ],
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
                                BoxShadow( // prefer_const_constructors 경고 해결
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
