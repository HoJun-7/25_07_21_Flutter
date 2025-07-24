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
  final TextEditingController registerIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedRole = 'P'; // 기본 선택 역할: 환자 ('P')

  // UI에 사용할 색상 정의
  static const Color primaryBlue = Color(0xFF5F97F7); // 로그인 버튼 등 주 색상
  static const Color lightBlueBackground = Color(0xFFB4D4FF); // 화면 전체 배경색
  static const Color patientRoleColor = Color(0xFF90CAF9); // 환자 역할 선택 시 색상 (하늘색 계열)
  static const Color doctorRoleColor = Color(0xFF81C784); // 의사 역할 선택 시 색상 (초록색 계열)
  static const Color unselectedCardColor = Color(0xFFE0E0E0); // 선택되지 않은 카드 배경색

  Future<void> login() async {
    final authViewModel = context.read<AuthViewModel>();
    final userInfoViewModel = context.read<UserInfoViewModel>();

    final registerId = registerIdController.text.trim();
    final password = passwordController.text.trim();

    if (registerId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')),
      );
      return;
    }

    try {
      // 로그인 시도 전 로딩 인디케이터 표시 (선택 사항)
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (context) => const Center(child: CircularProgressIndicator()),
      // );

      final user = await authViewModel.loginUser(registerId, password, _selectedRole);

      // Navigator.of(context).pop(); // 로딩 인디케이터 숨기기

      if (user != null) {
        userInfoViewModel.loadUser(user);
        if (user.role == 'D') {
          context.go('/d_home');
        } else {
          context.go('/home', extra: {'userId': user.registerId});
        }
      } else {
        final error = authViewModel.errorMessage ?? '로그인 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      // Navigator.of(context).pop(); // 오류 발생 시 로딩 인디케이터 숨기기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 처리 중 오류 발생: ${e.toString()}')),
      );
    }
  }

  Future<bool> _onWillPop() async {
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: lightBlueBackground, // 밝은 블루 배경
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(30), // 내부 패딩 증가
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // 모서리 더 둥글게
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 그림자 색상 및 투명도 조정
                    blurRadius: 20, // 그림자 흐림 정도 증가
                    offset: const Offset(0, 10), // 그림자 위치 조정
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고
                  Image.asset(
                    'assets/icon/cdss-icon_500.png', // 실제 앱 로고 경로 사용
                    width: 120, // 로고 크기 증가
                    height: 120,
                  ),
                  const SizedBox(height: 30), // 간격 증가

                  // 역할 선택 카드
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 역할 선택 카드 중앙 정렬
                    children: [
                      _buildRoleCard('환자', 'P', Icons.personal_injury_outlined), // 아이콘 변경
                      const SizedBox(width: 15), // 간격 조정
                      _buildRoleCard('의사', 'D', Icons.medical_information_outlined), // 아이콘 변경
                    ],
                  ),

                  const SizedBox(height: 30), // 간격 증가

                  // 아이디 입력
                  TextField(
                    controller: registerIdController,
                    keyboardType: TextInputType.emailAddress, // 이메일 타입 키보드
                    decoration: InputDecoration(
                      labelText: '아이디를 입력하세요', // placeholder 텍스트
                      hintText: '', // 힌트 텍스트 추가
                      prefixIcon: const Icon(Icons.person_outline, color: primaryBlue), // 아이콘 색상 변경
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), // 모서리 더 둥글게
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true,
                      fillColor: Colors.grey[100], // 배경색 추가
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
                    ),
                  ),
                  const SizedBox(height: 20), // 간격 증가

                  // 비밀번호 입력
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호를 입력하세요',
                      hintText: '6자 이상',
                      prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue), // 아이콘 색상 변경
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), // 모서리 더 둥글게
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true,
                      fillColor: Colors.grey[100], // 배경색 추가
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
                    ),
                  ),
                  const SizedBox(height: 30), // 간격 증가

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16), // 패딩 증가
                        backgroundColor: primaryBlue, // 진한 블루
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 모서리 더 둥글게
                        ),
                        elevation: 5, // 그림자 추가
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), // 폰트 크기 및 굵기 조정
                      ),
                    ),
                  ),
                  const SizedBox(height: 15), // 간격 조정

                  // 회원가입 버튼 (순서 변경)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryBlue, width: 2), // 테두리 색상 및 굵기 조정
                        padding: const EdgeInsets.symmetric(vertical: 16), // 패딩 증가
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // 모서리 더 둥글게
                        ),
                      ),
                      child: const Text(
                        '회원가입 하기',
                        style: TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.bold), // 폰트 크기 및 굵기 조정
                      ),
                    ),
                  ),
                  const SizedBox(height: 15), // 간격 조정

                  // 아이디/비밀번호 찾기 섹션 (순서 변경)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: 아이디 찾기 화면으로 이동
                          context.go('/find_id'); // 예시 경로 (실제 라우트 정의 필요)
                        },
                        child: Text(
                          '아이디 찾기',
                          style: TextStyle(color: primaryBlue.withOpacity(0.8), fontSize: 14), // 색상 및 크기 조정
                        ),
                      ),
                      // 구분선
                      Text(
                        ' | ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: 비밀번호 찾기 화면으로 이동
                          context.go('/find_password'); // 예시 경로 (실제 라우트 정의 필요)
                        },
                        child: Text(
                          '비밀번호 찾기',
                          style: TextStyle(color: primaryBlue.withOpacity(0.8), fontSize: 14), // 색상 및 크기 조정
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15), // 간격 조정
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 역할 선택 카드 위젯
  Widget _buildRoleCard(String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;

    Color cardBackgroundColor = isSelected
        ? (roleValue == 'P' ? patientRoleColor : doctorRoleColor)
        : unselectedCardColor; // 선택되지 않은 카드 배경색 추가

    Color iconAndTextColor = isSelected ? Colors.white : Colors.grey[700]!; // 선택 여부에 따른 아이콘/텍스트 색상

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250), // 애니메이션 시간 조정
          curve: Curves.easeInOut, // 애니메이션 커브 추가
          padding: const EdgeInsets.symmetric(vertical: 20), // 패딩 증가
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(20), // 모서리 더 둥글게
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent, // 선택 시 흰색 테두리
              width: isSelected ? 3 : 0, // 선택 시 테두리 굵기
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? cardBackgroundColor.withOpacity(0.6) : Colors.black.withOpacity(0.05), // 그림자 효과
                blurRadius: isSelected ? 15 : 5,
                offset: isSelected ? const Offset(0, 8) : const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: iconAndTextColor), // 아이콘 크기 조정
              const SizedBox(height: 10), // 간격 조정
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, // 선택 시 굵기 강조
                  fontSize: 17, // 폰트 크기 조정
                  color: iconAndTextColor,
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
    registerIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}