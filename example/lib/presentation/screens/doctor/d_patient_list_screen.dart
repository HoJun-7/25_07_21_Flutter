import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodel/doctor/d_patient_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../doctor/d_patient_detail_screen.dart';
import '../../model/doctor/d_patient.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  Future<void> _loadPatients() async {
    final authViewModel = context.read<AuthViewModel>();
    final patientViewModel = context.read<DPatientViewModel>();

    if (authViewModel.currentUser != null &&
        authViewModel.currentUser!.isDoctor &&
        authViewModel.currentUser!.id != null) {
      await patientViewModel.fetchPatients(authViewModel.currentUser!.id!);
      if (patientViewModel.errorMessage != null) {
        _showSnack('환자 목록 로드 오류: ${patientViewModel.errorMessage}');
      }
    } else {
      _showSnack('의사 계정으로 로그인해야 환자 목록을 확인할 수 있습니다.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addPatient(String doctorId) {
    // 다이얼로그 로직... (이전 코드와 동일)
  }

  // 환자 목록 위젯 (이전 코드와 동일)

  @override
  Widget build(BuildContext context) {
    final patientViewModel = context.watch<DPatientViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final doctorId = authViewModel.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('환자 목록'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (doctorId != null)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _addPatient(doctorId),
            ),
        ],
      ),
      body: patientViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : patientViewModel.patients.isEmpty
          ? const Center(child: Text('환자가 없습니다.'))
          : ListView.separated(
        itemCount: patientViewModel.patients.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = patientViewModel.patients[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade300,
              child: Text(
                patient.name.isNotEmpty ? patient.name[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(patient.name),
            subtitle: Text('생년월일: ${patient.dateOfBirth}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // 환자 상세 화면으로 이동하고, 돌아올 때 반환 값을 기다립니다.
              final result = await context.push(
                '/doctor/patients/${patient.id}', // GoRouter 경로
              );
              
              // 만약 상세 화면에서 true를 반환했다면 목록을 새로고침합니다.
              if (result == true) {
                _loadPatients();
              }
            },
          );
        },
      ),
    );
  }
}



