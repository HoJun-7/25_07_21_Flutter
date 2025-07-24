import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(title: const Text('비밀번호 확인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('개인정보 수정을 위해 비밀번호를 다시 입력해주세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
