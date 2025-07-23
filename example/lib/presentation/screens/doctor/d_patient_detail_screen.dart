import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import '/presentation/model/doctor/d_patient.dart';
import '/presentation/model/doctor/d_consultation_record.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailScreen({required this.patientId, super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Patient? _patient;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPatient();
    });
  }

  Future<void> _fetchPatient() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final patientViewModel = context.read<DPatientViewModel>();

    try {
      await patientViewModel.fetchPatient(widget.patientId);
      if (patientViewModel.errorMessage != null) {
        throw Exception(patientViewModel.errorMessage);
      }
      _patient = patientViewModel.currentPatient;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('환자 상세 정보', style: textTheme.headlineLarge),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('환자 상세 정보', style: textTheme.headlineLarge),
        ),
        body: Center(
          child: Text('오류: $_errorMessage', style: textTheme.bodyMedium),
        ),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('환자 상세 정보', style: textTheme.headlineLarge),
        ),
        body: Center(
          child: Text('환자 정보를 찾을 수 없습니다.', style: textTheme.bodyMedium),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient!.name} 환자 상세 정보', style: textTheme.headlineLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환자 기본 정보
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('환자 기본 정보', style: textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    _buildInfoRow('이름', _patient!.name, textTheme),
                    _buildInfoRow('생년월일', _patient!.dateOfBirth, textTheme),
                    _buildInfoRow('성별', _patient!.gender, textTheme),
                    _buildInfoRow('연락처', _patient!.phoneNumber ?? 'N/A', textTheme),
                    _buildInfoRow('주소', _patient!.address ?? 'N/A', textTheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('진단 결과 예시 (MongoDB)', style: textTheme.headlineSmall),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '이 환자의 진단 기록은 진단 결과 탭에서 확인할 수 있습니다.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
