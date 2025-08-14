// 생략된 import는 그대로 유지
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ 웹 화면 고정용 추가
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
  late bool _isRequested;
  late bool _isReplied;
  String? _doctorComment;
  List<Map<String, dynamic>> _implantResults = [];

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';
    _loadImages();
    _loadImplantManufacturerResults();
    if (_isReplied) {
      _fetchDoctorComment();
    }
  }

  // ✅ `GET /consult/status`로 엔드포인트 및 메소드 수정
  Future<void> _fetchDoctorComment() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/consult/status?user_id=${widget.userId}&image_path=$relativePath'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          _doctorComment = data['doctor_comment'];
        });
      } else {
        print("❌ 의사 코멘트 가져오기 실패: ${response.statusCode} - ${response.body}");
        if (!mounted) return;
        setState(() {
          _doctorComment = "의사 코멘트를 불러오는 데 실패했습니다.";
        });
      }
    } catch (e) {
      print('❌ 서버 요청 실패: $e');
      if (!mounted) return;
      setState(() {
        _doctorComment = "서버와 통신 중 문제가 발생했습니다.";
      });
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
        if (!mounted) return;
        setState(() {
          _implantResults = results;
        });
      } else {
        print("❌ 제조사 분류 API 실패: ${res.body}");
      }
    } catch (e) {
      print("❌ 예외 발생: $e");
    }
  }

  Future<void> _loadImages() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final ov1 = await _loadImageWithAuth(widget.model1ImageUrl, token);
      final ov2 = await _loadImageWithAuth(widget.model2ImageUrl, token);
      if (!mounted) return;
      setState(() {
        originalImageBytes = original;
        overlay1Bytes = ov1;
        overlay2Bytes = ov2;
      });
    } catch (e) {
      print('이미지 로딩 실패: $e');
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

    try {
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
        if (!mounted) return;
        context.push('/consult_success', extra: {'type': 'apply'});
        return;
      }

      String? serverMsg;
      try {
        final body = jsonDecode(response.body);
        serverMsg = body is Map<String, dynamic> ? body['error'] as String? : null;
      } catch (_) { /* ignore */ }

      final alreadyRequested =
          response.statusCode == 409 ||
          (serverMsg != null && serverMsg.contains('이미 신청'));

      if (alreadyRequested) {
        if (!mounted) return;
        await showDialog(
          context: context,
          useRootNavigator: true,
          builder: (dialogContext) => AlertDialog(
            title: const Text('알림'),
            content: Text(serverMsg ?? '이미 신청 중인 진료가 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        context.pop();
        return;
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('신청 실패'),
          content: Text(serverMsg ?? '신청 실패'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ 서버 요청 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 문제가 발생했습니다.')),
      );
    }
  }

  Future<void> _cancelConsultRequest() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    try {
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
        if (!mounted) return;
        setState(() => _isRequested = false);
        context.push('/consult_success', extra: {'type': 'cancel'});
      } else {
        final msg = jsonDecode(response.body)['error'] ?? '취소 실패';
        _showErrorDialog(msg);
      }
    } catch (e) {
      print('❌ 서버 요청 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 문제가 발생했습니다.')),
      );
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
    final textTheme = Theme.of(context).textTheme;
    final modelName = widget.model1Result['used_model'] ?? 'N/A';
    final count = (widget.model1Result['predictions'] as List?)?.length ?? 0;

    Widget consultButton;
    if (!_isRequested) {
      consultButton = _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', () => _submitConsultRequest(currentUser));
    } else if (_isRequested && !_isReplied) {
      consultButton = _buildActionButton(Icons.medical_services, 'AI 예측 기반 진단 신청 취소', _cancelConsultRequest);
    } else {
      consultButton = Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3869A8).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '진단 응답 완료',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    Widget? doctorCommentCard;
    if (_isReplied && _doctorComment != null) {
      doctorCommentCard = _buildCommentCard(_doctorComment!, textTheme);
    }

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
          if (doctorCommentCard != null) ...[
            const SizedBox(height: 16),
            doctorCommentCard,
          ],
          const SizedBox(height: 24),
          if (currentUser.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
            const SizedBox(height: 12),
            consultButton,
            const SizedBox(height: 12),
            _buildActionButton(Icons.chat, 'AI 소견 들어보기', _getGeminiOpinion),
            const SizedBox(height: 12),
            _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
          ]
        ],
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

  Widget _buildXraySummaryCard(String modelName, int count) {
    final predictions = widget.model1Result['predictions'] as List<dynamic>?;

    String summaryText = '감지된 객체가 없습니다.';
    if (predictions != null && predictions.isNotEmpty) {
      final Map<String, int> classCounts = {};
      for (final pred in predictions) {
        final className = pred['class_name'] ?? 'Unknown';
        if (className == '정상치아') continue;
        classCounts[className] = (classCounts[className] ?? 0) + 1;
      }

      if (classCounts.isNotEmpty) {
        final lines = classCounts.entries.map((e) => '${e.key} ${e.value}개 감지').toList();
        summaryText = lines.join('\n');
      }
    }

    if (_implantResults.isNotEmpty) {
      if(summaryText == '감지된 객체가 없습니다.') {
        summaryText = "[임플란트 제조사 분류 결과]";
      } else {
        summaryText += "\n\n[임플란트 제조사 분류 결과]";
      }
      final countMap = <String, int>{};

      for (final result in _implantResults) {
        final name = result['predicted_manufacturer_name'] ?? '알 수 없음';
        countMap[name] = (countMap[name] ?? 0) + 1;
      }

      countMap.forEach((name, cnt) {
        summaryText += "\n→ $name: $cnt개";
      });
    }

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
          Text(summaryText),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed) => ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? const Color(0xFF3869A8) : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

  Widget _buildCommentCard(String comment, TextTheme textTheme) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('의사 코멘트', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(comment, style: textTheme.bodyMedium),
        ],
      ),
    );
}