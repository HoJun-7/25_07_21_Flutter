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
  String _selectedRole = 'P';
  // 확대/축소 비율을 제어하는 상태 변수
  double _scaleFactor = 1.0; 

  static const Color primaryBlue = Color(0xFF5F97F7);
  static const Color lightBlueBackground = Color(0xFFB4D4FF);
  static const Color patientRoleColor = Color(0xFF90CAF9);
  static const Color doctorRoleColor = Color(0xFF81C784);
  static const Color unselectedCardColor = Color(0xFFE0E0E0);

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
      final user = await authViewModel.loginUser(registerId, password, _selectedRole);

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
    return MediaQuery(
      // 텍스트 스케일 팩터를 1.0으로 고정하여 시스템 설정에 관계없이 일관된 스케일링을 보장합니다.
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), 
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: lightBlueBackground,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column( // 슬라이더를 추가하기 위해 Column으로 감쌉니다.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 확대/축소 슬라이더
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UI 확대/축소: ${_scaleFactor.toStringAsFixed(1)}x',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
                        ),
                        Slider(
                          value: _scaleFactor,
                          min: 0.7, // 최소 확대 비율
                          max: 1.5, // 최대 확대 비율
                          divisions: 8, // 0.1 단위로 조절 가능 (0.7에서 1.5까지 0.1씩 9단계)
                          activeColor: primaryBlue,
                          inactiveColor: primaryBlue.withOpacity(0.3),
                          onChanged: (newValue) {
                            setState(() {
                              _scaleFactor = newValue;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // 슬라이더와 로그인 폼 사이 간격
                  // Transform.scale 위젯을 사용하여 로그인 폼 전체를 확대/축소합니다.
                  Transform.scale(
                    scale: _scaleFactor,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/cdss-icon_500.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRoleCard('환자', 'P', Icons.personal_injury_outlined),
                              const SizedBox(width: 15),
                              _buildRoleCard('의사', 'D', Icons.medical_information_outlined),
                            ],
                          ),
                          const SizedBox(height: 30),
                          TextField(
                            controller: registerIdController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: '아이디를 입력하세요',
                              hintText: '예: user@example.com',
                              prefixIcon: const Icon(Icons.person_outline, color: primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: '비밀번호를 입력하세요',
                              hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                              prefixIcon: const Icon(Icons.lock_outline, color: primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                '로그인',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.go('/register'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryBlue, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                '회원가입 하기',
                                style: TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => context.go('/find_id'),
                                child: Text(
                                  '아이디 찾기',
                                  style: TextStyle(color: primaryBlue.withOpacity(0.8), fontSize: 14),
                                ),
                              ),
                              Text(
                                ' | ',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () => context.go('/find_password'),
                                child: Text(
                                  '비밀번호 찾기',
                                  style: TextStyle(color: primaryBlue.withOpacity(0.8), fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;

    Color cardBackgroundColor = isSelected
        ? (roleValue == 'P' ? patientRoleColor : doctorRoleColor)
        : unselectedCardColor;

    Color iconAndTextColor = isSelected ? Colors.white : Colors.grey[700]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? cardBackgroundColor.withOpacity(0.6) : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 15 : 5,
                offset: isSelected ? const Offset(0, 8) : const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: iconAndTextColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 17,
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
