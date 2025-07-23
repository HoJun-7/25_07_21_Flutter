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
      _showSnack('의사 계정으로 로그인해야 환자 목록을 볼 수 있습니다.');
    }
  }

  void _showSnack(String msg) {
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

  @override
  Widget build(BuildContext context) {
    final patientViewModel = context.watch<DPatientViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('환자 목록', style: textTheme.headlineLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddPatientDialog(context, authViewModel.currentUser?.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: patientViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : patientViewModel.errorMessage != null
              ? Center(child: Text('오류: ${patientViewModel.errorMessage}', style: textTheme.bodyMedium))
              : patientViewModel.patients.isEmpty
                  ? Center(child: Text('등록된 환자가 없습니다.', style: textTheme.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: patientViewModel.patients.length,
                      itemBuilder: (context, index) {
                        final patient = patientViewModel.patients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(
                              patient.name,
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('생년월일: ${patient.dateOfBirth}', style: textTheme.bodySmall),
                                Text('성별: ${patient.gender}', style: textTheme.bodySmall),
                                if (patient.phoneNumber?.isNotEmpty ?? false)
                                  Text('연락처: ${patient.phoneNumber}', style: textTheme.bodySmall),
                                if (patient.address?.isNotEmpty ?? false)
                                  Text('주소: ${patient.address}', style: textTheme.bodySmall),
                              ],
                            ),
                            onTap: () {
                              if (patient.id != null) {
                                context.go('/patient_detail/${patient.id}');
                              } else {
                                _showSnack('환자 ID를 찾을 수 없습니다.');
                              }
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {
                                _showSnack('${patient.name} 환자 정보 수정 (미구현)');
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showAddPatientDialog(BuildContext context, int? doctorId) {
    if (doctorId == null) {
      _showSnack('의사 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
      return;
    }

    final _nameController = TextEditingController();
    final _dobController = TextEditingController();
    final _genderController = TextEditingController();
    final _phoneController = TextEditingController();
    final _addressController = TextEditingController();
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('새 환자 추가', style: textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                TextField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                  keyboardType: TextInputType.datetime,
                ),
                TextField(
                  controller: _genderController,
                  decoration: const InputDecoration(labelText: '성별 (Male/Female/Other)'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: '핸드폰 번호'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: '주소'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final patientViewModel = context.read<DPatientViewModel>();
                final success = await patientViewModel.addPatient(
                  doctorId: doctorId,
                  name: _nameController.text,
                  dateOfBirth: _dobController.text,
                  gender: _genderController.text,
                  phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                  address: _addressController.text.isNotEmpty ? _addressController.text : null,
                );

                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }

                if (success) {
                  _showSnack('환자가 성공적으로 추가되었습니다!');
                  _loadPatients();
                } else {
                  _showSnack('환자 추가 실패: ${patientViewModel.errorMessage}');
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }
}
