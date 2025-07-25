import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class TelemedicineApplyScreen extends StatefulWidget {
  final String userId;
  final String registerId;
  final String name;
  final String phone;
  final String birth;
  final String gender;
  final String role;
  final String inferenceResultId;
  final String baseUrl;
  final String originalImageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;

  const TelemedicineApplyScreen({
    super.key,
    required this.userId,
    required this.registerId,
    required this.name,
    required this.phone,
    required this.birth,
    required this.gender,
    required this.role,
    required this.inferenceResultId,
    required this.baseUrl,
    required this.originalImageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
  });

  @override
  State<TelemedicineApplyScreen> createState() => _TelemedicineApplyScreenState();
}

class _TelemedicineApplyScreenState extends State<TelemedicineApplyScreen> {
  final TextEditingController _addressController = TextEditingController(text: '대전 서구 계룡로 491번길 86');
  String? _selectedClinic;
  bool _isSubmitting = false;
  bool _isPressed = false;

  final List<String> _clinicOptions = [
    '서울 치과 병원',
    '강남 종합 치과',
    '부산 중앙 치과',
    '대구 사랑 치과',
    '인천 미소 치과',
    '광주 건강 치과',
    '대전 행복 치과',
    '울산 치과 센터',
  ];

  Future<void> _submitApplication() async {
    if (_selectedClinic == null || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('병원과 주소를 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final formattedDatetime = DateFormat('yyyyMMddHHmmss').format(now);

    final body = {
      "user_id": widget.userId,
      "register_id": widget.registerId,
      "name": widget.name,
      "phone": widget.phone,
      "birth": widget.birth,
      "gender": widget.gender,
      "role": widget.role,
      "inference_result_id": widget.inferenceResultId,
      "request_datetime": formattedDatetime,
      "clinic": _selectedClinic,
      "address": _addressController.text.trim(),
      "original_image_url": widget.originalImageUrl,
      "processed_image_urls": widget.processedImageUrls,
      "model_infos": widget.modelInfos,
    };

    final response = await http.post(
      Uri.parse("${widget.baseUrl}/consult"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    setState(() => _isSubmitting = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 신청이 완료되었습니다.")),
      );
      Navigator.pop(context);
    } else {
      final error = jsonDecode(response.body)['error'] ?? '알 수 없는 오류';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 신청 실패: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    final isFormValid = _selectedClinic != null && _addressController.text.trim().isNotEmpty;

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
              "이름: ${widget.name}",
              "성별: ${widget.gender}",
              "생년월일: ${widget.birth}",
              "전화번호: ${widget.phone}",
            ]),
            const SizedBox(height: 16),

            _buildSectionTitle("🦷 진단 결과 요약"),
            _buildInfoCard([
              "모델1: ${model1?['label'] ?? 'N/A'} / ${(model1?['confidence'] ?? 0.0 * 100).toStringAsFixed(1)}%",
              "모델2: ${model2?['label'] ?? 'N/A'} / ${(model2?['confidence'] ?? 0.0 * 100).toStringAsFixed(1)}%",
              "모델3: 치아번호 ${model3?['tooth_number_fdi'] ?? 'N/A'} / ${(model3?['confidence'] ?? 0.0 * 100).toStringAsFixed(1)}%",
            ]),
            const SizedBox(height: 16),

            _buildSectionTitle("🏥 병원 선택"),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
              ),
              hint: const Text("병원을 선택하세요"),
              value: _selectedClinic,
              items: _clinicOptions.map((clinic) {
                return DropdownMenuItem<String>(
                  value: clinic,
                  child: Text(clinic),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClinic = value);
              },
            ),
            const SizedBox(height: 16),

            _buildSectionTitle("🏠 주소 입력"),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "상세 주소를 입력하세요",
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 24),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: !_isPressed
                    ? (isFormValid ? const Color(0xFF3869A8) : Colors.grey[300])
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSubmitting || !isFormValid
                    ? null
                    : () async {
                        setState(() => _isPressed = true);
                        await _submitApplication();
                        setState(() => _isPressed = false);
                      },
                onHighlightChanged: (pressed) {
                  if (isFormValid) setState(() => _isPressed = pressed);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      _isSubmitting ? "신청 중..." : "이대로 신청하기",
                      style: TextStyle(
                        color: !_isPressed
                            ? (isFormValid ? Colors.white : Colors.black38)
                            : const Color(0xFF3869A8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
