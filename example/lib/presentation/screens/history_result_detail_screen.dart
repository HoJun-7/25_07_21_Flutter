import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '/presentation/viewmodel/auth_viewmodel.dart';

class HistoryResultDetailScreen extends StatefulWidget {
  final String originalImageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String userId;
  final String inferenceResultId;
  final String baseUrl;
  final String isRequested;
  final String isReplied;
  final List<dynamic> matchedResults; // 외부에서 오면 우선 사용, 없으면 내부에서 계산

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
    required this.matchedResults,
  });

  @override
  State<HistoryResultDetailScreen> createState() => _HistoryResultDetailScreenState();
}

class _HistoryResultDetailScreenState extends State<HistoryResultDetailScreen> {
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;
  bool _isLoadingGemini = true;
  String? _geminiOpinion;

  late bool _isRequested;
  late bool _isReplied;

  Uint8List? originalImageBytes;
  Uint8List? overlay1Bytes;
  Uint8List? overlay2Bytes;
  Uint8List? overlay3Bytes;

  // 최종적으로 사용할 matchedResults (치아번호 포함)
  List<Map<String, dynamic>> _effectiveMatchedResults = [];

  final Map<String, Color> diseaseColorMap = {
    '충치 초기': const Color.fromARGB(255, 255, 255, 0),
    '충치 중기': const Color.fromARGB(255, 255, 165, 0),
    '충치 말기': const Color.fromARGB(255, 255, 0, 0),
    '잇몸 염증 초기': const Color.fromARGB(255, 255, 0, 255),
    '잇몸 염증 중기': const Color.fromARGB(255, 165, 0, 255),
    '잇몸 염증 말기': const Color.fromARGB(255, 0, 0, 255),
    '치주질환 초기': const Color.fromARGB(255, 0, 255, 255),
    '치주질환 중기': const Color.fromARGB(255, 0, 255, 165),
    '치주질환 말기': const Color.fromARGB(255, 0, 255, 0),
  };

  final Map<String, Color> hygieneColorMap = {
    "교정장치": const Color.fromARGB(255, 138, 43, 226),
    "금니 (골드 크라운)": const Color.fromARGB(255, 192, 192, 192),
    "은니 (메탈 크라운)": const Color.fromARGB(255, 255, 215, 0),
    "도자기소재 치아 덮개(세라믹 크라운)": const Color.fromARGB(255, 0, 0, 0),
    "아말감 충전재": const Color.fromARGB(255, 0, 0, 255),
    "도자기소재 치아 덮개(지르코니아 크라운)": const Color.fromARGB(255, 0, 255, 0),
    "치석 1 단계": const Color.fromARGB(255, 255, 255, 0),
    "치석 2 단계": const Color.fromARGB(255, 255, 165, 0),
    "치석 3 단계": const Color.fromARGB(255, 255, 0, 0),
  };

