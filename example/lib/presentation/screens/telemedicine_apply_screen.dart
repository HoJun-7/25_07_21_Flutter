import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TelemedicineApplyScreen extends StatefulWidget {
  final String userId;
  final String inferenceResultId;
  final String baseUrl;

  // 진단 요약 전달
  final String diagnosisClassName;
  final double confidence;
  final String modelUsed;

  // 환자 정보 전달 (ex: 로그인 상태에서 ViewModel로 받아도 됨)
  final String patientName;
  final String patientPhone;
  final String patientBirth;

  const TelemedicineApplyScreen({
    super.key,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
    required this.diagnosisClassName,
    required this.confidence,
    required this.modelUsed,
    required this.patientName,
    required this.patientPhone,
    required this.patientBirth,
  });

  @override
  State<TelemedicineApplyScreen> createState() => _TelemedicineApplyScreenState();
}

class _TelemedicineApplyScreenState extends State<TelemedicineApplyScreen> {
  final TextEditingController _addressController = TextEditingController();
  String? _selectedClinic;

  final List<String> _clinicOptions = [
    '서울 밝은 치과',
    '연세 치과',
    '예쁜 미소 치과',
  ];

  bool _isSubmitting = false;

  Future<void> _submitApplication() async {
    if (_selectedClinic == null || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('병원과 주소를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await http.post(
      Uri.parse("${widget.baseUrl}/apply"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": widget.userId,
        "inference_result_id": widget.inferenceResultId,
        "location": _addressController.text.trim(),
        "selected_clinic": _selectedClinic,
      }),
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 신청이 완료되었습니다.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ 신청 실패. 다시 시도해주세요.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("비대면 진단 신청"),
        backgroundColor: const Color(0xFF3869A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildSectionTitle("👤 환자 정보"),
            _buildInfoCard([
              "이름: ${widget.patientName}",
              "생년월일: ${widget.patientBirth}",
              "전화번호: ${widget.patientPhone}",
            ]),
            const SizedBox(height: 16),

            _buildSectionTitle("🦷 진단 결과 요약"),
            _buildInfoCard([
              "예측 질환: ${widget.diagnosisClassName}",
              "확신도: ${(widget.confidence * 100).toStringAsFixed(1)}%",
              "사용 모델: ${widget.modelUsed}",
            ]),
            const SizedBox(height: 16),

            _buildSectionTitle("🏥 병원 선택"),
            DropdownButtonFormField<String>(
              value: _selectedClinic,
              items: _clinicOptions.map((clinic) {
                return DropdownMenuItem(
                  value: clinic,
                  child: Text(clinic),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedClinic = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '진료 받을 병원을 선택하세요',
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle("🏠 주소 입력"),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "상세 주소를 입력하세요",
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitApplication,
              icon: const Icon(Icons.check_circle),
              label: Text(_isSubmitting ? "신청 중..." : "이대로 신청하기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3869A8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildInfoCard(List<String> lines) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF3869A8)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((text) => Text(text)).toList(),
        ),
      );
}
