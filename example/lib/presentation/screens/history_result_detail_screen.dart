import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/presentation/model/user.dart';

class HistoryResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;

  const HistoryResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
  });

  @override
  State<HistoryResultDetailScreen> createState() => _HistoryResultDetailScreenState();
}

class _HistoryResultDetailScreenState extends State<HistoryResultDetailScreen> {
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;

  String _status = 'idle';
  int? _requestId;

  @override
  void initState() {
    super.initState();
    _checkConsultStatus();
  }

  Future<void> _checkConsultStatus() async {
    final uri = Uri.parse('${widget.baseUrl}/consult/active?user_id=${widget.userId}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final activeImage = result['image_path'];
      final activeRequestId = result['request_id'];

      if (activeImage == null) {
        setState(() => _status = 'requestable');
      } else if (activeImage == widget.originalImageUrl) {
        setState(() {
          _status = 'cancelable';
          _requestId = activeRequestId;
        });
      } else {
        setState(() => _status = 'locked');
      }
    }
  }

  Future<void> _submitConsultRequest(User currentUser) async {
    final uri = Uri.parse('${widget.baseUrl}/consult');
    final response = await http.post(uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'user_id': currentUser.registerId,
        'image_path': widget.originalImageUrl,
        'request_datetime': DateTime.now().toString(),
      }),
    );

    if (response.statusCode == 201) {
      await _checkConsultStatus(); // ✅ DB 상태 재조회
      setState(() => _status = 'cancelable');
    } else {
      final msg = jsonDecode(response.body)['error'] ?? '신청 실패';
      _showErrorDialog(msg);
    }
  }

  Future<void> _cancelConsultRequest() async {
    if (_requestId == null) return;
    final uri = Uri.parse('${widget.baseUrl}/consult/cancel');
    final response = await http.post(uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'request_id': _requestId}),
    );

    if (response.statusCode == 200) {
      await _checkConsultStatus(); // ✅ DB 상태 재조회
      setState(() {
        _status = 'requestable';
        _requestId = null;
      });
    } else {
      final msg = jsonDecode(response.body)['error'] ?? '취소 실패';
      _showErrorDialog(msg);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("에러"),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))
        ],
      ),
    );
  }

  Widget _buildConsultButton(User currentUser) {
    switch (_status) {
      case 'requestable':
        return _buildActionButton(Icons.medical_services, '비대면 진료 신청', () => _submitConsultRequest(currentUser));
      case 'cancelable':
        return _buildActionButton(Icons.cancel, '신청 취소', _cancelConsultRequest);
      case 'locked':
        return _buildActionButton(Icons.lock, '다른 진료 신청 진행중', null);
      default:
        return _buildActionButton(Icons.hourglass_empty, '상태 확인 중...', null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;

    final model1Info = widget.modelInfos[1];
    final model1Confidence = model1Info?['confidence'] ?? 0.0;
    final model1Label = model1Info?['label'] ?? '감지되지 않음';

    final model2Info = widget.modelInfos[2];
    final model2Confidence = model2Info?['confidence'] ?? 0.0;
    final model2Label = model2Info?['label'] ?? '감지되지 않음';

    final model3Info = widget.modelInfos[3];
    final model3Confidence = model3Info?['confidence'] ?? 0.0;
    final model3ToothNumber = model3Info?['tooth_number_fdi']?.toString() ?? 'Unknown';

    final imageUrl = widget.originalImageUrl;
    final overlay1 = widget.processedImageUrls[1];
    final overlay2 = widget.processedImageUrls[2];
    final overlay3 = widget.processedImageUrls[3];

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
            _buildFixedImageCard(imageUrl, overlay1, overlay2, overlay3),
            const SizedBox(height: 16),
            _buildSummaryCard(
              model1Label: model1Label,
              model1Confidence: model1Confidence,
              model2Label: model2Label,
              model2Confidence: model2Confidence,
              model3ToothNumber: model3ToothNumber,
              model3Confidence: model3Confidence,
              textTheme: textTheme,
            ),
            const SizedBox(height: 24),
            if (currentUser?.role == 'P') ...[
              _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildConsultButton(currentUser!),
              const SizedBox(height: 12),
              _buildActionButton(Icons.chat, 'AI 소견 들어보기', () async {
                final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini');

                final response = await http.post(
                  uri,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "image_url": widget.originalImageUrl,
                    "inference_result_id": widget.inferenceResultId,
                    "model1Label": model1Label,
                    "model1Confidence": model1Confidence,
                    "model2Label": model2Label,
                    "model2Confidence": model2Confidence,
                    "model3ToothNumber": model3ToothNumber,
                    "model3Confidence": model3Confidence,
                  }),
                );

                if (response.statusCode == 200) {
                  final result = jsonDecode(response.body);
                  final message = result['message'] ?? 'AI 응답이 없습니다.';
                  context.push('/multimodal-ressult', extra: {"responseText": message});
                } else {
                  _showErrorDialog("AI 소견 요청에 실패했습니다.");
                }
              }),
            ]
          ],
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
            _buildStyledToggle("충치/치주염/치은염", _showDisease, (val) => setState(() => _showDisease = val), toggleBg),
            _buildStyledToggle("치석/보철물", _showHygiene, (val) => setState(() => _showHygiene = val), toggleBg),
            _buildStyledToggle("치아번호", _showToothNumber, (val) => setState(() => _showToothNumber = val), toggleBg),
          ],
        ),
      );

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFixedImageCard(String imageUrl, String? overlay1, String? overlay2, String? overlay3) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('진단 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF3869A8), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                      ),
                      if (_showDisease && overlay1 != null)
                        Image.network(overlay1, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                      if (_showHygiene && overlay2 != null)
                        Image.network(overlay2, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                      if (_showToothNumber && overlay3 != null)
                        Image.network(overlay3, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

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
            Text("모델1 (질병): $model1Label, ${(model1Confidence * 100).toStringAsFixed(1)}%", style: textTheme.bodyMedium),
            Text("모델2 (위생): $model2Label, ${(model2Confidence * 100).toStringAsFixed(1)}%", style: textTheme.bodyMedium),
            Text("모델3 (치아번호): $model3ToothNumber, ${(model3Confidence * 100).toStringAsFixed(1)}%", style: textTheme.bodyMedium),
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