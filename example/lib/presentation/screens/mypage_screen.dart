import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';

class MyPageScreen extends StatefulWidget {
  final String baseUrl;
  const MyPageScreen({super.key, required this.baseUrl});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _diagnosisCount = 0;
  int _reservationCount = 0;

  // ===== 알림 배지/팝업 =====
  bool _isNotificationPopupVisible = false;
  final List<String> _notifications = const [
    '새로운 진단 결과가 도착했습니다.',
    '예약이 내일로 예정되어 있습니다.',
    '프로필 업데이트를 완료해주세요.',
  ];
  void _toggleNotificationPopup() =>
      setState(() => _isNotificationPopupVisible = !_isNotificationPopupVisible);
  void _closeNotificationPopup() {
    if (_isNotificationPopupVisible) {
      setState(() => _isNotificationPopupVisible = false);
    }
  }
  // ========================

  // ===== 디자인 상수 (스샷 느낌 맞춤) =====
  static const Color _bg = Color(0xFFB4D4FF);
  static const double kBodyMaxWidth = 980;     // 전체 본문 최대 폭
  // static const double kInfoRowMaxWidth = 640;  // ❌ 사용 안함 (아래 카드와 동일 폭 사용)
  static const double kMenuCardMaxWidth = 560; // ✅ 상단/하단 모두 이 값으로 통일
  static const double kTopSpacerDesktop = 68;  // 상단에서 살짝 내리기
  static const double kInfoTileHeight = 110;
  static const double kMenuMinHeight = 420;    // 메뉴 카드 최소 높이(넉넉하게)
  static const double kRadius = 22;
  // =====================================

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final user = context.read<UserInfoViewModel>().user;
    if (user == null) return;

    try {
      // 진료 기록
      final diagnosisUri = Uri.parse(
          '${widget.baseUrl}/inference_results?user_id=${user.registerId}&role=P');
      final diagnosisResponse = await http.get(diagnosisUri);
      if (diagnosisResponse.statusCode == 200) {
        final List<dynamic> results = jsonDecode(diagnosisResponse.body);
        _diagnosisCount = results.length;
      }

      // 예약 내역
      final reservationUri =
          Uri.parse('${widget.baseUrl}/consult/list?user_id=${user.registerId}');
      final reservationResponse = await http.get(reservationUri);
      if (reservationResponse.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(reservationResponse.body);
        List<dynamic> reservations = decoded['consults'] ?? [];
        final String me = '${user.registerId}';
        if (user.role == 'P') {
          reservations = reservations.where((e) {
            final m = e as Map<String, dynamic>;
            final String? uid =
                (m['user_id'] ?? m['userId'] ?? m['patient_id'])?.toString();
            return uid == me;
          }).toList();
        }
        _reservationCount = reservations.length;
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserInfoViewModel>().user;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeNotificationPopup,
        child: Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text('회원정보',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            centerTitle: true,
            actions: [
              // 스샷처럼 배지가 달린 종 아이콘
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.black87),
                      onPressed: _toggleNotificationPopup,
                      tooltip: '알림',
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
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kBodyMaxWidth),
                    child: _buildMainColumn(context, user),
                  ),
                ),
              ),

              // 알림 팝업
              if (_isNotificationPopupVisible)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            width: 280,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _notifications
                                  .map(
                                    (msg) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.notifications_active_outlined,
                                              color: Colors.blueAccent, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(msg,
                                                style: const TextStyle(
                                                    fontSize: 14, color: Colors.black87)),
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

  Widget _buildMainColumn(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: kTopSpacerDesktop),

          // 프로필
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 62, color: _bg.withOpacity(0.8)),
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? '로그인 필요',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.role == 'P' ? '환자' : (user?.role == 'D' ? '의사' : ''),
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          // 예약/진료 2칸 박스 (가운데, 폭 제한) — 메뉴 카드와 동일 폭으로 통일
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMenuCardMaxWidth), // ✅ 통일
              child: Row(
                children: [
                  Expanded(
                    child: _infoTile(
                      icon: Icons.edit_note,
                      label: '예약 내역',
                      count: '$_reservationCount',
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _infoTile(
                      icon: Icons.chat_bubble_outline,
                      label: '진료 기록',
                      count: '$_diagnosisCount',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 메뉴 카드 (가운데, 더 좁고, 세로 넉넉)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMenuCardMaxWidth),
              child: Container(
                constraints: const BoxConstraints(minHeight: kMenuMinHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _menuItem(context, Icons.person_outline, '개인정보 수정', '/reauth'),
                    _divider(),
                    _menuItem(context, Icons.logout, '로그아웃', '/login', isLogout: true),
                    _divider(),
                    _menuItem(context, Icons.delete_outline, '회원 탈퇴', '', isDelete: true),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 상단 2칸 정보 타일
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String count,
  }) {
    return Container(
      height: kInfoTileHeight,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withOpacity(0.96),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // 메뉴 아이템/구분선
  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEDEEF2));

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    bool isLogout = false,
    bool isDelete = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(
        icon,
        color: isDelete ? Colors.redAccent : Colors.grey[800],
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w500,
          color: isDelete ? Colors.redAccent : Colors.black87,
        ),
      ),
      trailing:
          (isLogout || isDelete) ? null : const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: () {
        if (title == '개인정보 수정') {
          context.push(route);
        } else if (isLogout) {
          context.read<UserInfoViewModel>().clearUser();
          _showSnack(context, '로그아웃 되었습니다.');
          context.go(route);
        } else if (isDelete) {
          _showDeleteConfirmationDialog(context);
        } else {
          context.push(route);
        }
      },
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final userInfoViewModel = context.read<UserInfoViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    if (userInfoViewModel.user == null) {
      _showSnack(context, '로그인 정보가 없습니다.');
      return;
    }
    final passwordController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            '회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('정말로 회원 탈퇴하시겠습니까?', style: TextStyle(fontSize: 15)),
              const Text(
                '모든 데이터가 삭제되며 복구할 수 없습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호를 다시 입력해주세요',
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final registerId = userInfoViewModel.user!.registerId;
                final password = passwordController.text;
                final role = userInfoViewModel.user!.role;
                if (password.isEmpty) {
                  _showSnack(dialogContext, '비밀번호를 입력해주세요.');
                  return;
                }
                final error = await authViewModel.deleteUser(registerId, password, role);
                if (error == null) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  _showSnack(dialogContext, error);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('탈퇴',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      userInfoViewModel.clearUser();
      _showSnack(context, '회원 탈퇴가 완료되었습니다.');
      context.go('/login');
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('종료')),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}
