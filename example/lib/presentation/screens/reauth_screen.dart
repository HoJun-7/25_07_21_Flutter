import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⬅ 웹 화면 고정용
import '/presentation/viewmodel/auth_viewmodel.dart';

class ReauthScreen extends StatefulWidget {
  const ReauthScreen({super.key});

  @override
  State<ReauthScreen> createState() => _ReauthScreenState();
}

class _ReauthScreenState extends State<ReauthScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final authViewModel = context.read<AuthViewModel>();
    final password = _passwordController.text.trim();
    final currentUser = authViewModel.currentUser;

    if (password.isEmpty) {
      _showSnack('비밀번호를 입력해주세요.');
      return;
    }
    if (currentUser == null) {
      _showSnack('로그인 정보가 없습니다.');
      return;
    }

    setState(() => _isLoading = true);

    final error = await authViewModel.reauthenticate(
      currentUser.registerId!,
      password,
      currentUser.role!,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      context.push('/edit-profile');
    } else {
      _showSnack(error);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('비밀번호 확인'),
        backgroundColor: const Color(0xFF3F8CD4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        // ✅ 세로 가운데 정렬 + 작은 화면 스크롤 둘 다 만족
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center( // ⬅ 세로/가로 가운데 정렬
                  child: kIsWeb
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildCard(),
                        )
                      : _buildCard(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 본문 카드 UI
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '개인정보 수정을 위해\n비밀번호를 다시 입력해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '비밀번호',
              filled: true,
              fillColor: const Color(0xFFF5F8FC),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F8CD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '확인',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
