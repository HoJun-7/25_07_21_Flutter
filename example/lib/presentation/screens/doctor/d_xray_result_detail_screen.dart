// example/lib/presentation/screens/doctor/d_xray_result_detail_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart'; // ← context.pop(true) 사용

import '/presentation/viewmodel/auth_viewmodel.dart';

class DXrayResultDetailScreen extends StatefulWidget {
  final String userId;
  /// 상대 경로(ex: /images/original/....png) 또는 절대 URL도 허용
  final String originalImageUrl;
  final String baseUrl;
  final int? requestId; // consult_request.id (선택)

  const DXrayResultDetailScreen({
    super.key,
    required this.userId,
    required this.originalImageUrl,
    required this.baseUrl,
    this.requestId,
  });

  @override
  State<DXrayResultDetailScreen> createState() => _DXrayResultDetailScreenState();
}

class _DXrayResultDetailScreenState extends State<DXrayResultDetailScreen> {
  // ─────────────────────────────
  // 토글 (X-ray는 model1/model2 두 겹)
  // ─────────────────────────────
  bool _showModel1 = true; // 구강 상태(세그/검출) 오버레이
  bool _showModel2 = true; // 임플란트/제조사 등 두 번째 오버레이

  // ─────────────────────────────
  // 이미지 (토큰 인증으로 바이트 로딩)
  // ─────────────────────────────
  Uint8List? _originalBytes;
  Uint8List? _overlay1Bytes;
  Uint8List? _overlay2Bytes;

  // ─────────────────────────────
  // 인퍼런스 결과 (X-ray 전용)
  // ─────────────────────────────
  String? _inferenceResultId;

  // model1 메타 & 예측
  String _m1UsedModel = 'N/A';
  double _m1Confidence = 0.0;
  List<dynamic> _m1Predictions = const []; // [{class_name, bbox/points, score...}, ...]

  // 제조사 분류 API 결과(보조)
  List<Map<String, dynamic>> _implantManufacturerResults = const [];

  // ─────────────────────────────
  // 의사 소견/상태
  // ─────────────────────────────
  bool _isLoading = true;
  String? _error;

  bool _isReplied = false;
  String? _doctorCommentFromDb;

  final TextEditingController _doctorOpinionController = TextEditingController();
  bool _isSubmittingOpinion = false;

  // ─────────────────────────────
  // AI 소견 (Gemini X-ray) - Markdown 렌더
  // ─────────────────────────────
  String? _aiOpinion;
  bool _isLoadingOpinion = false;

