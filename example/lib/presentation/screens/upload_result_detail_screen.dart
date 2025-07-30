import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';

class UploadResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;

  const UploadResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
  });

  @override
  State<UploadResultDetailScreen> createState() => _UploadResultDetailScreenState();
}

class _UploadResultDetailScreenState extends State<UploadResultDetailScreen> {
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;
  bool _isLoadingGemini = false;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;
  Uint8List? overlay3Bytes;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final ov1 = await _loadImageWithAuth(widget.processedImageUrls[1], token);
      final ov2 = await _loadImageWithAuth(widget.processedImageUrls[2], token);
      final ov3 = await _loadImageWithAuth(widget.processedImageUrls[3], token);

      setState(() {
        originalImageBytes = original;
        overlay1Bytes = ov1;
        overlay2Bytes = ov2;
        overlay3Bytes = ov3;
      });
    } catch (e) {
      print('이미지 로딩 실패: $e');
    }
  }

  Future<Uint8List?> _loadImageWithAuth(String? url, String token) async {
    if (url == null) return null;

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print('이미지 요청 실패: ${response.statusCode}');
      return null;
    }
  }

  Future<void> _applyConsultRequest() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final now = DateTime.now();
    final requestDatetime = "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}"
                            "${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}";

    final relativePath = widget.originalImageUrl.replaceFirst(
      widget.baseUrl.replaceAll('/api', ''),
      '',
    );

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/consult'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': widget.userId,
          'original_image_url': relativePath,
          'request_datetime': requestDatetime,
        }),
      );

      if (response.statusCode == 201) {
        // ✅ FIXED: consult_result.dart가 type을 받아야 UI가 정상 출력됨
        context.push('/consult_success', extra: {'type': 'apply'});
      } else {
        final msg = jsonDecode(response.body)['error'] ?? '신청에 실패했습니다.';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('신청 실패'),
            content: Text(msg),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
      }
    } catch (e) {
      print('❌ 서버 요청 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 문제가 발생했습니다.')),
      );
    }
  }



  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) return;

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    final response = await http.post(
      Uri.parse('${widget.baseUrl}/multimodal_gemini'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'image_url': widget.originalImageUrl,
        'inference_result_id': widget.inferenceResultId,
        'model1Label': model1?['label'] ?? '감지되지 않음',
        'model1Confidence': model1?['confidence'] ?? 0.0,
        'model2Label': model2?['label'] ?? '감지되지 않음',
        'model2Confidence': model2?['confidence'] ?? 0.0,
        'model3ToothNumber': model3?['tooth_number_fdi']?.toString() ?? 'Unknown',
        'model3Confidence': model3?['confidence'] ?? 0.0,
      }),
    );

    setState(() => _isLoadingGemini = false);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final message = result['message'] ?? 'AI 소견을 불러오지 못했습니다';
      context.push('/multimodal_result', extra: {'responseText': message});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 소견 요청 실패: ${response.statusCode}')),
      );
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser;
    final textTheme = Theme.of(context).textTheme;

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3869A8),
        title: const Text('진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToggleCard(const Color(0xFFEAEAEA)),
            const SizedBox(height: 16),
            _buildImageCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(
              model1Label: model1?['label'] ?? '감지되지 않음',
              model1Confidence: model1?['confidence'] ?? 0.0,
              model2Label: model2?['label'] ?? '감지되지 않음',
              model2Confidence: model2?['confidence'] ?? 0.0,
              model3ToothNumber: model3?['tooth_number_fdi']?.toString() ?? 'Unknown',
              model3Confidence: model3?['confidence'] ?? 0.0,
              textTheme: textTheme,
            ),
            const SizedBox(height: 24),
            if (currentUser?.role == 'P') ...[
              _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', _applyConsultRequest),
              const SizedBox(height: 12),
              _buildActionButton(Icons.chat, 'AI 소견 들어보기', _isLoadingGemini ? null : _getGeminiOpinion),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
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
                Image.memory(originalImageBytes!, fit: BoxFit.fill)
              else
                const Center(child: CircularProgressIndicator()),
              if (_showDisease && overlay1Bytes != null)
                Image.memory(overlay1Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
              if (_showHygiene && overlay2Bytes != null)
                Image.memory(overlay2Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
              if (_showToothNumber && overlay3Bytes != null)
                Image.memory(overlay3Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard(Color toggleBg) => Container(
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
        _buildStyledToggle('충치/치주염/치은염', _showDisease, (val) => setState(() => _showDisease = val), toggleBg),
        _buildStyledToggle('치석/보철물', _showHygiene, (val) => setState(() => _showHygiene = val), toggleBg),
        _buildStyledToggle('치아번호', _showToothNumber, (val) => setState(() => _showToothNumber = val), toggleBg),
      ],
    ),
  );

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontSize: 15)), Switch(value: value, onChanged: onChanged)],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String model1Label,
    required double model1Confidence,
    required String model2Label,
    required double model2Confidence,
    required String model3ToothNumber,
    required double model3Confidence,
    required TextTheme textTheme,
  }) =>
      Container(
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
            Text('모델1 (질병): $model1Label, ${(model1Confidence * 100).toStringAsFixed(1)}%', style: textTheme.bodyMedium),
            Text('모델2 (위생): $model2Label, ${(model2Confidence * 100).toStringAsFixed(1)}%', style: textTheme.bodyMedium),
            Text('모델3 (치아번호): $model3ToothNumber, ${(model3Confidence * 100).toStringAsFixed(1)}%', style: textTheme.bodyMedium),
          ],
        ),
      );

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed) {
    return ElevatedButton.icon(
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
}
