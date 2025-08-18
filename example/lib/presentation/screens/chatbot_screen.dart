// chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'package:flutter/services.dart';
import 'chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⬅ 웹 폭 고정용

// 🎨 통일 팔레트
class _Palette {
  static const primary       = Color(0xFF3869A8); // 기준색
  static const primaryDark   = Color(0xFF2D4F84);
  static const primaryLight  = Color(0xFF6FA1D9);
  static const bgSoft        = Color(0xFFEAF4FF); // 전체 배경/카드 배경 톤
  static const surface       = Colors.white;

  // 말풍선/보더(밝은 블루 계열)
  static const bubbleUser    = Color.fromARGB(255, 146, 188, 240);
  static const bubbleBot     = Color(0xFFEFF5FC);
  static const borderUser    = Color.fromARGB(255, 36, 130, 230);
  static const borderBot     = Color(0xFFCCE1F6);

  // 입력창/테두리
  static const fieldFill     = Color(0xFFF7FAFF);
  static const fieldBorder   = Color(0xFFCFE2F6);
  static const fieldFocus    = primaryLight;

  // 스위치/버튼
  static const sendBtn       = primary;
  static const chipSelected  = primary;
  static const chipUnselect  = Color(0xFFE6EEF8);

  // 텍스트
  static const textPrimary   = Colors.black87;
  static const textSecondary = Colors.black54;
}

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
  static const double kWebMaxWidth = 600; // ⬅ 웹 고정 폭

  // ✅ 알림 팝업 상태(홈/대시보드 패턴)
  bool _isNotificationPopupVisible = false;
  final List<String> _notifications = const [
    '새로운 진단 결과가 도착했습니다.',
    '예약이 내일로 예정되어 있습니다.',
    '프로필 업데이트를 완료해주세요.',
  ];
  void _toggleNotificationPopup() {
    setState(() => _isNotificationPopupVisible = !_isNotificationPopupVisible);
  }
  void _closeNotificationPopup() {
    if (_isNotificationPopupVisible) {
      setState(() => _isNotificationPopupVisible = false);
    }
  }

  // 마스킹 스위치 상태
  final Map<String, bool> _currentMaskSettings = {
    '충치/치아/위생 관련': false,
    '치석/보철물': false,
    '치아번호': false,
  };

  @override
  void initState() {
    super.initState();
    _sendBtnAnimCtr =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _sendBtnAnimCtr, curve: Curves.easeOut));
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
    await Provider.of<ChatbotViewModel>(context, listen: false).sendMessage(trimmed);
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
          color: isUser ? const Color(0xFFD7E6F6) : const Color(0xFFCFE2F6),
          shape: BoxShape.circle,
          border: Border.all(
            color: isUser ? _Palette.primaryLight : _Palette.primary,
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

  // ✅ 면책사항(입력창 아래)
  Widget _buildDisclaimerBottom() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Center(
        child: Text(
          '※ 본 챗봇은 참고용 정보만 제공하며, 정확한 진단은 의료 전문가와 상담하시기 바랍니다.',
          style: GoogleFonts.notoSansKr(
            fontSize: 12.5,
            color: _Palette.textSecondary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ✅ 마스크 설정 스위치
  Widget _buildMaskSettingSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.notoSansKr(fontSize: 14, color: _Palette.textPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _Palette.primary,
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChatbotViewModel>().messages;
    final isLoading = context.watch<ChatbotViewModel>().isLoading;

    // ⬇ 컨텐츠 기준 너비(웹이면 600 고정, 모바일은 화면 너비)
    final double contentBaseWidth =
        kIsWeb ? kWebMaxWidth : MediaQuery.of(context).size.width;
    final double imageContainerWidth = contentBaseWidth * 0.6; // 이미지 카드 최대 폭

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('앱 종료', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold)),
              content: Text('앱을 종료하시겠습니까?', style: GoogleFonts.notoSansKr()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('취소', style: GoogleFonts.notoSansKr(color: _Palette.primaryLight))),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('종료', style: GoogleFonts.notoSansKr(color: _Palette.primary))),
              ],
            ),
          );
          if (shouldExit == true) SystemNavigator.pop();
        }
      },
      child: GestureDetector( // ⬅ 바깥 탭 시 알림 팝업 닫기
        behavior: HitTestBehavior.translucent,
        onTap: _closeNotificationPopup,
        child: Scaffold(
          backgroundColor: _Palette.surface,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors:[_Palette.primaryDark, _Palette.primary], // ✅ 블루 그라데이션
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
              // ✅ 알림 버튼 + 배지
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                      tooltip: '알림',
                      onPressed: _toggleNotificationPopup,
                    ),
                    if (_notifications.isNotEmpty)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent, // 알림은 가독성 위해 유지
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${_notifications.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // ✅ Stack: 본문(웹 폭 고정) + 알림 팝업 오버레이
          body: Stack(
            children: [
              SafeArea(
                child: kIsWeb
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
                          child: _buildChatBody(messages, isLoading, imageContainerWidth),
                        ),
                      )
                    : _buildChatBody(messages, isLoading, imageContainerWidth),
              ),

              // ✅ 알림 팝업 (상단-오른쪽)
              if (_isNotificationPopupVisible)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: _Palette.surface,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.all(12),
                            child: _notifications.isEmpty
                                ? const Text('알림이 없습니다.',
                                    style: TextStyle(color: _Palette.textSecondary))
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _notifications
                                        .map(
                                          (msg) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.notifications_active_outlined,
                                                  color: _Palette.primaryLight,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    msg,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: _Palette.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 본문(웹/모바일 공통) – 이미지 카드 폭은 [imageContainerWidth] 사용
  Widget _buildChatBody(List messages, bool isLoading, double imageContainerWidth) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (_, idx) {
              final msg = messages[idx];
              final bool isUser = msg.role == 'user';

              String? imageUrlToDisplay;
              if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
                if (_currentMaskSettings['충치/치아/위생 관련'] == true) {
                  imageUrlToDisplay = msg.imageUrls!['model1'];
                } else if (_currentMaskSettings['치석/보철물'] == true) {
                  imageUrlToDisplay = msg.imageUrls!['model2'];
                } else if (_currentMaskSettings['치아번호'] == true) {
                  imageUrlToDisplay = msg.imageUrls!['model3'];
                }
                imageUrlToDisplay ??= msg.imageUrls!['original'];
                imageUrlToDisplay ??= msg.imageUrls!.values.first;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) _buildProfileAvatar(isUser: false),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: ChatBubble(
                            message: msg.content,
                            isUser: isUser,
                            bubbleColor:
                                isUser ? _Palette.bubbleUser : _Palette.bubbleBot,
                            borderColor:
                                isUser ? _Palette.borderUser : _Palette.borderBot,
                            textStyle:
                                GoogleFonts.notoSansKr(fontSize: 15, color: _Palette.textPrimary),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser) _buildProfileAvatar(isUser: true),
                      ],
                    ),
                    if (imageUrlToDisplay != null)
                      Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: imageContainerWidth,
                          margin: EdgeInsets.only(
                            top: 10,
                            left: isUser ? 0 : profileImageSize + 8,
                            right: isUser ? profileImageSize + 8 : 0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _Palette.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _Palette.borderBot, width: 1),
                            boxShadow: const [
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
                                '진단 사진 (${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일 ${DateTime.now().hour}시 ${DateTime.now().minute}분 촬영)',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 13, color: _Palette.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrlToDisplay,
                                  width: imageContainerWidth - 24,
                                  height: imageContainerWidth - 24, // 1:1
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: imageContainerWidth - 24,
                                      height: imageContainerWidth - 24,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: _Palette.primary,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return SizedBox(
                                      width: imageContainerWidth - 24,
                                      height: imageContainerWidth - 24,
                                      child: Center(
                                        child: Icon(Icons.broken_image,
                                            color: Colors.grey[400], size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                '마스크 설정',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _Palette.primaryDark),
                              ),
                              const Divider(color: _Palette.fieldBorder, thickness: 0.8),
                              _buildMaskSettingSwitch(
                                '충치/치아/위생 관련',
                                _currentMaskSettings['충치/치아/위생 관련']!,
                                (bool newValue) {
                                  setState(() {
                                    _currentMaskSettings['충치/치아/위생 관련'] = newValue;
                                    if (newValue) {
                                      _currentMaskSettings['치석/보철물'] = false;
                                      _currentMaskSettings['치아번호'] = false;
                                    }
                                  });
                                },
                              ),
                              _buildMaskSettingSwitch(
                                '치석/보철물',
                                _currentMaskSettings['치석/보철물']!,
                                (bool newValue) {
                                  setState(() {
                                    _currentMaskSettings['치석/보철물'] = newValue;
                                    if (newValue) {
                                      _currentMaskSettings['충치/치아/위생 관련'] = false;
                                      _currentMaskSettings['치아번호'] = false;
                                    }
                                  });
                                },
                              ),
                              _buildMaskSettingSwitch(
                                '치아번호',
                                _currentMaskSettings['치아번호']!,
                                (bool newValue) {
                                  setState(() {
                                    _currentMaskSettings['치아번호'] = newValue;
                                    if (newValue) {
                                      _currentMaskSettings['충치/치아/위생 관련'] = false;
                                      _currentMaskSettings['치석/보철물'] = false;
                                    }
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
                            color: _Palette.textSecondary, fontSize: 15));
                  },
                  onEnd: () => setState(() {}),
                ),
              ],
            ),
          ),
        // ✅ 입력창 + (바로 아래) 면책문구
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '메시지를 작성해주세요',
                          hintStyle: GoogleFonts.notoSansKr(color: _Palette.textSecondary),
                          filled: true,
                          fillColor: _Palette.fieldFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide:
                                  const BorderSide(color: _Palette.fieldBorder, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide:
                                  const BorderSide(color: _Palette.fieldFocus, width: 2)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        style: GoogleFonts.notoSansKr(fontSize: 16, color: _Palette.textPrimary),
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
                              color: _Palette.sendBtn,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ]),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(Icons.send, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildDisclaimerBottom(), // ⬅ 입력창 바로 아래
              ],
            ),
          ),
        ),
      ],
    );
  }
}

