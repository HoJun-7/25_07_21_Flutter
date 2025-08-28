// example/lib/presentation/screens/doctor/d_result_detail_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';

class DResultDetailScreen extends StatefulWidget {
  final String userId;
  /// 상대 경로(ex: /images/original/....png) 또는 절대 URL도 허용
  final String originalImageUrl;
  final String baseUrl;
  final int? requestId; // consult_request.id (선택 전달)

  const DResultDetailScreen({
    super.key,
    required this.userId,
    required this.originalImageUrl,
    required this.baseUrl,
    this.requestId,
  });

  @override
  State<DResultDetailScreen> createState() => _DResultDetailScreenState();
}

class _DResultDetailScreenState extends State<DResultDetailScreen> {
  // ─────────────────────────────
  // 토글 상태
  // ─────────────────────────────
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;

  // ─────────────────────────────
  // 이미지 바이트(토큰 인증 로딩)
  // ─────────────────────────────
  Uint8List? _originalBytes;
  Uint8List? _overlay1Bytes; // 질환
  Uint8List? _overlay2Bytes; // 치석/보철물
  Uint8List? _overlay3Bytes; // 치아번호

  // ─────────────────────────────
  // 인퍼런스/요약/팔레트
  // ─────────────────────────────
  String _m1Label = 'Unknown';
  double _m1Conf = 0.0;
  List<dynamic> _m1DetectedLabels = const []; // model1.detected_labels

  String _m2Label = 'Unknown';
  double _m2Conf = 0.0;
  List<String> _m2DetectedLabels = const [];  // model2.detected_labels

  String _m3ToothNumber = 'Unknown';
  double _m3Conf = 0.0;

  Map<String, dynamic>? _m1Palette; // model1.palette
  Map<String, dynamic>? _m2Palette; // model2.palette

  String? _inferenceResultId;

  // ─────────────────────────────
  // 상태/의사소견
  // ─────────────────────────────
  bool _isLoading = true;
  String? _error;

  bool _isReplied = false;
  String? _doctorCommentFromDb;

  final TextEditingController _doctorOpinionController = TextEditingController();
  bool _isSubmittingOpinion = false;

