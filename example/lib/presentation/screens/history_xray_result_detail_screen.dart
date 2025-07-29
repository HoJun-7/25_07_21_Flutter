import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/presentation/model/user.dart';
import '/data/service/http_service.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

class HistoryXrayResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final String model1ImageUrl;
  final String model2ImageUrl;
  final Map<String, dynamic> model1Result;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;

  const HistoryXrayResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.model1ImageUrl,
    required this.model2ImageUrl,
    required this.model1Result,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
  });

  @override
  State<HistoryXrayResultDetailScreen> createState() => _HistoryXrayResultDetailScreenState();
}

class _HistoryXrayResultDetailScreenState extends State<HistoryXrayResultDetailScreen> {
  bool _showModel1 = true;
  bool _showModel2 = true;
  String _status = 'idle';
  int? _requestId;

  @override
  void initState() {
    super.initState();
    _checkConsultStatus();
  }

  Future<void> _checkConsultStatus() async {
    final httpService = HttpService(baseUrl: widget.baseUrl);
    final response = await httpService.get('/consult/active');

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
    } else {
      _showErrorDialog("상태 확인 실패");
    }
  }

  Future<void> _submitConsultRequest(User currentUser) async {
    final httpService = HttpService(baseUrl: widget.baseUrl);
    final response = await httpService.post('/consult', {
      'image_path': widget.originalImageUrl,
      'request_datetime': DateTime.now().toString(),
    });

    if (response.statusCode == 201) {
      await _checkConsultStatus();
    } else {
      final msg = jsonDecode(response.body)['error'] ?? '신청 실패';
      _showErrorDialog(msg);
    }
  }

  Future<void> _cancelConsultRequest() async {
    if (_requestId == null) return;
    final httpService = HttpService(baseUrl: widget.baseUrl);
    final response = await httpService.post('/consult/cancel', {
      'request_id': _requestId,
    });

    if (response.statusCode == 200) {
      await _checkConsultStatus();
    } else {
      final msg = jsonDecode(response.body)['error'] ?? '취소 실패';
      _showErrorDialog(msg);
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
    final currentUser = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final predictionCount = (widget.model1Result['predictions'] as List?)?.length ?? 0;

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
            _buildXrayImage(),
            const SizedBox(height: 16),
            _buildXraySummaryCard(modelName, predictionCount),
            const SizedBox(height: 24),
            if (currentUser?.role == 'P') ...[
              _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
              const SizedBox(height: 12),
              _buildConsultButton(currentUser!),
              const SizedBox(height: 12), // AI 소견 버튼 추가를 위한 간격
              _buildActionButton(Icons.chat, 'AI 소견 들어보기', () async {
                final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini_xray');

                final response = await http.post(
                  uri,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "image_url": widget.originalImageUrl,
                    "inference_result_id": widget.inferenceResultId,
                    "model1Label": modelName, // model1Result에서 가져온 modelName 사용
                    "model1Confidence": widget.model1Result['confidence'] ?? 0.0, // model1Result에 confidence가 있다면 사용
                    "predictionCount": predictionCount, // 탐지된 객체 수 추가
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
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
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

  Widget _buildXrayImage() => Container(
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
                Image.network(widget.originalImageUrl, fit: BoxFit.fill),
                if (_showModel1) Image.network(widget.model1ImageUrl, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                if (_showModel2) Image.network(widget.model2ImageUrl, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
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