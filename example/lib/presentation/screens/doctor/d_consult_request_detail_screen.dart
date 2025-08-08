// lib/presentation/screens/doctor/d_consult_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart'; // go_router 임포트 추가

// 외부 파일 참조 오류를 해결하기 위해 관련 위젯들을 이 파일에 직접 정의합니다.

/// AI 진단 결과 이미지와 모델 선택 토글 버튼을 표시하는 위젯입니다.
class ResultImageWithToggle extends StatelessWidget {
  final int? selectedModelIndex;
  final ValueChanged<int> onModelToggle;
  final String imageUrl;

  const ResultImageWithToggle({
    super.key,
    this.selectedModelIndex,
    required this.onModelToggle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI 결과 이미지를 표시합니다.
        Image.network(
          imageUrl,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Text('이미지를 불러올 수 없습니다.'),
        ),
        const SizedBox(height: 8),
        // 모델 선택 토글 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => onModelToggle(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedModelIndex == 1 ? Colors.blue : Colors.grey,
              ),
              child: const Text('모델 1'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onModelToggle(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedModelIndex == 2 ? Colors.blue : Colors.grey,
              ),
              child: const Text('모델 2'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => onModelToggle(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedModelIndex == 3 ? Colors.blue : Colors.grey,
              ),
              child: const Text('모델 3'),
            ),
          ],
        ),
      ],
    );
  }
}

/// AI 진단 결과를 요약해서 표시하는 박스 위젯입니다.
class AIResultBox extends StatelessWidget {
  final String modelName;
  final double confidence;
  final String className;

  const AIResultBox({
    super.key,
    required this.modelName,
    required this.confidence,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 진단 결과',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('사용 모델: $modelName'),
          Text('진단명: $className'),
          Text('신뢰도: ${(confidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

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
  // 답변 완료 상태를 내부적으로 관리하는 대신, 화면을 pop하면서 결과를 전달합니다.

  @override
  void initState() {
    super.initState();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitDoctorReply() async {
    if (!mounted) return;
    if (_commentController.text.isEmpty) {
      _showSnack('코멘트를 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final url = '${widget.baseUrl}/consult/reply';
    final now = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '').substring(0, 14);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'request_id': int.parse(widget.requestId),
          'doctor_id': widget.doctorId,
          'doctor_comment': _commentController.text,
          'replied_at': now,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSnack('답변이 성공적으로 저장되었습니다!');
        // 성공 시, 화면을 닫고 성공했음을 알리는 true 값을 반환합니다.
        context.pop(true);
      } else {
        if (!mounted) return;
        _showSnack('답변 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('네트워크 오류: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelInfo = _selectedModelIndex != null ? widget.modelInfos[_selectedModelIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('진단 결과')),
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
            // 답변 완료 시 화면이 닫히므로, 조건부 UI는 필요 없습니다.
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
          ],
        ),
      ),
    );
  }
}





