// example/lib/presentation/screens/upload_xray_result_detail_screen.dart

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/user.dart';
import '/data/service/http_service.dart';

class UploadXrayResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final String model1ImageUrl;
  final String model2ImageUrl;
  final Map<String, dynamic> model1Result;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;

  const UploadXrayResultDetailScreen({
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
  State<UploadXrayResultDetailScreen> createState() => _UploadXrayResultDetailScreenState();
}

class _UploadXrayResultDetailScreenState extends State<UploadXrayResultDetailScreen> {
  bool _showModel1 = true;
  bool _showModel2 = true;

  Uint8List? _originalImageBytes;
  Uint8List? _model1Bytes;
  Uint8List? _model2Bytes;

  bool _isLoadingGemini = true;
  String? _geminiOpinion;

  List<Map<String, dynamic>> _implantResults = [];

  String get _relativePath =>
      widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadImplantManufacturerResults();
    _getGeminiOpinion();
  }

  Future<void> _loadImages() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final overlay1 = await _loadImageWithAuth(widget.model1ImageUrl, token);
      final overlay2 = await _loadImageWithAuth(widget.model2ImageUrl, token);

      setState(() {
        _originalImageBytes = original;
        _model1Bytes = overlay1;
        _model2Bytes = overlay2;
      });
    } catch (e) {
      // ignore: avoid_print
      print('이미지 로딩 실패: $e');
    }
  }

  Future<Uint8List?> _loadImageWithAuth(String url, String token) async {
    final String resolvedUrl = url.startsWith('http')
        ? url
        : '${widget.baseUrl.replaceAll('/api', '')}${url.startsWith('/') ? '' : '/'}$url';

    final res = await http.get(Uri.parse(resolvedUrl), headers: {
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('❌ 이미지 요청 실패: $resolvedUrl (${res.statusCode})');
    }
    return res.statusCode == 200 ? res.bodyBytes : null;
  }

  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) {
      setState(() => _isLoadingGemini = false);
      return;
    }

    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final predictionCount = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/multimodal_gemini_xray'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'image_url': widget.originalImageUrl,
          'inference_result_id': widget.inferenceResultId,
          'model1Label': modelName,
          'model1Confidence': widget.model1Result['confidence'] ?? 0.0,
          'predictionCount': predictionCount,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final message = result['message'] ?? 'AI 소견을 불러오지 못했습니다';
        setState(() => _geminiOpinion = message);
      } else {
        setState(() => _geminiOpinion = 'AI 소견 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _geminiOpinion = 'AI 소견 요청 실패: $e');
    } finally {
      setState(() => _isLoadingGemini = false);
    }
  }

  Future<void> _loadImplantManufacturerResults() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final uri = Uri.parse('${widget.baseUrl}/xray_implant_classify');

    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"image_path": _relativePath}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = List<Map<String, dynamic>>.from(data['results']);
        setState(() => _implantResults = results);
      } else {
        // ignore: avoid_print
        print("❌ 제조사 분류 API 실패: ${res.body}");
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ 예외 발생: $e");
    }
  }

  Future<void> _saveResultImage() async {
    // 두 오버레이 중 선택해서 저장 (합성까지 원하면 별도 로직 추가 가능)
    final bytes = _showModel2 && _model2Bytes != null ? _model2Bytes : _model1Bytes;
    if (bytes == null) return;
    await ImageGallerySaver.saveImage(bytes, quality: 100, name: "xray_result_overlay");
  }

  Future<void> _saveOriginalImage() async {
    if (_originalImageBytes == null) return;
    await ImageGallerySaver.saveImage(_originalImageBytes!, quality: 100, name: "xray_original_image");
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {'glbUrl': 'assets/web/model/open_mouth.glb'});
  }

  Future<void> _submitConsultRequest(User currentUser) async {
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMddHHmmss').format(now);
    final httpService = HttpService(baseUrl: widget.baseUrl);

    final response = await httpService.post('/consult', {
      'user_id': widget.userId,
      'original_image_url': _relativePath,
      'request_datetime': formatted,
    });

    if (response.statusCode == 201) {
      context.push('/consult_success');
    } else {
      final msg = jsonDecode(response.body)['error'] ?? '신청 실패';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser;

    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final predictionCount = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3869A8),
        title: const Text('X-ray 진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildBody(currentUser, modelName, predictionCount),
                ),
              )
            : _buildBody(currentUser, modelName, predictionCount),
      ),
    );
  }

  Widget _buildBody(User? currentUser, String modelName, int predictionCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggleCard(),
          const SizedBox(height: 16),
          _buildXrayImage(),
          const SizedBox(height: 16),
          _buildXraySummaryCard(modelName, predictionCount),
          const SizedBox(height: 16),
          _buildGeminiOpinionCard(),
          const SizedBox(height: 24),
          if (currentUser?.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
            const SizedBox(height: 12),
            _buildActionButton(
              Icons.medical_services,
              'AI 예측 기반 비대면 진단 신청',
              () => _submitConsultRequest(currentUser!),
            ),
            const SizedBox(height: 12),
            _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
          ],
        ],
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
            const Text('인공지능 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStyledToggle("구강 상태 분석", _showModel1, (val) => setState(() => _showModel1 = val)),
            _buildStyledToggle("임플란트 분류", _showModel2, (val) => setState(() => _showModel2 = val)),
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
                if (_originalImageBytes != null)
                  Image.memory(_originalImageBytes!, fit: BoxFit.fill)
                else
                  const Center(child: CircularProgressIndicator()),
                // 🔹 서버 오버레이는 이미 알파 포함 → 추가 opacity 제거
                if (_showModel1 && _model1Bytes != null)
                  Image.memory(_model1Bytes!, fit: BoxFit.fill),
                if (_showModel2 && _model2Bytes != null)
                  Image.memory(_model2Bytes!, fit: BoxFit.fill),
              ],
            ),
          ),
        ),
      );

  Widget _buildXraySummaryCard(String modelName, int count) {
    final predictions = widget.model1Result['predictions'] as List<dynamic>?;

    final Map<String, int> classCounts = {};
    if (predictions != null && predictions.isNotEmpty) {
      for (final pred in predictions) {
        final className = pred['class_name'] ?? 'Unknown';
        if (className == '정상치아') continue;
        classCounts[className] = (classCounts[className] ?? 0) + 1;
      }
    }

    // 간단 색상 맵
    final Map<String, Color> colorMap = {
      '치아 우식증': Colors.red,
      '임플란트': Colors.blue,
      '보철물': Colors.yellow,
      '근관치료': Colors.green,
      '상실치아': Colors.black,
    };

    final bold = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    return Container(
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
          if (classCounts.isNotEmpty)
            ...classCounts.entries.map((e) {
              final color = colorMap[e.key] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('${e.key} ${e.value}개 감지', style: bold),
                  ],
                ),
              );
            }).toList(),
          if (classCounts.isEmpty) Text('감지된 객체가 없습니다.', style: bold),
          if (_implantResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('[임플란트 제조사 분류 결과]', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._implantResults.map((result) {
              final name = result['predicted_manufacturer_name'] ?? '알 수 없음';
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('-> $name: 1개', style: bold),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // 🔹 AI 소견 카드 (Markdown 렌더링)
  Widget _buildGeminiOpinionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI 소견', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_isLoadingGemini)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingGemini)
            const Text('AI 소견을 불러오는 중입니다...', style: TextStyle(fontSize: 16, height: 1.5))
          else
            MarkdownBody(
              data: _geminiOpinion ?? 'AI 소견을 불러오지 못했습니다.',
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 16, height: 1.5),
                strong: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
                h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                listBullet: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

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
