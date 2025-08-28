// lib/presentation/screens/chatbot_screen.dart
// (중첩 Scaffold 대응 + 고정폭 정렬, 원본 + 마스크 레이어링)

import 'dart:typed_data';                          // ✅ 추가: 바이트 렌더링
import 'package:http/http.dart' as http;           // ✅ 추가: 직접 다운로드용

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import 'package:flutter/services.dart';
import 'chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 🎨 통일 팔레트
class _Palette {
  static const primary       = Color(0xFF3869A8);
  static const primaryDark   = Color(0xFF2D4F84);
  static const primaryLight  = Color(0xFF6FA1D9);
  static const bgSoft        = Color(0xFFEAF4FF);
  static const surface       = Colors.white;

  // 말풍선/보더
  static const bubbleUser    = Color.fromARGB(255, 146, 188, 240);
  static const bubbleBot     = Color(0xFFEFF5FC);
  static const borderUser    = Color.fromARGB(255, 36, 130, 230);
  static const borderBot     = Color(0xFFCCE1F6);

  // 입력창/테두리
  static const fieldFill     = Color(0xFFF7FAFF);
  static const fieldBorder   = Color(0xFFCFE2F6);
  static const fieldFocus    = primaryLight;

  // 버튼
  static const sendBtn       = primary;

  // 텍스트
  static const textPrimary   = Colors.black87;
  static const textSecondary = Colors.black54;
}

class ChatbotScreen extends StatefulWidget {
  // ✅ 추가: baseUrl을 화면에서 직접 받음
  final String baseUrl;

  const ChatbotScreen({super.key, required this.baseUrl});

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
  static const double kWebMaxWidth = 600; // ⬅ 웹 폭 고정

  // ✅ 알림 팝업 상태
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