  // ─────────────────────────────
  // AI 소견(Gemini) - Markdown 렌더
  // ─────────────────────────────
  String? _aiOpinion;
  bool _isLoadingOpinion = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _doctorOpinionController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _fetchConsultStatusIfNeeded();
    await _fetchInferenceAndImages();
    if (mounted && _error == null) {
      await _fetchGeminiOpinion();
    }
  }

  Future<void> _fetchConsultStatusIfNeeded() async {
    try {
      final auth = context.read<AuthViewModel>();
      final token = await auth.getAccessToken();
      if (token == null) return;

      final cleanBase = widget.baseUrl.replaceAll('/api', '');
      final isAbsolute = widget.originalImageUrl.startsWith('http');
      final relativePath = isAbsolute
          ? widget.originalImageUrl.replaceFirst(cleanBase, '')
          : widget.originalImageUrl;

      final uri = Uri.parse(
        '${widget.baseUrl}/consult/status'
        '?user_id=${Uri.encodeComponent(widget.userId)}'
        '&image_path=${Uri.encodeComponent(relativePath)}',
      );
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final m = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final isRepliedStr = (m['is_replied'] ?? 'N').toString();
        final doctorCmt = m['doctor_comment'] as String?;
        setState(() {
          _isReplied = isRepliedStr == 'Y';
          _doctorCommentFromDb = doctorCmt;
          if (_isReplied && (doctorCmt ?? '').isNotEmpty) {
            _doctorOpinionController.text = doctorCmt!;
          }
        });
      }
    } catch (_) {
      // 상태 조회 실패는 치명적이지 않으므로 무시
    }
  }

  Future<void> _fetchInferenceAndImages() async {
    try {
      final auth = context.read<AuthViewModel>();
      final token = await auth.getAccessToken();
      if (token == null) {
        setState(() {
          _error = '토큰이 없습니다. 로그인 상태를 확인해주세요.';
          _isLoading = false;
        });
        return;
      }

      // API 파라미터용 상대경로 계산
      final cleanBase = widget.baseUrl.replaceAll('/api', '');
      final isAbsolute = widget.originalImageUrl.startsWith('http');
      final imagePathRelative = isAbsolute
          ? widget.originalImageUrl.replaceFirst(cleanBase, '')
          : widget.originalImageUrl;

      // 1) 인퍼런스 결과 조회
      final inferenceUri = Uri.parse(
        '${widget.baseUrl}/inference_results'
        '?role=D'
        '&user_id=${Uri.encodeComponent(widget.userId)}'
        '&image_path=${Uri.encodeComponent(imagePathRelative)}',
      );

      final infRes = await http.get(inferenceUri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (infRes.statusCode != 200) {
        setState(() {
          _error = '진단 결과 불러오기 실패: ${infRes.statusCode}. ${infRes.body}';
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(utf8.decode(infRes.bodyBytes)) as Map<String, dynamic>;

      // ── 모델 블록
      final Map<String, dynamic>? m1 = (data['model1_inference_result'] as Map?)?.cast<String, dynamic>();
      final Map<String, dynamic>? m2 = (data['model2_inference_result'] as Map?)?.cast<String, dynamic>();
      final Map<String, dynamic>? m3 = (data['model3_inference_result'] as Map?)?.cast<String, dynamic>();

      // 상대 경로(overlay) - 서버 키가 다를 수 있어 폴백 포함
      final String? m1Img = (data['model1_image_path'] ?? m1?['processed_image_path']) as String?;
      final String? m2Img = (data['model2_image_path'] ?? m2?['processed_image_path']) as String?;
      final String? m3Img = (data['model3_image_path'] ?? m3?['processed_image_path']) as String?;

      // 라벨/신뢰도
      setState(() {
        _inferenceResultId = data['_id']?.toString();

        _m1Label = m1?['label']?.toString() ?? 'Unknown';
        _m1Conf  = (m1?['confidence'] as num?)?.toDouble() ?? 0.0;
        _m1DetectedLabels = (m1?['detected_labels'] as List?) ?? const [];

        _m2Label = m2?['label']?.toString() ?? 'Unknown';
        _m2Conf  = (m2?['confidence'] as num?)?.toDouble() ?? 0.0;
        _m2DetectedLabels =
            ((m2?['detected_labels'] as List?) ?? const []).map((e) => e.toString().trim()).toList();

        _m3ToothNumber = m3?['tooth_number_fdi']?.toString() ?? 'Unknown';
        _m3Conf        = (m3?['confidence'] as num?)?.toDouble() ?? 0.0;

        _m1Palette = (m1?['palette'] as Map?)?.cast<String, dynamic>();
        _m2Palette = (m2?['palette'] as Map?)?.cast<String, dynamic>();
      });

      // 2) 이미지 바이트 로딩(토큰 인증)
      final originalFull = isAbsolute ? widget.originalImageUrl : '$cleanBase$imagePathRelative';
      final ov1Full = (m1Img != null && m1Img.isNotEmpty) ? '$cleanBase$m1Img' : null;
      final ov2Full = (m2Img != null && m2Img.isNotEmpty) ? '$cleanBase$m2Img' : null;
      final ov3Full = (m3Img != null && m3Img.isNotEmpty) ? '$cleanBase$m3Img' : null;

      final originalBytes = await _getBytesWithAuth(originalFull, token);
      final ov1Bytes = ov1Full != null ? await _getBytesWithAuth(ov1Full, token) : null;
      final ov2Bytes = ov2Full != null ? await _getBytesWithAuth(ov2Full, token) : null;
      final ov3Bytes = ov3Full != null ? await _getBytesWithAuth(ov3Full, token) : null;

      if (!mounted) return;
      setState(() {
        _originalBytes = originalBytes;
        _overlay1Bytes = ov1Bytes;
        _overlay2Bytes = ov2Bytes;
        _overlay3Bytes = ov3Bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _getBytesWithAuth(String url, String token) async {
    final res = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200) return res.bodyBytes;
    return null;
  }

  Future<void> _fetchGeminiOpinion() async {
    setState(() => _isLoadingOpinion = true);
    try {
      final auth = context.read<AuthViewModel>();
      final token = await auth.getAccessToken();
      if (token == null) {
        setState(() {
          _aiOpinion = 'AI 소견 요청 실패: 토큰이 없습니다.';
          _isLoadingOpinion = false;
        });
        return;
      }

      final invalidAll = (_m1Label == 'Unknown' && _m1Conf == 0.0) &&
          (_m2Label == 'Unknown' && _m2Conf == 0.0) &&
          (_m3ToothNumber == 'Unknown' && _m3Conf == 0.0);
      if (invalidAll) {
        setState(() {
          _aiOpinion = 'AI 소견 요청 실패: 진단 결과가 유효하지 않습니다.';
          _isLoadingOpinion = false;
        });
        return;
      }

      final cleanBase = widget.baseUrl.replaceAll('/api', '');
      final isAbsolute = widget.originalImageUrl.startsWith('http');
      final imageFullUrl = isAbsolute ? widget.originalImageUrl : '$cleanBase${widget.originalImageUrl}';

      final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini');
      final body = jsonEncode({
        'image_url': imageFullUrl,
        'model1Label': _m1Label,
        'model1Confidence': _m1Conf,
        'model2Label': _m2Label,
        'model2Confidence': _m2Conf,
        'model3ToothNumber': _m3ToothNumber,
        'model3Confidence': _m3Conf,
        'inference_result_id': _inferenceResultId,
      });

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body,
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        final m = json.decode(utf8.decode(res.bodyBytes));
        setState(() => _aiOpinion = m['message'] ?? 'AI 소견을 불러오지 못했습니다.');
      } else {
        setState(() => _aiOpinion = 'AI 소견 요청 실패: ${res.statusCode}. ${res.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiOpinion = 'AI 소견 요청 중 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOpinion = false);
    }
  }

Future<void> _submitDoctorOpinion() async {
    setState(() => _isSubmittingOpinion = true);

    final opinionText = _doctorOpinionController.text.trim();
    if (opinionText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('의견을 입력해주세요.')));
      setState(() => _isSubmittingOpinion = false);
      return;
    }

    try {
      final auth = context.read<AuthViewModel>();
      final token = await auth.getAccessToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        setState(() => _isSubmittingOpinion = false);
        return;
      }

      // requestId 확보
      int? reqId = widget.requestId;
      if (reqId == null) {
        final cleanBase = widget.baseUrl.replaceAll('/api', '');
        final isAbsolute = widget.originalImageUrl.startsWith('http');
        final relativePath = isAbsolute
            ? widget.originalImageUrl.replaceFirst(cleanBase, '')
            : widget.originalImageUrl;

        final statusUri = Uri.parse(
          '${widget.baseUrl}/consult/status'
          '?user_id=${Uri.encodeComponent(widget.userId)}'
          '&image_path=${Uri.encodeComponent(relativePath)}',
        );
        final statusRes = await http.get(statusUri, headers: {'Authorization': 'Bearer $token'});
        if (statusRes.statusCode == 200) {
          final m = json.decode(utf8.decode(statusRes.bodyBytes));
          final dynamic v = m['request_id'];
          reqId = v is int ? v : (v is String ? int.tryParse(v) : null);
        }
      }

      if (reqId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('요청 ID를 찾을 수 없습니다.')));
        setState(() => _isSubmittingOpinion = false);
        return;
      }

      final uri = Uri.parse('${widget.baseUrl}/consult/reply');
      final body = jsonEncode({'request_id': reqId, 'comment': opinionText});

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _isReplied = true;
          _doctorCommentFromDb = opinionText;
          _doctorOpinionController.text = opinionText;
        });

        // ✅ 컨텍스트 분리: 다이얼로그 닫기 vs 페이지 pop(true)
        final rootContext = context;
        showDialog(
          context: rootContext,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('제출 완료'),
            content: const Text('의사 의견이 저장되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();               // 다이얼로그만 닫기
                  if (mounted) GoRouter.of(rootContext).pop(true); // 상위 페이지로 true 반환
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${res.statusCode} ${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isSubmittingOpinion = false);
    }
  }


  // ─────────────────────────────
  // UI 위젯
  // ─────────────────────────────

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
      );

  Widget _buildStatusBadge() {
    final Color bg = _isReplied ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final String text = _isReplied ? '진단 응답 완료' : '진단 대기';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isReplied ? Icons.check_circle : Icons.pending_actions, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildToggleCard() => Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('마스크 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStyledToggle("충치/치주염/치은염", _showDisease, (val) => setState(() => _showDisease = val)),
            _buildStyledToggle("치석/보철물", _showHygiene, (val) => setState(() => _showHygiene = val)),
            _buildStyledToggle("치아번호", _showToothNumber, (val) => setState(() => _showToothNumber = val)),
          ],
        ),
      );

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_originalBytes != null)
                // 왜곡 방지: contain 권장
                Image.memory(_originalBytes!, fit: BoxFit.contain)
              else
                const Center(child: CircularProgressIndicator()),
              if (_showDisease && _overlay1Bytes != null)
                Image.memory(_overlay1Bytes!, fit: BoxFit.contain),
              if (_showHygiene && _overlay2Bytes != null)
                Image.memory(_overlay2Bytes!, fit: BoxFit.contain),
              if (_showToothNumber && _overlay3Bytes != null)
                Image.memory(_overlay3Bytes!, fit: BoxFit.contain),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // 팔레트/라벨 정리 및 요약 카드
  // ─────────────────────────────

  // 환자 화면과 동일한 폴백 팔레트
  static const Map<String, String> _kDiseaseHexFallback = {
    "충치 초기": "#FFFF00",
    "충치 중기": "#FFA500",
    "충치 말기": "#FF0000",
    "잇몸 염증 초기": "#90CAF9",
    "잇몸 염증 중기": "#1E88E5",
    "잇몸 염증 말기": "#0D47A1",
    "치주질환 초기": "#B2FF9E",
    "치주질환 중기": "#66BB6A",
    "치주질환 말기": "#1B5E20",
  };

  static const Map<String, String> _kHygieneHexFallback = {
    "교정장치 (ortho)": "#1E1E1E",
    "골드 (gcr)": "#FFD700",
    "메탈크라운 (mcr)": "#A9A9A9",
    "세라믹 (cecr)": "#F5F5F5",
    "아말감 (am)": "#C0C0C0",
    "지르코니아 (zircr)": "#DC143C",
    "치석 단계1 (tar1)": "#FFFF99",
    "치석 단계2 (tar2)": "#FFCC00",
    "치석 단계3 (tar3)": "#CC9900",
  };

  Color _hexToColor(String hex) {
    var v = hex.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.parse(v, radix: 16));
  }

  Color? _colorFromServerPalette(Map<String, dynamic>? palette, String label) {
    if (palette == null) return null;
    final value = palette[label];
    if (value is String && value.startsWith('#')) {
      return _hexToColor(value);
    }
    return null;
  }

  List<String> _normalizeDiseaseLabels(List<dynamic> raw) {
    return raw
        .map((e) {
          if (e is String) return e.trim();
          if (e is Map) {
            final v = e['class_name'] ?? e['label'];
            return v == null ? '' : v.toString().trim();
          }
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  Color _colorForDiseaseLabel(String label) {
    final fromServer = _colorFromServerPalette(_m1Palette, label);
    if (fromServer != null) return fromServer;
    final hex = _kDiseaseHexFallback[label] ?? "#999999";
    return _hexToColor(hex);
  }

  Color _colorForHygieneLabel(String label) {
    final fromServer = _colorFromServerPalette(_m2Palette, label);
    if (fromServer != null) return fromServer;
    final hex = _kHygieneHexFallback[label] ?? "#999999";
    return _hexToColor(hex);
  }

  Widget _labelRow(String label, Color color, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: style)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final textTheme = Theme.of(context).textTheme;
    final bold = textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    // 서버가 label 리스트를 안줄 경우, 단일 label을 리스트로 대체
    final List<String> diseaseList = _showDisease
        ? (_m1DetectedLabels.isNotEmpty
            ? _normalizeDiseaseLabels(_m1DetectedLabels)
            : (_m1Label != 'Unknown' ? <String>[_m1Label] : <String>[]))
        : <String>[];

    final List<String> hygieneList = _showHygiene
        ? (_m2DetectedLabels.isNotEmpty
            ? _m2DetectedLabels.toSet().toList()
            : (_m2Label != 'Unknown' ? <String>[_m2Label] : <String>[]))
        : <String>[];

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('진단 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (_showDisease) ...[
            const Text('충치/잇몸 염증/치주질환', style: TextStyle(fontWeight: FontWeight.w600)),
            if (diseaseList.isNotEmpty)
              ...diseaseList.map((label) => _labelRow(label, _colorForDiseaseLabel(label), bold))
            else
              const Text('감지되지 않음'),
            const SizedBox(height: 8),
          ],

          if (_showHygiene) ...[
            const Text('치석/보철물', style: TextStyle(fontWeight: FontWeight.w600)),
            if (hygieneList.isNotEmpty)
              ...hygieneList.map((label) => _labelRow(label, _colorForHygieneLabel(label), bold))
            else
              const Text('감지되지 않음'),
            const SizedBox(height: 8),
          ],

          if (_showToothNumber && _m3ToothNumber != 'Unknown') ...[
            const Text('치아번호', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('FDI 번호: $_m3ToothNumber', style: bold),
            const SizedBox(height: 8),
          ],

          if (!_showDisease && !_showHygiene && _m3ToothNumber == 'Unknown')
            const Text('감지된 내용이 없습니다.'),
        ],
      ),
    );
  }

  Widget _buildAiOpinionCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI 소견', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_isLoadingOpinion)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingOpinion)
            const Text('AI 소견을 불러오는 중입니다...', style: TextStyle(fontSize: 16, height: 1.5))
          else
            MarkdownBody(
              data: _aiOpinion ?? 'AI 소견을 불러오지 못했습니다.',
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

  Widget _buildDoctorOpinionCard() {
    String hint = '환자에게 전달할 진단 결과 및 조언을 작성하세요.';
    if (_isReplied && _doctorOpinionController.text.isNotEmpty) {
      hint = '';
    } else if (_isReplied) {
      hint = '작성 완료된 의사 소견입니다.';
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('의사 의견 작성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _doctorOpinionController,
            maxLines: 5,
            enabled: !_isReplied,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (_isSubmittingOpinion || _isReplied) ? null : _submitDoctorOpinion,
            icon: _isSubmittingOpinion
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.white),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _isSubmittingOpinion ? '전송 중...' : (_isReplied ? '작성 완료됨' : '보내기'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3869A8),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _bootstrap,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: _buildStatusBadge()),
          const SizedBox(height: 12),
          _buildToggleCard(),
          const SizedBox(height: 16),
          _buildImageCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildAiOpinionCard(),
          const SizedBox(height: 16),
          _buildDoctorOpinionCard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color outerBackground = Color(0xFFE7F0FF);
    const Color appbarColor = Color(0xFF3869A8);

    return Scaffold(
      backgroundColor: outerBackground,
      appBar: AppBar(
        backgroundColor: appbarColor,
        title: const Text('진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildBodyContent(),
                ),
              )
            : _buildBodyContent(),
      ),
    );
  }
}
