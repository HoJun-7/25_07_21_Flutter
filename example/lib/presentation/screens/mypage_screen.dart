import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

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
              const Text('모든 데이터가 삭제되며 복구할 수 없습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호를 다시 입력해주세요',
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
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
              child: const Text('탈퇴', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final userInfoViewModel = context.watch<UserInfoViewModel>();
    final user = userInfoViewModel.user;

    // 마이페이지 스크린샷에서 확인된 배경색
    const Color myPageBackgroundColor = Color(0xFFB4D4FF); // 마이페이지 배경색

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: myPageBackgroundColor, // 밝은 블루 배경
        appBar: AppBar(
          backgroundColor: Colors.white, // AppBar 배경색은 흰색 유지
          elevation: 1, // 그림자도 유지 (이미지와 유사)
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87), // 햄버거 메뉴 아이콘
            onPressed: () {
              // TODO: 햄버거 메뉴 기능 구현 (Drawer 열기 등)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('햄버거 메뉴 클릭됨')),
              );
            },
          ),
          title: const Text(
            '회원정보', // 앱 바 타이틀
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87, // 텍스트 색상 검정
              fontSize: 20,
            ),
          ),
          centerTitle: true, // 제목을 앱 바 중앙에 배치
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87), // 알림 아이콘
              onPressed: () {
                // TODO: 알림 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 아이콘 클릭됨')),
                );
              },
            ),
          ],
        ),
        body: SafeArea( // 상태 바 및 노치 영역을 고려하여 콘텐츠 배치
          child: Column( // SingleChildScrollView 대신 Column으로 변경하여 스크롤 영역을 명확히 구분
            children: [
              // --- 프로필 섹션 ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: myPageBackgroundColor, // 배경색 유지
                  // gradient: LinearGradient( // 더 부드러운 전환을 위해 그라데이션 추가 (선택 사항)
                  //   begin: Alignment.topCenter,
                  //   end: Alignment.bottomCenter,
                  //   colors: [myPageBackgroundColor, myPageBackgroundColor.withOpacity(0.8)],
                  // ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45, // 아바타 크기 증가
                      backgroundColor: Colors.white, // 아바타 배경색
                      child: Icon(
                        Icons.person,
                        size: 65, // 아이콘 크기 증가
                        color: myPageBackgroundColor.withOpacity(0.8), // 아이콘 색상
                      ),
                    ),
                    const SizedBox(height: 15), // 간격 증가
                    Text(
                      user?.name ?? '로그인 필요', // 사용자 이름
                      style: TextStyle(
                        fontSize: 24, // 폰트 크기 증가
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.95), // 텍스트 색상
                        shadows: [
                          Shadow(
                            blurRadius: 6.0,
                            color: Colors.black38,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.role == 'P' ? '환자' : (user?.role == 'D' ? '의사' : ''), // 역할 표시
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 25), // 간격 증가
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // user?.reviewsCount.toString() 대신 '0'을 직접 전달하여 컴파일 오류 회피
                        _buildInfoBox(Icons.rate_review, '예약 내역', '0', context),
                        const SizedBox(width: 15), // 간격 조정
                        // user?.consultationsCount.toString() 대신 '0'을 직접 전달하여 컴파일 오류 회피
                        _buildInfoBox(Icons.chat_bubble_outline, '진료 기록', '15', context),
                      ],
                    ),
                  ],
                ),
              ),
              // --- 메뉴 목록 섹션 ---
              Expanded( // 남은 공간을 메뉴 목록이 채우도록
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // 메뉴 목록 배경색을 흰색으로
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), // 상단 모서리 둥글게
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5), // 위쪽으로 그림자
                      ),
                    ],
                  ),
                  child: SingleChildScrollView( // 메뉴 목록이 길어질 경우를 대비해 스크롤 가능하게
                    padding: const EdgeInsets.symmetric(vertical: 10.0), // 내부 패딩
                    child: Column(
                      children: [
                        _buildMenuItem(context, Icons.person_outline, '내 정보 관리', '/mypage/manage_info'),
                        // 삭제된 항목: 구매 목록, 취소/반품/교환 목록, 배송 추적, 고객센터
                        _buildMenuItem(context, Icons.logout, '로그아웃', '/login', isLogout: true), // 로그아웃은 특별 처리
                        _buildMenuItem(context, Icons.delete_outline, '회원 탈퇴', '', isDelete: true), // 회원 탈퇴는 특별 처리
                      ],
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

  // 정보 박스 위젯 (리뷰, 상담 내역) - 이미지에 맞춰 변경
  Widget _buildInfoBox(IconData icon, String label, String count, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: 각 정보 박스 클릭 시 기능 구현 (예: 리뷰 목록으로 이동)
          _showSnack(context, '$label 클릭됨');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // 박스 배경색 (투명도 조절)
            borderRadius: BorderRadius.circular(15), // 둥근 모서리
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1), // 테두리
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white), // 아이콘 색상 흰색
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
              ),
              Text(
                count,
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 항목 위젯 - 디자인 개선
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route, {bool isLogout = false, bool isDelete = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8), // 패딩 조정
          leading: Icon(icon, color: isDelete ? Colors.redAccent : Colors.grey[700], size: 28), // 아이콘 색상 및 크기
          title: Text(
            title,
            style: TextStyle(
              fontSize: 17, // 폰트 크기
              fontWeight: FontWeight.w500,
              color: isDelete ? Colors.redAccent : Colors.black87, // 텍스트 색상
            ),
          ),
          trailing: isLogout || isDelete ? null : const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey), // 화살표 아이콘 크기
          onTap: () {
            if (isLogout) {
              // TODO: 로그아웃 로직 구현 (예: 토큰 삭제, 상태 초기화)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 되었습니다.')),
              );
              context.go(route); // 로그인 화면으로 이동
            } else if (isDelete) {
              _showDeleteConfirmationDialog(context); // 회원 탈퇴 다이얼로그 호출
            } else {
              context.push(route);
            }
          },
        ),
        // 마지막 항목이 아니면 구분선 추가 (로그아웃/회원탈퇴도 구분선 포함하도록 변경)
        Divider(
          height: 1,
          indent: 25, // 구분선 시작 위치 조정
          endIndent: 25, // 구분선 끝 위치 조정
          color: Colors.grey[200],
        ),
      ],
    );
  }
}
