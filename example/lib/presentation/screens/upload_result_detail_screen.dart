// example/lib/presentation/screens/upload_result_detail_screen.dart

import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui; // ✅ 이미지 합성용 라이브러리 추가
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/model/user.dart';

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

  // ✅ X-ray 화면과 동일: 자동 로드용 상태
  bool _isLoadingGemini = true;
  String? _geminiOpinion;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;
  Uint8List? overlay3Bytes;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _getGeminiOpinion(); // ✅ 자동 로드
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

      if (!mounted) return;
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

  Future<void> _saveResultImage() async {
    if (originalImageBytes == null) {
      _showErrorDialog('원본 이미지를 찾을 수 없습니다.');
      return;
    }

    try {
      final ui.Codec originalCodec = await ui.instantiateImageCodec(originalImageBytes!);
      final ui.FrameInfo originalFrame = await originalCodec.getNextFrame();
      final ui.Image originalImage = originalFrame.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      canvas.drawImage(originalImage, Offset.zero, Paint());

      final Paint overlayPaint = Paint()
        ..colorFilter = const ui.ColorFilter.mode(Colors.transparent, ui.BlendMode.srcOver);

      if (_showDisease && overlay1Bytes != null) {
        final ui.Codec overlay1Codec = await ui.instantiateImageCodec(overlay1Bytes!);
        final ui.FrameInfo overlay1Frame = await overlay1Codec.getNextFrame();
        final ui.Image overlay1Image = overlay1Frame.image;
        canvas.drawImage(overlay1Image, Offset.zero, overlayPaint);
      }

      if (_showHygiene && overlay2Bytes != null) {
        final ui.Codec overlay2Codec = await ui.instantiateImageCodec(overlay2Bytes!);
        final ui.FrameInfo overlay2Frame = await overlay2Codec.getNextFrame();
        final ui.Image overlay2Image = overlay2Frame.image;
        canvas.drawImage(overlay2Image, Offset.zero, overlayPaint);
      }

      if (_showToothNumber && overlay3Bytes != null) {
        final ui.Codec overlay3Codec = await ui.instantiateImageCodec(overlay3Bytes!);
        final ui.FrameInfo overlay3Frame = await overlay3Codec.getNextFrame();
        final ui.Image overlay3Image = overlay3Frame.image;
        canvas.drawImage(overlay3Image, Offset.zero, overlayPaint);
      }

      final ui.Image compositeImage =
          await recorder.endRecording().toImage(originalImage.width, originalImage.height);
      final ByteData? byteData = await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resultBytes = byteData!.buffer.asUint8List();

      final result =
          await ImageGallerySaver.saveImage(resultBytes, quality: 100, name: "dental_result_image");

      if (!mounted) return;
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('진단 결과 이미지가 저장되었습니다.')));
      } else {
        _showErrorDialog('이미지 저장에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _saveOriginalImage() async {
    if (originalImageBytes == null) {
      _showErrorDialog('원본 이미지를 찾을 수 없습니다.');
      return;
    }
    final result = await ImageGallerySaver.saveImage(originalImageBytes!,
        quality: 100, name: "dental_original_image");
    if (result['isSuccess'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('원본 이미지가 저장되었습니다.')));
    } else {
      if (!mounted) return;
      _showErrorDialog('이미지 저장에 실패했습니다.');
    }
  }

  Future<void> _applyConsultRequest() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      if (!mounted) return;
      _showErrorDialog('인증 토큰이 없습니다. 다시 로그인해주세요.');
      return;
    }

    final now = DateTime.now();
    final requestDatetime = DateFormat('yyyyMMddHHmmss').format(now);

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

      if (!mounted) return;
      if (response.statusCode == 201) {
        // ✅ 성공 시 현재 화면 닫고 성공 화면으로 이동
        context.pop();
        context.push('/consult_success', extra: {'type': 'apply'});
        return;
      }

      String? serverMsg;
      try {
        final body = jsonDecode(response.body);
        serverMsg = body is Map<String, dynamic> ? body['error'] as String? : null;
      } catch (_) { /* ignore */ }

      final alreadyRequested =
          response.statusCode == 409 || (serverMsg != null && serverMsg.contains('이미 신청'));

      if (alreadyRequested) {
        await showDialog(
          context: context,
          useRootNavigator: true,
          builder: (dialogContext) => AlertDialog(
            title: const Text('알림'),
            content: Text(serverMsg ?? '이미 신청 중인 진료가 있습니다.'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        // ✅ 팝업 닫은 후 이전 화면으로 돌아가기
        context.pop();
        return;
      }

      await showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('신청 실패'),
          content: Text(serverMsg ?? '신청에 실패했습니다.'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ 서버 요청 실패: $e');
      if (!mounted) return;
      _showErrorDialog('서버와 통신 중 문제가 발생했습니다.');
    }
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {
      'glbUrl': 'assets/web/model/open_mouth.glb',
    });
  }

  // ✅ X-ray 방식과 동일: 자동 로드 + 카드 표시
  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      setState(() => _isLoadingGemini = false);
      if (!mounted) return;
      _showErrorDialog('인증 토큰이 없습니다. 다시 로그인해주세요.');
      return;
    }

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    try {
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

      if (!mounted) return;
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
      }
    } catch (e) {
      print('❌ AI 소견 요청 실패: $e');
      if (!mounted) return;
      setState(() {
        _geminiOpinion = '서버와 통신 중 문제가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingGemini = false);
    }
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("에러"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser;
    final textTheme = Theme.of(context).textTheme;

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];
    final List<dynamic> model1DetectedLabels = model1?['detected_labels'] ?? [];
    final List<String> model2DetectedLabels =
        (model2?['detected_labels'] as List? ?? [])
            .map((e) => e.toString().trim())
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3869A8),
        title: const Text('진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildMainBody(
                    currentUser,
                    textTheme,
                    model1DetectedLabels,
                    model2DetectedLabels,
                    model2,
                    model3,
                  ),
                ),
              )
            : _buildMainBody(
                currentUser,
                textTheme,
                model1DetectedLabels,
                model2DetectedLabels,
                model2,
                model3,
              ),
      ),
    );
  }

  Widget _buildMainBody(
    User? currentUser,
    TextTheme textTheme,
    List<dynamic> model1DetectedLabels,
    List<String> model2DetectedLabels,
    Map<String, dynamic>? model2,
    Map<String, dynamic>? model3,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggleCard(const Color(0xFFEAEAEA)),
          const SizedBox(height: 16),
          _buildImageCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(
            model1DetectedLabels: model1DetectedLabels,
            model2DetectedLabels: model2DetectedLabels,
            textTheme: textTheme,
            model2Label: model2?['label'] ?? '감지되지 않음',
            model2Confidence: model2?['confidence'] ?? 0.0,
            model3ToothNumber: model3?['tooth_number_fdi']?.toString() ?? 'Unknown',
            model3Confidence: model3?['confidence'] ?? 0.0,
          ),
          const SizedBox(height: 16),
          _buildGeminiOpinionCard(), // ✅ 카드로 같은 화면에서 표시
          const SizedBox(height: 24),
          if (currentUser?.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', _applyConsultRequest),
            const SizedBox(height: 12),
            // ❌ 기존의 'AI 소견 들어보기' 버튼 제거 (자동 로드 방식)
            _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
          ]
        ],
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
                Image.memory(overlay1Bytes!, fit: BoxFit.fill),
              if (_showHygiene && overlay2Bytes != null)
                Image.memory(overlay2Bytes!, fit: BoxFit.fill),
              if (_showToothNumber && overlay3Bytes != null)
                Image.memory(overlay3Bytes!, fit: BoxFit.fill),
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

  final Map<String, String> diseaseLabelMap = {
    "충치 초기": "🔴",
    "충치 중기": "🟡",
    "충치 말기": "🟠",
    "잇몸 염증 초기": "🔵",
    "잇몸 염증 중기": "🟢",
    "잇몸 염증 말기": "⚪",
    "치주질환 초기": "⚫",
    "치주질환 중기": "🟩",
    "치주질환 말기": "🟣",
  };

  final Map<String, String> hygieneLabelMap = {
    "교정장치 (ortho)": "🔴",
    "골드 (gcr)": "🟣",
    "메탈크라운 (mcr)": "🟡",
    "세라믹 (cecr)": "⚪",
    "아말감 (am)": "⚫",
    "지르코니아 (zircr)": "🟢",
    "치석 단계1 (tar1)": "🟠",
    "치석 단계2 (tar2)": "🔵",
    "치석 단계3 (tar3)": "🟤",
  };

  Widget _buildSummaryCard({
    required List<dynamic> model1DetectedLabels,
    required List<dynamic> model2DetectedLabels,
    required String model2Label,
    required double model2Confidence,
    required String model3ToothNumber,
    required double model3Confidence,
    required TextTheme textTheme,
  }) {
    final filteredDiseaseLabels = _showDisease ? model1DetectedLabels : <dynamic>[];
    final List<String> hygieneLabels = _showHygiene
        ? model2DetectedLabels
            .whereType<String>()
            .where((l) => hygieneLabelMap.containsKey(l))
            .toSet()
            .toList()
        : <String>[];

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
          if (filteredDiseaseLabels.isNotEmpty) ...[
            const Text('충치/잇몸 염증/치주질환', style: TextStyle(fontWeight: FontWeight.w600)),
            ...filteredDiseaseLabels.map((label) {
              final icon = diseaseLabelMap[label] ?? "❓";
              return Text("$icon : $label", style: textTheme.bodyMedium);
            }),
            const SizedBox(height: 8),
          ],
          if (_showHygiene) ...[
            const Text('치석/보철물', style: TextStyle(fontWeight: FontWeight.w600)),
            if (hygieneLabels.isNotEmpty)
              ...hygieneLabels.map((l) => Text("${hygieneLabelMap[l]} : $l", style: textTheme.bodyMedium))
            else
              Text('감지되지 않음', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
          if (_showToothNumber && model3ToothNumber != 'Unknown') ...[
            const Text('치아번호', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('FDI 번호: $model3ToothNumber', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
          if (filteredDiseaseLabels.isEmpty && hygieneLabels.isEmpty && model3ToothNumber == 'Unknown')
            Text('감지된 내용이 없습니다.', style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ✅ X-ray와 동일한 스타일의 AI 소견 카드
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? const Color(0xFF3869A8) : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
