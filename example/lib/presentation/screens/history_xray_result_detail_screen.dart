// 생략된 import는 그대로 유지
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/user.dart';

class HistoryXrayResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final String model1ImageUrl;
  final String model2ImageUrl;
  final Map<String, dynamic> model1Result;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;
  final String isRequested;
  final String isReplied;

  const HistoryXrayResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.model1ImageUrl,
    required this.model2ImageUrl,
    required this.model1Result,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
    required this.isRequested,
    required this.isReplied,
  });

  @override
  State<HistoryXrayResultDetailScreen> createState() => _HistoryXrayResultDetailScreenState();
}

class _HistoryXrayResultDetailScreenState extends State<HistoryXrayResultDetailScreen> {
  bool _showModel1 = true;
  bool _showModel2 = true;
  bool _isRequested = false;
  bool _isReplied = false;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';
    _loadImages();
  }

  Future<void> _loadImages() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final ov1 = await _loadImageWithAuth(widget.model1ImageUrl, token);
      final ov2 = await _loadImageWithAuth(widget.model2ImageUrl, token);
      setState(() {
        originalImageBytes = original;
        overlay1Bytes = ov1;
        overlay2Bytes = ov2;
      });
    } catch (e) {
      print('이미지 로딩 실패: $e');
    }
  }

  Future<Uint8List?> _loadImageWithAuth(String url, String token) async {
    final String resolvedUrl = url.startsWith('http')
        ? url
        : '${widget.baseUrl.replaceAll('/api', '')}${url.startsWith('/') ? '' : '/'}$url';

    final response = await http.get(Uri.parse(resolvedUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      print('❌ 이미지 요청 실패: $resolvedUrl (${response.statusCode})');
    }

    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  Future<void> _saveResultImage() async {
    final bytes = _showModel2 && overlay2Bytes != null ? overlay2Bytes : overlay1Bytes;
    if (bytes == null) return;
    await ImageGallerySaver.saveImage(bytes, quality: 100, name: "result_image");
  }

  Future<void> _saveOriginalImage() async {
    if (originalImageBytes == null) return;
    await ImageGallerySaver.saveImage(originalImageBytes!, quality: 100, name: "original_image");
  }

  Future<void> _submitConsultRequest(User currentUser) async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final now = DateTime.now();
    final datetime = "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}"
        "${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}";

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    final response = await http.post(
      Uri.parse('${widget.baseUrl}/consult'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': widget.userId,
        'original_image_url': relativePath,
        'request_datetime': datetime,
      }),
    );

    if (response.statusCode == 201) {
      setState(() => _isRequested = true);
      context.push('/consult_success', extra: {'type': 'apply'});
    } else {
      _showErrorDialog(jsonDecode(response.body)['error'] ?? '신청 실패');
    }
  }

  Future<void> _cancelConsultRequest() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    final response = await http.post(
      Uri.parse('${widget.baseUrl}/consult/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': widget.userId,
        'original_image_url': relativePath,
      }),
    );

    if (response.statusCode == 200) {
      setState(() => _isRequested = false);
      context.push('/consult_success', extra: {'type': 'cancel'});
    } else {
      _showErrorDialog(jsonDecode(response.body)['error'] ?? '취소 실패');
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("에러"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))],
      ),
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser!;
    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final count = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3869A8),
        title: const Text('X-ray 진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToggleCard(),
            const SizedBox(height: 16),
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildXraySummaryCard(modelName, count),
            const SizedBox(height: 24),
            if (currentUser.role == 'P') ...[
              _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
              const SizedBox(height: 12),
              _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
              const SizedBox(height: 12),
              if (!_isRequested)
                _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', () => _submitConsultRequest(currentUser))
              else if (_isRequested && !_isReplied)
                _buildActionButton(Icons.medical_services, 'AI 예측 기반 진단 신청 취소', _cancelConsultRequest),
              const SizedBox(height: 12),
              _buildActionButton(Icons.chat, 'AI 소견 들어보기', _getGeminiOpinion),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _getGeminiOpinion() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final predictionCount = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    final response = await http.post(
      Uri.parse('${widget.baseUrl}/multimodal_gemini_xray'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "image_url": widget.originalImageUrl,
        "inference_result_id": widget.inferenceResultId,
        "model1Label": modelName,
        "model1Confidence": widget.model1Result['confidence'] ?? 0.0,
        "predictionCount": predictionCount,
      }),
    );

    if (response.statusCode == 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'AI 응답이 없습니다.';
      context.push('/multimodal_result', extra: {"responseText": msg});
    } else {
      _showErrorDialog("AI 소견 요청 실패");
    }
  }

  Widget _buildToggleCard() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('마스크 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStyledToggle("YOLO 탐지 결과 (model1)", _showModel1, (val) => setState(() => _showModel1 = val)),
            _buildStyledToggle("추가 오버레이 (model2)", _showModel2, (val) => setState(() => _showModel2 = val)),
          ],
        ),
      );

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: const TextStyle(fontSize: 15)), Switch(value: value, onChanged: onChanged)],
        ),
      );

  Widget _buildImageCard() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (originalImageBytes != null)
                  Image.memory(originalImageBytes!, fit: BoxFit.fill),
                if (_showModel1 && overlay1Bytes != null)
                  Image.memory(overlay1Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                if (_showModel2 && overlay2Bytes != null)
                  Image.memory(overlay2Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
              ],
            ),
          ),
        ),
      );

  Widget _buildXraySummaryCard(String modelName, int count) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('진단 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("YOLO 모델: $modelName"),
            Text("탐지된 객체 수: $count개"),
          ],
        ),
      );

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed) => ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3869A8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
