// example/lib/presentation/screens/history_result_detail_screen.dart

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

class HistoryResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;
  final String isRequested;
  final String isReplied;

  const HistoryResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
    required this.userId,
    required this.inferenceResultId,
    required this.baseUrl,
    required this.isRequested,
    required this.isReplied,
  });

  @override
  State<HistoryResultDetailScreen> createState() => _HistoryResultDetailScreenState();
}

class _HistoryResultDetailScreenState extends State<HistoryResultDetailScreen> {
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;

  /// ✅ AI 소견 자동 로드 상태
  bool _isLoadingGemini = true;
  String? _geminiOpinion;

  late bool _isRequested;
  late bool _isReplied;
  String? _doctorComment;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;
  Uint8List? overlay3Bytes;

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';
    _loadImages();
    if (_isReplied) _fetchDoctorComment();
    _getGeminiOpinion(); // ✅ AI 소견 자동 로드
  }

  Future<void> _fetchDoctorComment() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) return;

    final relativePath = widget.originalImageUrl.replaceFirst(
      widget.baseUrl.replaceAll('/api', ''),
      '',
    );

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/consult/status?user_id=${widget.userId}&image_path=$relativePath'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() => _doctorComment = data['doctor_comment']);
      } else {
        if (!mounted) return;
        setState(() => _doctorComment = "의사 코멘트를 불러오는 데 실패했습니다.");
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _doctorComment = "서버와 통신 중 문제가 발생했습니다.");
    }
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
      debugPrint('이미지 로딩 실패: $e');
    }
  }

  Future<Uint8List?> _loadImageWithAuth(String? url, String token) async {
    if (url == null) return null;
    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200 ? response.bodyBytes : null;
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

      final Paint overlayPaint =
          Paint()..colorFilter = const ui.ColorFilter.mode(Colors.transparent, ui.BlendMode.srcOver);

      if (_showDisease && overlay1Bytes != null) {
        final ui.Image img = (await (await ui.instantiateImageCodec(overlay1Bytes!)).getNextFrame()).image;
        canvas.drawImage(img, Offset.zero, overlayPaint);
      }
      if (_showHygiene && overlay2Bytes != null) {
        final ui.Image img = (await (await ui.instantiateImageCodec(overlay2Bytes!)).getNextFrame()).image;
        canvas.drawImage(img, Offset.zero, overlayPaint);
      }
      if (_showToothNumber && overlay3Bytes != null) {
        final ui.Image img = (await (await ui.instantiateImageCodec(overlay3Bytes!)).getNextFrame()).image;
        canvas.drawImage(img, Offset.zero, overlayPaint);
      }

      final ui.Image compositeImage =
          await recorder.endRecording().toImage(originalImage.width, originalImage.height);
      final ByteData? byteData = await compositeImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resultBytes = byteData!.buffer.asUint8List();

      final result =
          await ImageGallerySaver.saveImage(resultBytes, quality: 100, name: "dental_result_image");

      if (!mounted) return;
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('진단 결과 이미지가 저장되었습니다.')));
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
    final result = await ImageGallerySaver.saveImage(
      originalImageBytes!,
      quality: 100,
      name: "dental_original_image",
    );
    if (!mounted) return;
    if (result['isSuccess'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('원본 이미지가 저장되었습니다.')));
    } else {
      _showErrorDialog('이미지 저장에 실패했습니다.');
    }
  }

  Future<void> _applyConsultRequest() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
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
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'user_id': widget.userId,
          'original_image_url': relativePath,
          'request_datetime': requestDatetime,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 201) {
        setState(() {
          _isRequested = true;
          _isReplied = false;
        });
        context.push('/consult_success', extra: {'type': 'apply'});
        return;
      }

      String? serverMsg;
      try {
        final body = jsonDecode(response.body);
        serverMsg = body is Map<String, dynamic> ? body['error'] as String? : null;
      } catch (_) {}

      final alreadyRequested = response.statusCode == 409 || (serverMsg != null && serverMsg.contains('이미 신청'));

      if (alreadyRequested) {
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

      await showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('신청 실패'),
          content: Text(serverMsg ?? '신청에 실패했습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('서버와 통신 중 문제가 발생했습니다.');
    }
  }

  Future<void> _cancelConsultRequest() async {
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) {
      _showErrorDialog('인증 토큰이 없습니다. 다시 로그인해주세요.');
      return;
    }

    final relativePath = widget.originalImageUrl.replaceFirst(
      widget.baseUrl.replaceAll('/api', ''),
      '',
    );

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/consult/cancel'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.userId, 'original_image_url': relativePath}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => _isRequested = false);
        context.push('/consult_success', extra: {'type': 'cancel'});
      } else {
        final msg = jsonDecode(response.body)['error'] ?? '신청 취소 실패';
        _showErrorDialog('❌ $msg');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('서버와 통신 중 문제가 발생했습니다.');
    }
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {'glbUrl': 'assets/web/model/open_mouth.glb'});
  }

  /// ✅ 자동 로드 + 카드 표시
  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final token = await context.read<AuthViewModel>().getAccessToken();
    if (token == null) {
      setState(() => _isLoadingGemini = false);
      _showErrorDialog('인증 토큰이 없습니다. 다시 로그인해주세요.');
      return;
    }

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/multimodal_gemini'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
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
        setState(() => _geminiOpinion = message);
      } else {
        setState(() => _geminiOpinion = 'AI 소견 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _geminiOpinion = '서버와 통신 중 문제가 발생했습니다.');
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))],
      ),
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthViewModel>().currentUser;

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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildMainBody(currentUser),
                ),
              )
            : _buildMainBody(currentUser),
      ),
    );
  }

  Widget _buildMainBody(User? currentUser) {
    final textTheme = Theme.of(context).textTheme;

    final model1 = widget.modelInfos[1];
    final model2 = widget.modelInfos[2];
    final model3 = widget.modelInfos[3];

    final List<dynamic> model1DetectedLabels = model1?['detected_labels'] ?? [];
    final List<String> model2DetectedLabels =
        (model2?['detected_labels'] as List? ?? []).map((e) => e.toString().trim()).toList();
    final String model3ToothNumber = model3?['tooth_number_fdi']?.toString() ?? 'Unknown';

    Widget consultButton;
    if (!_isRequested) {
      consultButton = _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', _applyConsultRequest);
    } else if (_isRequested && !_isReplied) {
      consultButton = _buildActionButton(Icons.medical_services, 'AI 예측 기반 진단 신청 취소', _cancelConsultRequest);
    } else {
      // _isRequested && _isReplied
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
            Text('진단 응답 완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          _buildToggleCard(const Color(0xFFEAEAEA)),
          const SizedBox(height: 16),
          _buildImageCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(
            model1DetectedLabels: model1DetectedLabels,
            model2DetectedLabels: model2DetectedLabels,
            model3ToothNumber: model3ToothNumber,
            textTheme: textTheme,
          ),
          const SizedBox(height: 16),
          _buildGeminiOpinionCard(), // ✅ AI 소견 카드 표시
          if (doctorCommentCard != null) ...[
            const SizedBox(height: 16),
            doctorCommentCard,
          ],
          const SizedBox(height: 24),
          if (currentUser?.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', _saveResultImage),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', _saveOriginalImage),
            const SizedBox(height: 12),
            consultButton,
            const SizedBox(height: 12),
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

  /// ✅ 아이콘 매핑(필요시 Upload 화면과 동일하게 조정 가능)
  final Map<String, String> diseaseLabelMap = {
    "충치 초기": "🔴",
    "충치 중기": "🟢",
    "충치 말기": "🔵",
    "잇몸 염증 초기": "🟡",
    "잇몸 염증 중기": "🟣",
    "잇몸 염증 말기": "🟦",
    "치주질환 초기": "🟧",
    "치주질환 중기": "🟪",
    "치주질환 말기": "⚫",
  };

  final Map<String, String> hygieneLabelMap = {
    "아말감 (am)": "🔴",
    "세라믹 (cecr)": "🟣",
    "골드 (gcr)": "🟡",
    "메탈크라운 (mcr)": "⚪",
    "교정장치 (ortho)": "⚫",
    "치석 단계1 (tar1)": "🟢",
    "치석 단계2 (tar2)": "🟠",
    "치석 단계3 (tar3)": "🔵",
    "지르코니아 (zircr)": "🟤",
  };

  /// ✅ 문자열/Map 형태 모두 처리 + 모두 볼드체로 출력
  Widget _buildSummaryCard({
    required List<dynamic> model1DetectedLabels,
    required List<String> model2DetectedLabels,
    required String model3ToothNumber,
    required TextTheme textTheme,
  }) {
    // 1) 질환 라벨 정규화: String/Map 모두 처리
    final List<String> diseaseLabels = _showDisease
        ? model1DetectedLabels
            .map((e) {
              if (e is String) return e.trim();
              if (e is Map<String, dynamic>) {
                final v = e['class_name'] ?? e['label'];
                return v == null ? '' : v.toString().trim();
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];

    // 2) 위생/보철 라벨 정규화
    final List<String> hygieneLabels = _showHygiene
        ? model2DetectedLabels.where((l) => hygieneLabelMap.containsKey(l)).toSet().toList()
        : <String>[];

    final bold = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

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

          // 충치/염증/치주
          if (_showDisease) ...[
            const Text('충치/잇몸 염증/치주질환', style: TextStyle(fontWeight: FontWeight.w600)),
            if (diseaseLabels.isNotEmpty)
              ...diseaseLabels.map((label) {
                final icon = diseaseLabelMap[label] ?? "❓";
                return Text("$icon : $label", style: bold);
              })
            else
              const Text("❓ : 알 수 없음", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],

          // 치석/보철물
          if (_showHygiene) ...[
            const Text('치석/보철물', style: TextStyle(fontWeight: FontWeight.w600)),
            if (hygieneLabels.isNotEmpty)
              ...hygieneLabels.map((l) => Text("${hygieneLabelMap[l]} : $l", style: bold))
            else
              Text('감지되지 않음', style: bold),
            const SizedBox(height: 8),
          ],

          // 치아번호
          if (_showToothNumber && model3ToothNumber != 'Unknown') ...[
            const Text('치아번호', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('FDI 번호: $model3ToothNumber', style: bold),
            const SizedBox(height: 8),
          ],

          if (!_showDisease && !_showHygiene && model3ToothNumber == 'Unknown')
            Text('감지된 내용이 없습니다.', style: bold),
        ],
      ),
    );
  }

  // ✅ AI 소견 카드 (자동 로드 상태/결과 표시)
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
          Text(
            _isLoadingGemini ? 'AI 소견을 불러오는 중입니다...' : (_geminiOpinion ?? 'AI 소견을 불러오지 못했습니다.'),
            style: const TextStyle(fontSize: 16, height: 1.5),
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