  String _normalizeHygiene(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('골드') || s.contains('gcr')) return '금니 (골드 크라운)';
    if (s.contains('메탈') || s.contains('mcr')) return '은니 (메탈 크라운)';
    if (s.contains('세라믹') || s.contains('ccr')) return '도자기소재 치아 덮개(세라믹 크라운)';
    if (s.contains('아말감')) return '아말감 충전재';
    if (s.contains('지르코니아')) return '도자기소재 치아 덮개(지르코니아 크라운)';
    if (s.contains('치석') && s.contains('1')) return '치석 1 단계';
    if (s.contains('치석') && s.contains('2')) return '치석 2 단계';
    if (s.contains('치석') && s.contains('3')) return '치석 3 단계';
    if (s.contains('교정')) return '교정장치';
    return raw.trim();
  }

  @override
  void initState() {
    super.initState();
    _isRequested = widget.isRequested == 'Y';
    _isReplied = widget.isReplied == 'Y';

    _loadImages();
    _prepareMatchedResults();   // ← 치아번호 매칭 사전준비
    _getGeminiOpinion();        // ← 준비된 결과로 서버 호출
  }

  // -------------------- 이미지 로딩 --------------------
  Future<void> _loadImages() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) return;

    try {
      final original = await _loadImageWithAuth(widget.originalImageUrl, token);
      final ov1 = await _loadImageWithAuth(widget.processedImageUrls[1], token);
      final ov2 = await _loadImageWithAuth(widget.processedImageUrls[2], token);
      final ov3 = await _loadImageWithAuth(widget.processedImageUrls[3], token);

      setState(() {
        originalImageBytes = original;
        overlay1Bytes = ov1;
        overlay2Bytes = ov2;
        overlay3Bytes = ov3;
      });
    } catch (_) {}
  }

  Future<Uint8List?> _loadImageWithAuth(String? url, String token) async {
    if (url == null) return null;
    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) return response.bodyBytes;
    return null;
  }

  // -------------------- 핵심: 치아번호 매칭 --------------------
  void _prepareMatchedResults() {
    final provided = widget.matchedResults.whereType<Map<String, dynamic>>().toList();
    final hasTooth = provided.any((e) => e['tooth_number'] != null);
    if (hasTooth && provided.isNotEmpty) {
      _effectiveMatchedResults = provided;
      return;
    }
    _effectiveMatchedResults = _computeMatchedFromModelInfos();
  }

  List<Map<String, dynamic>> _computeMatchedFromModelInfos() {
    final results = <Map<String, dynamic>>[];

    final m1 = widget.modelInfos[1]; // disease
    final m2 = widget.modelInfos[2]; // hygiene
    final m3 = widget.modelInfos[3]; // tooth numbers

    final toothInfos = (m3?['predicted_tooth_info'] as List?)?.whereType<Map<String, dynamic>>() ?? const [];
    final toothBoxes = <Map<String, dynamic>>[];
    for (final t in toothInfos) {
      final numStr = (t['tooth_number_fdi'] ?? t['tooth_number'] ?? t['tooth'])?.toString();
      final bbox = _toBbox(t['bbox']);
      if (numStr != null && bbox != null) {
        toothBoxes.add({'num': numStr, 'bbox': bbox});
      }
    }

    void assign(String category, List? dets) {
      final list = dets?.whereType<Map<String, dynamic>>() ?? const Iterable<Map<String, dynamic>>.empty();
      for (final d in list) {
        final label = d['label'];
        final conf = (d['confidence'] ?? d['score'] ?? 0.0) * 1.0;
        final db = _toBbox(d['bbox']);
        if (label == null || db == null) continue;

        double best = 0.0;
        String? bestTooth;

        for (final t in toothBoxes) {
          final tb = t['bbox'] as List<double>;
          final ratio = _intersectionOverDet(db, tb);
          if (ratio > best) {
            best = ratio;
            bestTooth = t['num'] as String;
          }
        }

        // overlap이 5% 이상이면 매칭
        if (bestTooth != null && best > 0.05) {
          results.add({
            'category': category,
            'tooth_number': bestTooth,
            'label': label,
            'confidence': conf,
          });
        }
      }
    }

    assign('disease', m1?['detections'] as List?);
    assign('hygiene', m2?['detections'] as List?);
    return results;
  }

  List<double>? _toBbox(dynamic raw) {
    if (raw is List && raw.length == 4) {
      final vals = raw.map((e) => (e as num).toDouble()).toList();
      return [vals[0], vals[1], vals[2], vals[3]];
    }
    return null;
  }

  // detection bbox 기준의 겹침 비율(∩/detArea)
  double _intersectionOverDet(List<double> a, List<double> b) {
    final x1 = math.max(a[0], b[0]);
    final y1 = math.max(a[1], b[1]);
    final x2 = math.min(a[2], b[2]);
    final y2 = math.min(a[3], b[3]);

    final iw = math.max(0.0, x2 - x1);
    final ih = math.max(0.0, y2 - y1);
    final inter = iw * ih;

    final detArea = (a[2] - a[0]).abs() * (a[3] - a[1]).abs();
    if (detArea <= 0) return 0.0;
    return inter / detArea;
  }

  // -------------------- 상담 신청/취소/3D --------------------
  Future<void> _applyConsultRequest() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final now = DateTime.now();
    String _twoDigits(int n) => n.toString().padLeft(2, '0');
    final requestDatetime =
        "${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}";

    final relativePath = widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

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

      if (response.statusCode == 201) {
        setState(() => _isRequested = true);
        // ignore: use_build_context_synchronously
        context.push('/consult_success', extra: {'type': 'apply'});
      } else {
        final msg = jsonDecode(response.body)['error'] ?? '신청에 실패했습니다.';
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('신청 실패'),
            content: Text(msg),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 문제가 발생했습니다.')),
      );
    }
  }

  Future<void> _cancelConsultRequest() async {
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

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
        setState(() => _isRequested = false);
        // ignore: use_build_context_synchronously
        context.push('/consult_success', extra: {'type': 'cancel'});
      } else {
        final msg = jsonDecode(response.body)['error'] ?? '신청 취소 실패';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $msg')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신 중 문제가 발생했습니다.')),
      );
    }
  }

  void _open3DViewer() {
    context.push('/dental_viewer', extra: {'glbUrl': 'assets/web/model/open_mouth.glb'});
  }

  // -------------------- Gemini 의견 --------------------
  Future<void> _getGeminiOpinion() async {
    setState(() => _isLoadingGemini = true);
    final authViewModel = context.read<AuthViewModel>();
    final token = await authViewModel.getAccessToken();
    if (token == null) {
      setState(() => _isLoadingGemini = false);
      return;
    }

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
          'matchedResults': _effectiveMatchedResults, // 치아번호 포함 결과 전달
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

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // -------------------- UI --------------------
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
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildMainBody(currentUser),
                ),
              )
            : _buildMainBody(currentUser),
      ),
    );
  }

  Widget _buildMainBody(dynamic currentUser) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToggleCard(const Color(0xFFEAEAEA)),
          const SizedBox(height: 16),
          _buildImageCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(textTheme: textTheme),
          const SizedBox(height: 16),
          _buildGeminiOpinionCard(),
          const SizedBox(height: 24),
          if (currentUser?.role == 'P') ...[
            _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
            const SizedBox(height: 12),
            _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
            const SizedBox(height: 12),
            if (!_isRequested)
              _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', _applyConsultRequest)
            else if (_isRequested && !_isReplied)
              _buildActionButton(Icons.medical_services, 'AI 예측 기반 진단 신청 취소', _cancelConsultRequest),
            const SizedBox(height: 12),
            _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
          ]
        ],
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
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isLoadingGemini ? 'AI 소견을 불러오는 중입니다...' : _geminiOpinion ?? 'AI 소견을 불러오지 못했습니다.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
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
                Image.memory(overlay1Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.9)),
              if (_showHygiene && overlay2Bytes != null)
                Image.memory(overlay2Bytes!, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.9)),
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
            const Text('인공지능 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStyledToggle('질병', _showDisease, (val) => setState(() => _showDisease = val), toggleBg),
            _buildStyledToggle('위생', _showHygiene, (val) => setState(() => _showHygiene = val), toggleBg),
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

  // 치아별 상세 분석 + 폴백(집계)
  Widget _buildSummaryCard({required TextTheme textTheme}) {
    // 1) 치아별 그룹핑
    final Map<String, List<Map<String, dynamic>>> diseaseResults = {};
    final Map<String, List<Map<String, dynamic>>> hygieneResults = {};

    for (final r in _effectiveMatchedResults) {
      final tooth = r['tooth_number']?.toString();
      final cat = r['category']?.toString();
      if (tooth == null || cat == null) continue;

      if (cat == 'disease' && _showDisease) {
        (diseaseResults[tooth] ??= []).add(r);
      } else if (cat == 'hygiene' && _showHygiene) {
        (hygieneResults[tooth] ??= []).add(r);
      }
    }

    final hasToothWise = diseaseResults.isNotEmpty || hygieneResults.isNotEmpty;

    // 2) 치아별 결과가 없으면 업로드 화면처럼 '집계 카드'로 폴백
    if (!hasToothWise) {
      return _buildAggregateFallbackCard(textTheme: textTheme);
    }

    // 3) 치아별 상세 카드
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
          const Text('치아별 상세 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          if (diseaseResults.isNotEmpty && _showDisease) ...[
            Text('질병(Disease):', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...diseaseResults.keys.map((toothNumber) {
              final list = diseaseResults[toothNumber]!;
              final text = list.map((r) {
                final label = r['label'];
                final conf = ((r['confidence'] ?? 0.0) * 100).toStringAsFixed(2);
                return '$label (확신도: $conf%)';
              }).join(', ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('$toothNumber번 치아: $text', style: textTheme.bodyMedium),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          if (hygieneResults.isNotEmpty && _showHygiene) ...[
            Text('치석/크라운/충전재(Hygiene):', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...hygieneResults.keys.map((toothNumber) {
              final list = hygieneResults[toothNumber]!;
              final text = list.map((r) {
                final label = r['label'];
                final conf = ((r['confidence'] ?? 0.0) * 100).toStringAsFixed(2);
                return '$label (확신도: $conf%)';
              }).join(', ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('$toothNumber번 치아: $text', style: textTheme.bodyMedium),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // 업로드 화면처럼 '집계'로만 보여주는 폴백 카드
  Widget _buildAggregateFallbackCard({required TextTheme textTheme}) {
    final m1 = widget.modelInfos[1];
    final m2 = widget.modelInfos[2];

    // 질병 집계
    final List<String> diseaseLabels =
        (m1?['detected_labels'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => (e['label'] ?? '').toString())
            .toList();

    final Map<String, int> cnt = {};
    final Map<String, int> firstSeen = {};
    for (var i = 0; i < diseaseLabels.length; i++) {
      final lbl = diseaseLabels[i];
      if (lbl.isEmpty) continue;
      cnt[lbl] = (cnt[lbl] ?? 0) + 1;
      firstSeen.putIfAbsent(lbl, () => i);
    }
    final diseaseEntries = cnt.entries.toList()
      ..sort((a, b) => firstSeen[a.key]!.compareTo(firstSeen[b.key]!));

    // 위생 집계(중복 제거)
    final List<String> hygieneLabels =
        (m2?['detected_labels'] as List? ?? const [])
            .map((e) => e.toString().trim())
            .map(_normalizeHygiene)
            .where((l) => hygieneColorMap.containsKey(l))
            .toSet()
            .toList();

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
          const Text('인공지능 분석 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_showDisease && diseaseEntries.isNotEmpty) ...[
            const Text('질병', style: TextStyle(fontWeight: FontWeight.w600)),
            ...diseaseEntries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(
                    color: diseaseColorMap[e.key] ?? Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('${e.key} ${e.value}건', style: textTheme.bodyMedium),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],

          if (_showHygiene) ...[
            const Text('치석/크라운/충전재', style: TextStyle(fontWeight: FontWeight.w600)),
            if (hygieneLabels.isNotEmpty)
              ...hygieneLabels.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: hygieneColorMap[l] ?? Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(l, style: textTheme.bodyMedium),
                  ],
                ),
              ))
            else
              Text('감지되지 않음', style: textTheme.bodyMedium),
          ],
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
        backgroundColor: const Color(0xFF3869A8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