  String get _cleanBase => widget.baseUrl.replaceAll('/api', '');
  bool get _isAbsolute => widget.originalImageUrl.startsWith('http');
  String get _relativeImagePath =>
      _isAbsolute ? widget.originalImageUrl.replaceFirst(_cleanBase, '') : widget.originalImageUrl;
  String get _originalFullUrl => _isAbsolute ? widget.originalImageUrl : '$_cleanBase$_relativeImagePath';

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
    await _fetchConsultStatus();
    await _fetchInferenceAndImages();
    await _fetchImplantManufacturer();
    if (mounted && _error == null) {
      await _fetchGeminiOpinion();
    }
  }

  // ─────────────────────────────
  // 상태/의사 코멘트
  // ─────────────────────────────
  Future<void> _fetchConsultStatus() async {
    try {
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) return;

      final uri = Uri.parse(
        '${widget.baseUrl}/consult/status'
        '?user_id=${Uri.encodeComponent(widget.userId)}'
        '&image_path=${Uri.encodeComponent(_relativeImagePath)}',
      );
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final m = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final replied = (m['is_replied'] ?? 'N').toString() == 'Y';
        final cmt = m['doctor_comment'] as String?;
        setState(() {
          _isReplied = replied;
          _doctorCommentFromDb = cmt;
          if (_isReplied && (cmt ?? '').isNotEmpty) {
            _doctorOpinionController.text = cmt!;
          }
        });
      }
    } catch (_) {/* 상태는 실패해도 치명적 아님 */}
  }

  // ─────────────────────────────
  // 인퍼런스/이미지 로드
  // ─────────────────────────────
  Future<void> _fetchInferenceAndImages() async {
    try {
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) {
        setState(() {
          _error = '토큰이 없습니다. 로그인 상태를 확인해주세요.';
          _isLoading = false;
        });
        return;
      }

      // 1) 인퍼런스 결과 (D용 — 서버가 X-ray도 동일 엔드포인트로 제공한다는 가정)
      final uri = Uri.parse(
        '${widget.baseUrl}/inference_results'
        '?role=D'
        '&user_id=${Uri.encodeComponent(widget.userId)}'
        '&image_path=${Uri.encodeComponent(_relativeImagePath)}',
      );

      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode != 200) {
        setState(() {
          _error = '진단 결과 불러오기 실패: ${res.statusCode}. ${res.body}';
          _isLoading = false;
        });
        return;
      }

      final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      _inferenceResultId = data['_id']?.toString();

      // 오버레이 상대 경로 (키가 다를 때 대비하여 processed_image_path도 폴백)
      final Map<String, dynamic>? m1 =
          (data['model1_inference_result'] as Map?)?.cast<String, dynamic>();
      final Map<String, dynamic>? m2 =
          (data['model2_inference_result'] as Map?)?.cast<String, dynamic>();

      final String? m1Img = (data['model1_image_path'] ?? m1?['processed_image_path']) as String?;
      final String? m2Img = (data['model2_image_path'] ?? m2?['processed_image_path']) as String?;

      setState(() {
        _m1UsedModel   = m1?['used_model']?.toString() ?? (m1?['label']?.toString() ?? 'N/A');
        _m1Confidence  = (m1?['confidence'] as num?)?.toDouble() ?? 0.0;
        _m1Predictions = (m1?['predictions'] as List?) ?? const [];
      });

      // 2) 토큰 인증으로 이미지 바이트 로딩
      final originalBytes = await _getBytesWithAuth(_originalFullUrl, token);
      final ov1Full = (m1Img != null && m1Img.isNotEmpty) ? '$_cleanBase$m1Img' : null;
      final ov2Full = (m2Img != null && m2Img.isNotEmpty) ? '$_cleanBase$m2Img' : null;

      final ov1Bytes = ov1Full != null ? await _getBytesWithAuth(ov1Full, token) : null;
      final ov2Bytes = ov2Full != null ? await _getBytesWithAuth(ov2Full, token) : null;

      if (!mounted) return;
      setState(() {
        _originalBytes = originalBytes;
        _overlay1Bytes = ov1Bytes;
        _overlay2Bytes = ov2Bytes;
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

  // ─────────────────────────────
  // 임플란트 제조사 분류 (보조 정보)
  // ─────────────────────────────
  Future<void> _fetchImplantManufacturer() async {
    try {
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) return;

      final uri = Uri.parse('${widget.baseUrl}/xray_implant_classify');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'image_path': _relativeImagePath}),
      );

      if (res.statusCode == 200) {
        final m = json.decode(utf8.decode(res.bodyBytes));
        final results = List<Map<String, dynamic>>.from(m['results'] ?? const []);
        setState(() => _implantManufacturerResults = results);
      }
    } catch (_) {/* 실패시 무시 */}
  }

  // ─────────────────────────────
  // AI 소견 (X-ray 전용 엔드포인트)
  // ─────────────────────────────
  Future<void> _fetchGeminiOpinion() async {
    setState(() => _isLoadingOpinion = true);
    try {
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) {
        setState(() {
          _aiOpinion = 'AI 소견 요청 실패: 토큰이 없습니다.';
          _isLoadingOpinion = false;
        });
        return;
      }

      final predictionCount = _m1Predictions.length;
      if (predictionCount == 0 && _m1UsedModel == 'N/A') {
        setState(() {
          _aiOpinion = 'AI 소견 요청 실패: 유효한 예측이 없습니다.';
          _isLoadingOpinion = false;
        });
        return;
      }

      final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini_xray');
      final body = jsonEncode({
        'image_url': _originalFullUrl,
        'inference_result_id': _inferenceResultId,
        'model1Label': _m1UsedModel,
        'model1Confidence': _m1Confidence,
        'predictionCount': predictionCount,
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

  // ─────────────────────────────
  // 의사 소견 제출
  // ─────────────────────────────
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
      final token = await context.read<AuthViewModel>().getAccessToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        setState(() => _isSubmittingOpinion = false);
        return;
      }

      // requestId 확보(없으면 상태 API에서 재조회)
      int? reqId = widget.requestId;
      if (reqId == null) {
        final statusUri = Uri.parse(
          '${widget.baseUrl}/consult/status'
          '?user_id=${Uri.encodeComponent(widget.userId)}'
          '&image_path=${Uri.encodeComponent(_relativeImagePath)}',
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

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('제출 완료'),
            content: const Text('의사 의견이 저장되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  context.pop(true);      // 목록 새로고침 신호
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
  // UI
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
            const Text('인공지능 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStyledToggle("구강 상태 분석", _showModel1, (v) => setState(() => _showModel1 = v)),
            _buildStyledToggle("임플란트/제조사", _showModel2, (v) => setState(() => _showModel2 = v)),
          ],
        ),
      );

  Widget _buildStyledToggle(String label, bool value, ValueChanged<bool> onChanged) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: const TextStyle(fontSize: 15)), Switch(value: value, onChanged: onChanged)],
        ),
      );

  Widget _buildImageCard() => Container(
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
                  // X-ray는 비율 유지가 중요 → contain
                  Image.memory(_originalBytes!, fit: BoxFit.contain)
                else
                  const Center(child: CircularProgressIndicator()),
                if (_showModel1 && _overlay1Bytes != null)
                  Image.memory(_overlay1Bytes!, fit: BoxFit.contain),
                if (_showModel2 && _overlay2Bytes != null)
                  Image.memory(_overlay2Bytes!, fit: BoxFit.contain),
              ],
            ),
          ),
        ),
      );

  Widget _buildXraySummaryCard() {
    // class_name별 카운트(정상치아 제외)
    final Map<String, int> classCounts = {};
    for (final p in _m1Predictions) {
      final className = (p is Map ? p['class_name'] : null) ?? 'Unknown';
      if (className == '정상치아') continue;
      classCounts[className] = (classCounts[className] ?? 0) + 1;
    }

    // 간단 컬러 맵 (없으면 회색)
    final Map<String, Color> colorMap = {
      '치아 우식증': Colors.red,
      '임플란트': Colors.blue,
      '보철물': Colors.yellow,
      '근관치료': Colors.green,
      '상실치아': Colors.black,
    };

    final bold = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    return Container(
      decoration: _cardDecoration(),
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
            })
          else
            Text('감지된 객체가 없습니다.', style: bold),

          if (_implantManufacturerResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('[임플란트 제조사 분류 결과]', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._implantManufacturerResults.map((r) {
              final name = r['predicted_manufacturer_name'] ?? '알 수 없음';
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('→ $name: 1개', style: bold),
              );
            }),
          ],
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

  Widget _buildBody() {
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
          _buildXraySummaryCard(),
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
    const outerBg = Color(0xFFE7F0FF);
    const appbarColor = Color(0xFF3869A8);

    return Scaffold(
      backgroundColor: outerBg,
      appBar: AppBar(
        backgroundColor: appbarColor,
        title: const Text('X-ray 진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: kIsWeb
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildBody(),
                ),
              )
            : _buildBody(),
      ),
    );
  }
}
