// lib/presentation/screens/doctor/d_consult_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_image_base.dart';

class DConsultRequestDetailScreen extends StatefulWidget {
  final String imageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String requestId;
  final String doctorId;
  final String baseUrl;

  const DConsultRequestDetailScreen({
    super.key,
    required this.imageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
    required this.requestId,
    required this.doctorId,
    required this.baseUrl,
  });

  @override
  State<DConsultRequestDetailScreen> createState() => _DConsultRequestDetailScreenState();
}

class _DConsultRequestDetailScreenState extends State<DConsultRequestDetailScreen> {
  int? _selectedModelIndex = 1;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isReplied = false;

  Future<void> _submitDoctorReply() async {
    final url = '${widget.baseUrl}/consult/reply';
    final now = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '').substring(0, 14);

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'request_id': widget.requestId,
          'doctor_id': widget.doctorId,
          'comment': _commentController.text,
          'reply_datetime': now,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isReplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 답변이 저장되었습니다.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 실패: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 네트워크 오류: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelInfo = (_selectedModelIndex != null)
        ? widget.modelInfos[_selectedModelIndex!]
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("진단 결과")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ResultImageWithToggle(
              selectedModelIndex: _selectedModelIndex,
              onModelToggle: (index) => setState(() => _selectedModelIndex = index),
              imageUrl: widget.processedImageUrls[_selectedModelIndex!] ?? widget.imageUrl,
            ),
            const SizedBox(height: 12),
            if (modelInfo != null)
              AIResultBox(
                modelName: modelInfo['model_used'],
                confidence: modelInfo['confidence'],
                className: 'Dental Plaque',
              ),
            const SizedBox(height: 16),
            if (!_isReplied) ...[
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '의사 코멘트 입력',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitDoctorReply,
                icon: const Icon(Icons.save),
                label: Text(_isSubmitting ? '저장 중...' : '답변 저장'),
              ),
            ] else
              const Text("✅ 답변 완료", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

