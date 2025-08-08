import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import '/presentation/model/doctor/d_patient.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

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
    // 첫 빌드 이후 안전하게 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPatient();
    });
  }

  Future<void> _fetchPatient() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vm = context.read<DPatientViewModel>();

    try {
      await vm.fetchPatient(widget.patientId);

      if (!mounted) return;

      if (vm.errorMessage != null) {
        throw Exception(vm.errorMessage);
      }

      setState(() {
        _patient = vm.currentPatient;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(
    String label,
    String value,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label',
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(TextTheme textTheme) {
    return Scaffold(
      appBar: AppBar(title: const Text('환자 상세 정보')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('오류가 발생했습니다.', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '알 수 없는 오류',
                style: textTheme.bodySmall?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPatient,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(TextTheme textTheme) {
    return Scaffold(
      appBar: AppBar(title: const Text('환자 상세 정보')),
      body: Center(
        child: Text('환자 정보를 찾을 수 없습니다.', style: textTheme.bodyMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) return _buildLoading();
    if (_errorMessage != null) return _buildError(textTheme);
    if (_patient == null) return _buildEmpty(textTheme);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient!.name} 환자 상세 정보'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPatient,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환자 기본 정보 카드
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('환자 기본 정보', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _buildInfoRow('이름', _patient!.name, textTheme),
                      _buildInfoRow('생년월일', _patient!.dateOfBirth, textTheme),
                      _buildInfoRow('성별', _patient!.gender, textTheme),
                      _buildInfoRow('연락처', _patient!.phoneNumber ?? '정보 없음', textTheme),
                      _buildInfoRow('주소', _patient!.address ?? '정보 없음', textTheme),
                    ],
                  ),
                ),
              ),

              // 안내 섹션
              const SizedBox(height: 8),
              Text('진단 결과', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  '이 환자의 진단 기록은 상단 탭의 “진단 결과” 화면에서 확인할 수 있습니다.\n'
                  '비대면 진료 요청/응답은 “신청 현황” 화면에서 관리하세요.',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
