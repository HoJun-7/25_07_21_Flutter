import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _diagnosisCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDiagnosisCount();
  }

  Future<void> _loadDiagnosisCount() async {
    final baseUrl = "http://192.168.0.19:5000/api";
    final user = context.read<UserInfoViewModel>().user;
    if (user == null) return;

    final uri = Uri.parse('$baseUrl/inference-results?user_id=${user.registerId}&role=P');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(response.body);
      setState(() {
        _diagnosisCount = results.length;
      });
    }
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
          title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('정말로 회원 탈퇴하시겠습니까?', style: TextStyle(fontSize: 15)),
              const Text('모든 데이터가 삭제되며 복구할 수 없습니다.', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호를 다시 입력해주세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('탈퇴', style: TextStyle(color: Colors.white)),
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
      builder: (_) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserInfoViewModel>().user;
    const Color myPageBackgroundColor = Color(0xFFB4D4FF);

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: myPageBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('회원정보', style: TextStyle(color: Colors.black87)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                color: myPageBackgroundColor,
                width: double.infinity,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 65, color: myPageBackgroundColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 15),
                    Text(user?.name ?? '로그인 필요',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(user?.role == 'P' ? '환자' : '의사',
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoBox(Icons.rate_review, '예약 내역', '0', context),
                        const SizedBox(width: 15),
                        _buildInfoBox(Icons.chat_bubble_outline, '진료 기록', '$_diagnosisCount', context),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(context, Icons.person_outline, '개인정보 수정', '/reauth'),
                      _buildMenuItem(context, Icons.logout, '로그아웃', '/login', isLogout: true),
                      _buildMenuItem(context, Icons.delete_outline, '회원 탈퇴', '', isDelete: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String count, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showSnack(context, '$label 클릭됨'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
              Text(count, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route,
      {bool isLogout = false, bool isDelete = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      leading: Icon(icon, color: isDelete ? Colors.redAccent : Colors.grey[700]),
      title: Text(title,
          style: TextStyle(color: isDelete ? Colors.redAccent : Colors.black87, fontWeight: FontWeight.w500)),
      onTap: () {
        if (isLogout) {
          context.read<UserInfoViewModel>().clearUser();
          context.go(route);
        } else if (isDelete) {
          _showDeleteConfirmationDialog(context);
        } else {
          context.push(route);
        }
      },
    );
  }
}
