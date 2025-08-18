import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  // ✅ implantClassificationResult를 위젯의 필드로 추가합니다.
  final List<dynamic>? implantClassificationResult;

  const UploadXrayResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.model1ImageUrl,
    required this.model2ImageUrl,
    required this.model1Result,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
    // ✅ 생성자에 추가
    this.implantClassificationResult,
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
  // ✅ 이제 이 리스트는 initState에서 widget.implantClassificationResult를 통해 초기화됩니다.
  List<Map<String, dynamic>> _implantClassificationResults = [];

  String get _relativePath => widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

  @override
  void initState() {
    super.initState();
    _loadImages();
    _getGeminiOpinion();

    // ✅ 위젯 필드에서 직접 임플란트 분류 결과를 가져와 초기화합니다.
    if (widget.implantClassificationResult != null &&
        widget.implantClassificationResult is List) {
      _implantClassificationResults = List<Map<String, dynamic>>.from(
        widget.implantClassificationResult!,
      );
    }
  }

  Future<void> _loadImages() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImage(widget.originalImageUrl, token);
      final overlay1 = await _loadImage(widget.model1ImageUrl, token);
      final overlay2 = await _loadImage(widget.model2ImageUrl, token);

      setState(() {
        _originalImageBytes = original;
        _model1Bytes = overlay1;
        _model2Bytes = overlay2;
      });
    } catch (e) {
      print('이미지 로딩 실패: $e');
    }
  }

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
        final message = result['message'] ?? 'AI 소견을 불러오지 못했습니다';
        setState(() {
          _geminiOpinion = message;
        });
      } else {
        setState(() {
          _geminiOpinion = 'AI 소견 요청 실패: ${response.statusCode}';
        });
        print('AI 소견 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _geminiOpinion = 'AI 소견 요청 실패: $e';
      });
      print('업로드 실패: $e');
    } finally {
      setState(() => _isLoadingGemini = false);
    }
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {
      'glbUrl': 'assets/web/model/open_mouth.glb',
    });
  }

  Future<Uint8List?> _loadImage(String url, String token) async {
    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });

    return res.statusCode == 200 ? res.bodyBytes : null;
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // ✅ 웹에서 중앙 고정 및 폭 제한
          child: SingleChildScrollView(
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
                  _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
                  const SizedBox(height: 12),
                  _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
                  const SizedBox(height: 12),
                  _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', () => _submitConsultRequest(currentUser!)),
                  const SizedBox(height: 12),
                  _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
                ]
              ],
            ),
          ),
        ),
      ),
    );
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
            const Text('인공지능 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),// 250814 변경
            const SizedBox(height: 12),
            _buildStyledToggle("구강 상태 분석", _showModel1, (val) => setState(() => _showModel1 = val)),// 250814 변경
            _buildStyledToggle("임플란트 분류", _showModel2, (val) => setState(() => _showModel2 = val)),// 250814 변경
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
                  Image.memory(_originalImageBytes!, fit: BoxFit.fill),
                if (_showModel1 && _model1Bytes != null)
                  Image.memory(_model1Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                if (_showModel2 && _model2Bytes != null)
                  Image.memory(_model2Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
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

    // ✅ 클래스별 색상을 정의
    final Map<String, Color> colorMap = {
        '치아 우식증': Colors.red,
        '임플란트': Colors.blue,
        '보철물': Colors.yellow,
        '근관치료': Colors.black, // ✅ 검은색으로 변경
        '상실치아': Colors.green,
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
          // ✅ 클래스별 색깔 동그라미 및 개수 표시
          if (classCounts.isNotEmpty)
            ...classCounts.entries.map((e) {
              final className = e.key;
              final count = e.value;
              final color = colorMap[className] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$className ${count}개 감지'),
                  ],
                ),
              );
            }).toList(),
          if (classCounts.isEmpty)
            const Text('감지된 객체가 없습니다.'),
          if (_implantClassificationResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('[임플란트 제조사 분류 결과]', style: TextStyle(fontWeight: FontWeight.bold)),

            // ✅ 번호별로 중복 제거 + 개수 집계 (전 클래스 자동 대응)
            ...(() {
              final Map<int, Map<String, dynamic>> legend = {};
              for (final r in _implantClassificationResults) {
                final id = (r['predicted_manufacturer_class'] as num?)?.toInt();
                if (id == null) continue;

                // 우선순위: display_name → predicted_manufacturer_name → '알 수 없음'
                final displayName = (r['display_name'] ??
                    r['predicted_manufacturer_name'] ??
                    '알 수 없음') as String;

                if (legend.containsKey(id)) {
                  legend[id]!['count'] = (legend[id]!['count'] as int) + 1;
                } else {
                  legend[id] = {'name': displayName, 'count': 1};
                }
              }

              // 번호 오름차순 정렬
              final entries = legend.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));

              // 출력: "-> 29: 덴티움 수퍼라인 (2개)" 형식
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
          ],
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
} // ✅ _UploadXrayResultDetailScreenState 클래스를 닫는 괄호입니다.
