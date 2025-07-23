import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  final String baseUrl;

  const LoginScreen({
    super.key,
    required this.baseUrl,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 텍스트 필드 컨트롤러
  final TextEditingController registerIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // 선택된 역할 ('P' for Patient, 'D' for Doctor)
  String _selectedRole = 'P';

  /// 로그인 처리 함수
  Future<void> login() async {
    final authViewModel = context.read<AuthViewModel>();
    final userInfoViewModel = context.read<UserInfoViewModel>();

    final registerId = registerIdController.text.trim();
    final password = passwordController.text.trim();

    // 아이디 또는 비밀번호가 비어있는 경우 스낵바 표시
    if (registerId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')),
      );
      return;
    }

    try {
      // AuthViewModel을 통해 로그인 시도
      final user = await authViewModel.loginUser(registerId, password, _selectedRole);

      if (user != null) {
        // 로그인 성공 시 UserInfoViewModel에 사용자 정보 로드
        userInfoViewModel.loadUser(user);
        // 사용자 역할에 따라 다른 화면으로 이동
        if (user.role == 'D') {
          context.go('/d_home'); // 의사 홈 화면
        } else {
          context.go('/home', extra: {'userId': user.registerId}); // 환자 홈 화면
        }
      } else {
        // 로그인 실패 시 에러 메시지 표시
        final error = authViewModel.errorMessage ?? '로그인 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      // 로그인 처리 중 예외 발생 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 처리 중 오류 발생: ${e.toString()}')),
      );
    }
  }

  /// 뒤로가기 버튼 눌렀을 때 앱 종료 확인 다이얼로그
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // 취소 버튼
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // 종료 버튼
            child: const Text('종료'),
          ),
        ],
      ),
    );
    return shouldExit ?? false; // 다이얼로그가 닫혔을 때 null 방지
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 뒤로가기 버튼 처리
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F7FA), // 밝은 아쿠아 블루 배경 (치아 이미지와 어울리게)
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // 모서리 둥글기 조정
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 그림자 색상 및 투명도 조정
                    blurRadius: 15, // 그림자 블러 반경
                    offset: const Offset(0, 8), // 그림자 오프셋
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고 이미지 (치아 캐릭터 이미지로 대체)
                  Image.asset(
                    'assets/tooth_character.png', // 사용자 제공 이미지 경로
                    width: 150, // 이미지 크기 조정
                    height: 150,
                  ),
                  const SizedBox(height: 32), // 간격 증가

                  // 역할 선택 카드
                  Row(
                    children: [
                      _buildRoleCard('환자', 'P', Icons.person),
                      const SizedBox(width: 16), // 간격 증가
                      _buildRoleCard('의사', 'D', Icons.medical_services),
                    ],
                  ),

                  const SizedBox(height: 32), // 간격 증가

                  // 아이디 입력 필드
                  TextField(
                    controller: registerIdController,
                    decoration: InputDecoration(
                      labelText: '아이디',
                      hintText: '아이디를 입력해주세요', // 힌트 텍스트 추가
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5F97F7)), // 아이콘 색상
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true, // 배경 채우기
                      fillColor: Colors.grey[100], // 배경 색상
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력 필드
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '비밀번호를 입력해주세요', // 힌트 텍스트 추가
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5F97F7)), // 아이콘 색상
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true, // 배경 채우기
                      fillColor: Colors.grey[100], // 배경 색상
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16), // 패딩 증가
                        backgroundColor: const Color(0xFF5F97F7), // 진한 블루
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5, // 버튼 그림자 추가
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), // 폰트 크기 및 굵기
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // 간격 조정

                  // 아이디/비밀번호 찾기 및 회원가입 버튼들을 위한 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: 아이디 찾기 화면으로 이동
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('아이디 찾기 기능은 아직 구현되지 않았습니다.')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600], // 텍스트 색상
                        ),
                        child: const Text('아이디 찾기'),
                      ),
                      Text(
                        '|',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: 비밀번호 찾기 화면으로 이동
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('비밀번호 찾기 기능은 아직 구현되지 않았습니다.')),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600], // 텍스트 색상
                        ),
                        child: const Text('비밀번호 찾기'),
                      ),
                      Text(
                        '|',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'), // 회원가입 화면으로 이동
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF5F97F7), // 회원가입 버튼 색상
                          textStyle: const TextStyle(fontWeight: FontWeight.bold), // 굵게
                        ),
                        child: const Text('회원가입'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 역할 선택 카드 위젯 빌더
  Widget _buildRoleCard(String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;

    Color selectedColor;
    Color borderColor;
    Color iconColor;
    Color textColor;

    // 역할에 따른 색상 설정
    if (roleValue == 'P') {
      selectedColor = const Color(0xFFFFF9C4); // 밝은 노란색
      borderColor = const Color(0xFFFFD54F); // 진한 노란색
      iconColor = isSelected ? const Color(0xFFFFB300) : Colors.grey[600]!; // 아이콘 색상
      textColor = isSelected ? Colors.black87 : Colors.grey[700]!; // 텍스트 색상
    } else {
      selectedColor = const Color(0xFFDCEDC8); // 밝은 연두색
      borderColor = const Color(0xFFAED581); // 진한 연두색
      iconColor = isSelected ? const Color(0xFF689F38) : Colors.grey[600]!; // 아이콘 색상
      textColor = isSelected ? Colors.black87 : Colors.grey[700]!; // 텍스트 색상
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue), // 탭 시 역할 변경
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
          curve: Curves.easeInOut, // 애니메이션 커브
          padding: const EdgeInsets.symmetric(vertical: 18), // 패딩 조정
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.grey[50], // 선택 여부에 따른 배경색
            borderRadius: BorderRadius.circular(16), // 모서리 둥글기
            border: Border.all(
              color: isSelected ? borderColor : Colors.grey[300]!, // 선택 여부에 따른 테두리 색상
              width: isSelected ? 2.5 : 1, // 선택 여부에 따른 테두리 두께
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.3), // 선택 시 그림자
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 36), // 아이콘 크기
              const SizedBox(height: 10), // 간격
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700, // 텍스트 굵기
                  fontSize: 16, // 텍스트 크기
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    registerIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
