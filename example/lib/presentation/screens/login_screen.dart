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
<<<<<<< HEAD
  // 텍스트 필드 컨트롤러
  final TextEditingController registerIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // 선택된 역할 ('P' for Patient, 'D' for Doctor)
  String _selectedRole = 'P';

  /// 로그인 처리 함수
=======
  final TextEditingController registerIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _selectedRole = 'P';

>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
  Future<void> login() async {
    final authViewModel = context.read<AuthViewModel>();
    final userInfoViewModel = context.read<UserInfoViewModel>();

    final registerId = registerIdController.text.trim();
    final password = passwordController.text.trim();

<<<<<<< HEAD
    // 아이디 또는 비밀번호가 비어있는 경우 스낵바 표시
=======
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
    if (registerId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')),
      );
      return;
    }

    try {
<<<<<<< HEAD
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
=======
      final user = await authViewModel.loginUser(registerId, password, _selectedRole);

      if (user != null) {
        userInfoViewModel.loadUser(user);
        if (user.role == 'D') {
          context.go('/d_home');
        } else {
          context.go('/home', extra: {'userId': user.registerId});
        }
      } else {
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
        final error = authViewModel.errorMessage ?? '로그인 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
<<<<<<< HEAD
      // 로그인 처리 중 예외 발생 시 스낵바 표시
=======
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 처리 중 오류 발생: ${e.toString()}')),
      );
    }
  }

<<<<<<< HEAD
  /// 뒤로가기 버튼 눌렀을 때 앱 종료 확인 다이얼로그
=======
  // ✅ 뒤로가기 시 종료 확인 팝업
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
<<<<<<< HEAD
            onPressed: () => Navigator.of(context).pop(false), // 취소 버튼
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // 종료 버튼
=======
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
            child: const Text('종료'),
          ),
        ],
      ),
    );
<<<<<<< HEAD
    return shouldExit ?? false; // 다이얼로그가 닫혔을 때 null 방지
=======
    return shouldExit ?? false;
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
<<<<<<< HEAD
      onWillPop: _onWillPop, // 뒤로가기 버튼 처리
      child: Scaffold(
        backgroundColor: const Color(0xFFE0F7FA), // 밝은 아쿠아 블루 배경 (치아 이미지와 어울리게)
=======
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF376193), // ✅ 파란 외부 배경
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
<<<<<<< HEAD
                borderRadius: BorderRadius.circular(20), // 모서리 둥글기 조정
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // 그림자 색상 및 투명도 조정
                    blurRadius: 15, // 그림자 블러 반경
                    offset: const Offset(0, 8), // 그림자 오프셋
=======
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
<<<<<<< HEAD
                  // 로고 이미지 (치아 캐릭터 이미지로 대체)
                  Image.asset(
                    'assets/tooth_character.png', // 사용자 제공 이미지 경로
                    width: 150, // 이미지 크기 조정
                    height: 150,
                  ),
                  const SizedBox(height: 32), // 간격 증가
=======
                  // ✅ 로고 아이콘 (이미지 경로 수정)
                  Image.asset(
                    'assets/icon/cdss-icon_500.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4

                  // 역할 선택 카드
                  Row(
                    children: [
                      _buildRoleCard('환자', 'P', Icons.person),
<<<<<<< HEAD
                      const SizedBox(width: 16), // 간격 증가
=======
                      const SizedBox(width: 12),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                      _buildRoleCard('의사', 'D', Icons.medical_services),
                    ],
                  ),

<<<<<<< HEAD
                  const SizedBox(height: 32), // 간격 증가

                  // 아이디 입력 필드
=======
                  const SizedBox(height: 24),

                  // 아이디 입력
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                  TextField(
                    controller: registerIdController,
                    decoration: InputDecoration(
                      labelText: '아이디',
<<<<<<< HEAD
                      hintText: '아이디를 입력해주세요', // 힌트 텍스트 추가
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5F97F7)), // 아이콘 색상
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true, // 배경 채우기
                      fillColor: Colors.grey[100], // 배경 색상
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
=======
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                    ),
                  ),
                  const SizedBox(height: 16),

<<<<<<< HEAD
                  // 비밀번호 입력 필드
=======
                  // 비밀번호 입력
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
<<<<<<< HEAD
                      hintText: '비밀번호를 입력해주세요', // 힌트 텍스트 추가
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5F97F7)), // 아이콘 색상
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none, // 기본 테두리 제거
                      ),
                      filled: true, // 배경 채우기
                      fillColor: Colors.grey[100], // 배경 색상
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // 패딩 조정
=======
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
<<<<<<< HEAD
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
=======
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('로그인', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('회원가입 하기', style: TextStyle(color: Colors.blueAccent)),
                    ),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
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
=======
  Widget _buildRoleCard(String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;

    // 역할에 따른 색상 정의
    Color selectedColor;
    Color borderColor;

    if (roleValue == 'P') {
      selectedColor = Color(0xFFFFE36A); // 노란색
      borderColor = Colors.amber;
    } else {
      selectedColor = Color(0xFFA0E6B2); // 연초록
      borderColor = Colors.green;
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
    }

    return Expanded(
      child: GestureDetector(
<<<<<<< HEAD
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
=======
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? borderColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.black : Colors.grey),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
<<<<<<< HEAD
    // 컨트롤러 해제
=======
>>>>>>> 7b514fcc087e571e7fa829d1f915eb26c90561d4
    registerIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