  // ✅ 간단한 마크다운 감지
  bool _looksLikeMarkdown(String s) {
    if (s.isEmpty) return false;
    final md = RegExp(r'(^|\n)\s*(#{1,6}\s|[-*+]\s|\d+\.\s|>\s|[-*_]{3,})|[*_`~]{1,}');
    return md.hasMatch(s);
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
                  'assets/images/dentibot.png',
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
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors:[_Palette.primaryDark, _Palette.primary],
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
                            color: Colors.redAccent,
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

          // ✅ 본문 + 알림 팝업(오버레이)
          body: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kWebMaxWidth),
                    child: Column(
                      children: [
                        // ⬇ 메시지 리스트 (남는 높이 모두 차지)
                        Expanded(
                          child: _buildChatBody(messages, isLoading, imageContainerWidth),
                        ),
                        // ⬇ 입력창 (body 안에 포함: 탭바와 중첩되지 않음)
                        _buildInputArea(),
                      ],
                    ),
                  ),
                ),
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: isLoading ? messages.length + 1 : messages.length,
      itemBuilder: (_, idx) {
        // ✅ 로딩 셀
        if (idx == messages.length && isLoading) {
          return Padding(
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
          );
        }

        final msg = messages[idx];
        final bool isUser = msg.role == 'user';
        final bool renderMd = !isUser && _looksLikeMarkdown(msg.content);

        // ▼ 보내온 이미지 URL들
        Map<String, String>? urls = msg.imageUrls;
        final originalUrl = urls?['original'];
        final diseaseUrl  = urls?['model1'] ?? urls?['xmodel1'];
        final hygieneUrl  = urls?['model2'] ?? urls?['xmodel2'];
        final toothUrl    = urls?['model3']; // X-ray엔 보통 없음

        final hasAnyImage = originalUrl != null ||
            diseaseUrl != null || hygieneUrl != null || toothUrl != null;

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
                      textStyle: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        color: _Palette.textPrimary,
                      ),
                      renderMarkdown: renderMd,
                    ),
                  ),
                  if (isUser) const SizedBox(width: 8),
                  if (isUser) _buildProfileAvatar(isUser: true),
                ],
              ),

              // ▼ 이미지 카드: 원본 + 마스크 레이어링
              if (hasAnyImage)
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
                          child: _LayeredNetImages(
                            originalUrl: originalUrl,
                            model1Url: diseaseUrl,
                            model2Url: hygieneUrl,
                            model3Url: toothUrl,
                            showModel1: _currentMaskSettings['충치/치아/위생 관련'] ?? false,
                            showModel2: _currentMaskSettings['치석/보철물'] ?? false,
                            showModel3: _currentMaskSettings['치아번호'] ?? false,
                            width: imageContainerWidth - 24,
                            height: imageContainerWidth - 24, // 정사각 카드
                            // ✅ 추가: baseUrl 전달
                            baseUrl: widget.baseUrl,
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
    );
  }

  // ✅ 입력창: body 안에 배치(부모 탭바와 충돌 방지), 웹에서도 고정 폭 정렬 유지
  Widget _buildInputArea() {
    return SafeArea(
      top: false,
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
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: _Palette.fieldBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(color: _Palette.fieldFocus, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            _buildDisclaimerBottom(),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────
/// 레이어링 이미지 위젯: 원본을 바닥에 깔고 마스크를 Stack으로 ON/OFF
/// 인증이 필요한 이미지도 보이도록 Authorization 헤더 사용
/// ✅ 모바일 이슈 해결: 상대경로 보정 + 바이트 로딩 + 리다이렉트 추적
/// ─────────────────────────────────────────────────────────
class _LayeredNetImages extends StatefulWidget {
  final String? originalUrl;
  final String? model1Url;
  final String? model2Url;
  final String? model3Url;
  final bool showModel1;
  final bool showModel2;
  final bool showModel3;
  final double width;
  final double height;
  // ✅ 추가: baseUrl을 직접 전달받음
  final String baseUrl;

  const _LayeredNetImages({
    super.key,
    required this.originalUrl,
    required this.model1Url,
    required this.model2Url,
    required this.model3Url,
    required this.showModel1,
    required this.showModel2,
    required this.showModel3,
    required this.width,
    required this.height,
    required this.baseUrl,
  });

  @override
  State<_LayeredNetImages> createState() => _LayeredNetImagesState();
}

class _LayeredNetImagesState extends State<_LayeredNetImages> {
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (!mounted) return;
    setState(() {
      _headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    });
  }

  /// ⬇ 상대경로('/images/...')를 baseUrl과 합쳐 절대 URL로 보정
  /// baseUrl이 http://host/api 라면 정적 파일은 http://host 로 접근하도록 /api 제거
  String _absUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final staticBase = widget.baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) return '$staticBase$url';
    return '$staticBase/$url';
  }

  // ✅ 리다이렉트가 있어도 Authorization을 계속 붙여서 추적
  Future<Uint8List> _loadBytesWithAuth(String startUrl, Map<String, String> headers) async {
    Uri current = Uri.parse(startUrl);
    for (int i = 0; i < 5; i++) {
      final res = await http.get(current, headers: headers);

      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
      if (res.statusCode >= 300 && res.statusCode < 400) {
        final loc = res.headers['location'];
        if (loc == null) break;
        current = Uri.parse(loc).isAbsolute ? Uri.parse(loc) : current.resolve(loc);
        continue;
      }
      throw Exception('Image fetch failed ${res.statusCode} for $current');
    }
    throw Exception('Too many redirects for $startUrl');
  }

  @override
  Widget build(BuildContext context) {
    if (_headers == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final headers = _headers!;

    Widget net(String? raw, {bool visible = true}) {
      if (raw == null || raw.isEmpty) return const SizedBox.shrink();
      final url = _absUrl(raw);
      final cacheBustKey = '${url}_${headers['Authorization'] ?? ''}';

      return Visibility(
        visible: visible,
        child: FutureBuilder<Uint8List>(
          key: ValueKey(cacheBustKey),
          future: _loadBytesWithAuth(url, headers),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                width: widget.width, height: widget.height,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return SizedBox(
                width: widget.width, height: widget.height,
                child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
              );
            }
            return Image.memory(
              snap.data!,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain, // 원본 비율 유지
            );
          },
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ 바닥에 원본 고정
          net(widget.originalUrl, visible: true),

          // ✅ 마스크(알파 PNG여야 원본이 비친다)
          if (widget.model1Url != null)
            net(widget.model1Url, visible: widget.showModel1),
          if (widget.model2Url != null)
            net(widget.model2Url, visible: widget.showModel2),
          if (widget.model3Url != null)
            net(widget.model3Url, visible: widget.showModel3),
        ],
      ),
    );
  }
}
