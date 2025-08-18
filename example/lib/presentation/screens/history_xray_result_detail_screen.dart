import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart'; // ✅ AI 소견 관련 날짜 포맷팅을 위해 추가

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/user.dart';
import '/data/service/http_service.dart'; // ✅ Consult 요청을 위해 추가

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
  List<Map<String, dynamic>> _implantResults = [];
  bool _isLoadingGemini = true; // ✅ AI 소견 로딩 상태 변수 추가
  String? _geminiOpinion; // ✅ AI 소견 저장 변수 추가

  // ✅ 추가: 의사 코멘트
  String? _doctorComment;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;

  String get _relativePath => widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';
    _loadImages();
    _loadImplantManufacturerResults();
    _getGeminiOpinion(); // ✅ 화면 진입 시 바로 AI 소견을 불러오도록 호출

    // ✅ 추가: 의사 응답이 완료된 경우 코멘트 가져오기
    if (_isReplied) {
      _fetchDoctorComment();
    }
  }

  // ✅ 추가: 의사 코멘트 불러오기 (GET /consult/status)
  Future<void> _fetchDoctorComment() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/consult/status?user_id=${widget.userId}&image_path=$relativePath'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          _doctorComment = data['doctor_comment'];
        });
      } else {
        // 실패 시에도 UI가 멈추지 않도록 로그만 남김
        // ignore: avoid_print
        print('❌ 의사 코멘트 가져오기 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ 서버 요청 실패: $e');
    }
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
      // ignore: avoid_print
      print('이미지 로딩 실패: $e');
    }
  }

  Future<void> _loadImplantManufacturerResults() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');
    final uri = Uri.parse('${widget.baseUrl}/xray_implant_classify');

    try {
      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"image_path": relativePath}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = List<Map<String, dynamic>>.from(data['results']);
        setState(() {
          _implantResults = results;
        });
      } else {
        // ignore: avoid_print
        print("❌ 제조사 분류 API 실패: ${res.body}");
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ 예외 발생: $e");
    }
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {
      'glbUrl': 'assets/web/model/open_mouth.glb',
    });
  }

  Future<Uint8List?> _loadImageWithAuth(String url, String token) async {
    final String resolvedUrl = url.startsWith('http')
        ? url
        : '${widget.baseUrl.replaceAll('/api', '')}${url.startsWith('/') ? '' : '/'}$url';

    final response = await http.get(Uri.parse(resolvedUrl), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) {
      // ignore: avoid_print
      print('❌ 이미지 요청 실패: $resolvedUrl (${response.statusCode})');
    }

    return response.statusCode == 200 ? response.bodyBytes : null;
  }

  // ✅ (유지) AI 소견 요청
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
        // ignore: avoid_print
        print('AI 소견 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _geminiOpinion = 'AI 소견 요청 실패: $e';
      });
      // ignore: avoid_print
      print('업로드 실패: $e');
    } finally {
      setState(() => _isLoadingGemini = false);
    }
  }

  // ✅ (유지) Consult 신청: HttpService 사용
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

  // ✅ (유지) Consult 취소
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
          const SizedBox(height: 16), // ✅ AI 소견 카드와 간격
          _buildGeminiOpinionCard(), // ✅ AI 소견 카드
          // ✅ 추가: 의사 코멘트 카드 (응답 완료 + 코멘트가 존재할 때만)
          if (_isReplied && (_doctorComment?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _buildDoctorCommentCard(_doctorComment!.trim()),
          ],
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

  // ✅ AI 소견 카드
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

  // ✅ 추가: 의사 코멘트 카드
  Widget _buildDoctorCommentCard(String comment) {
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
          const Text('의사 코멘트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(comment, style: const TextStyle(fontSize: 16, height: 1.5)),
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

    // ✅ 클래스별 색상을 정의
    final Map<String, Color> colorMap = {
      '치아 우식증': Colors.red,
      '임플란트': Colors.blue,
      '보철물': Colors.yellow,
      '근관치료': Colors.green,
      '상실치아': Colors.black,
    };

    // ✅ 결과 텍스트를 볼드로 표시하기 위한 스타일
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
                    Text('$className ${count}개 감지', style: bold),
                  ],
                ),
              );
            }).toList(),
          if (classCounts.isEmpty)
            Text('감지된 객체가 없습니다.', style: bold),
          if (_implantResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('[임플란트 제조사 분류 결과]', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._implantResults.map((result) {
              final name = result['predicted_manufacturer_name'] ?? '알 수 없음';
              final count = 1; // 분류 결과는 개별 임플란트이므로 항상 1
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('-> $name: ${count}개', style: bold),
              );
            }).toList(),
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
}
