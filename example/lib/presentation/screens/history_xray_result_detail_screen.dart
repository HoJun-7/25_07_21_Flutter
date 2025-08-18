// lib/presentation/screens/history_xray_result_detail_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/user.dart';
import '/data/service/http_service.dart';

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
  // 옵션: 이미 리스트에서 받아왔을 수도 있는 분류 결과
  final List<dynamic>? implantClassificationResult;

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
    this.implantClassificationResult,
  });

  @override
  State<HistoryXrayResultDetailScreen> createState() =>
      _HistoryXrayResultDetailScreenState();
}

class _HistoryXrayResultDetailScreenState
    extends State<HistoryXrayResultDetailScreen> {
  bool _showModel1 = true;
  bool _showModel2 = true;
  bool _isRequested = false;
  bool _isReplied = false;

  // 임플란트 제조사 분류 결과(방어적 파싱 후 저장)
  List<Map<String, dynamic>> _implantResults = [];

  bool _isLoadingGemini = true;
  String? _geminiOpinion;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;

  String get _relativePath =>
      widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';

    _loadImages();
    _getGeminiOpinion();

    // 1) extras로 넘어온 결과를 먼저 방어적으로 파싱
    _implantResults = _parseImplantList(widget.implantClassificationResult);

    // 2) 비어 있으면 서버에서 다시 조회(히스토리 레코드가 오래된 형식일 수 있음)
    if (_implantResults.isEmpty) {
      _loadImplantManufacturerResults();
    }
  }

  // ========== 이미지 로딩(모델2 폴백 포함) ==========
  Future<void> _loadImages() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final ov1 = await _loadImageWithAuth(widget.model1ImageUrl, token);
      final ov2 = await _loadModel2WithFallback(widget.model2ImageUrl, token);

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

    final response =
        await http.get(Uri.parse(resolvedUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      print('❌ 이미지 요청 실패: $resolvedUrl (${response.statusCode})');
    }
    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  // model2 전용: 404면 *_implant_classified.png 로 한 번 더 시도
  Future<Uint8List?> _loadModel2WithFallback(String url, String token) async {
    final bytes = await _loadImageWithAuth(url, token);
    if (bytes != null) return bytes;

    // 404였고, implant_classified 붙인 파일이 있을 수 있음
    if (!url.contains('_implant_classified') && url.endsWith('.png')) {
      final alt = url.replaceFirst('.png', '_implant_classified.png');
      print('🔁 model2 폴백 재시도: $alt');
      return _loadImageWithAuth(alt, token);
    }
    return null;
  }

  // ========== 임플란트 결과 폴백 조회(히스토리) ==========
  Future<void> _loadImplantManufacturerResults() async {
    try {
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) return;

      final uri = Uri.parse('${widget.baseUrl}/xray_implant_classify');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'image_path': _relativePath}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final parsed = _parseImplantList(data['results']);
        if (!mounted) return;
        setState(() => _implantResults = parsed);
        print('[HISTORY XRAY] fetched implant results: ${parsed.length}');
      } else {
        print('❌ 제조사 분류 API 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
    }
  }

  // ========== 방어적 파싱 유틸 ==========
  List<Map<String, dynamic>> _parseImplantList(dynamic raw) {
    final List<Map<String, dynamic>> out = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          out.add(Map<String, dynamic>.from(item));
        } else if (item is List) {
          // 리스트 안에 리스트가 올 때 평탄화
          for (final sub in item) {
            if (sub is Map) out.add(Map<String, dynamic>.from(sub));
          }
        } else {
          // 무시
        }
      }
    }
    return out;
  }

  // ========== Gemini 소견 ==========
  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
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
        setState(() => _geminiOpinion = result['message'] ?? 'AI 소견을 불러오지 못했습니다');
      } else {
        setState(() => _geminiOpinion = 'AI 소견 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _geminiOpinion = 'AI 소견 요청 실패: $e');
    } finally {
      setState(() => _isLoadingGemini = false);
    }
  }

  // ========== 비대면 진단 신청/취소 ==========
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

  Future<void> _cancelConsultRequest() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('${widget.baseUrl}/consult/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': widget.userId,
        'original_image_url': _relativePath,
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

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {
      'glbUrl': 'assets/web/model/open_mouth.glb',
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser!;

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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildMainBody(currentUser),
                ),
              )
            : _buildMainBody(currentUser),
      ),
    );
  }

  Widget _buildMainBody(User currentUser) {
    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final count = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggleCard(),
          const SizedBox(height: 16),
          _buildImageCard(),
          const SizedBox(height: 16),
          _buildXraySummaryCard(modelName, count),
          const SizedBox(height: 16),
          _buildGeminiOpinionCard(),
          const SizedBox(height: 24),
          if (currentUser.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
            const SizedBox(height: 12),
            if (!_isRequested)
              _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청',
                  () => _submitConsultRequest(currentUser))
            else if (_isRequested && !_isReplied)
              _buildActionButton(Icons.medical_services, 'AI 예측 기반 진단 신청 취소',
                  _cancelConsultRequest),
            const SizedBox(height: 12),
            _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
          ]
        ],
      ),
    );
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
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isLoadingGemini
                ? 'AI 소견을 불러오는 중입니다...'
                : _geminiOpinion ?? 'AI 소견을 불러오지 못했습니다.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
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

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Container(
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
                if (originalImageBytes != null) Image.memory(originalImageBytes!, fit: BoxFit.fill),
                if (_showModel1 && overlay1Bytes != null)
                  Image.memory(overlay1Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                if (_showModel2 && overlay2Bytes != null)
                  Image.memory(overlay2Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
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

    final Map<String, Color> colorMap = {
        '치아 우식증': Colors.red,
        '임플란트': Colors.blue,
        '보철물': Colors.yellow,
        '근관치료': Colors.green, // ✅ 검은색으로 변경
        '상실치아': Colors.black,
    };

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
                    Text('${e.key} ${e.value}개 감지'),
                  ],
                ),
              );
            }).toList()
          else
            const Text('감지된 객체가 없습니다.'),

          const SizedBox(height: 10),
          const Text('[임플란트 제조사 분류 결과]', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_implantResults.isNotEmpty) ...[
            ...(() {
              final Map<int, Map<String, dynamic>> legend = {};
              for (final r in _implantResults) {
                final id = (r['predicted_manufacturer_class'] as num?)?.toInt();
                if (id == null) continue;

                final displayName =
                    (r['display_name'] ?? r['predicted_manufacturer_name'] ?? '알 수 없음') as String;

                if (legend.containsKey(id)) {
                  legend[id]!['count'] = (legend[id]!['count'] as int) + 1;
                } else {
                  legend[id] = {'name': displayName, 'count': 1};
                }
              }

              final entries = legend.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));

              return entries.map((e) {
                final id = e.key;
                final name = e.value['name'] as String;
                final cnt = e.value['count'] as int;
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('-> $id: $name${cnt > 1 ? " (${cnt}개)" : ""}'),
                );
              }).toList();
            })(),
          ] else ...[
            const SizedBox(height: 4),
            const Text('감지된 임플란트 제조사 분류 결과가 없습니다.'),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed) =>
      ElevatedButton.icon(
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
