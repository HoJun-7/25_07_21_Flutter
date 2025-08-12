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
    bool _isLoadingGemini = false;
    List<Map<String, dynamic>> _implantResults = []; // ✅ 추가

    String get _relativePath => widget.originalImageUrl.replaceFirst(widget.baseUrl.replaceAll('/api', ''), '');

    @override
    void initState() {
      super.initState();
      _loadImages();
      _loadImplantManufacturerResults(); // ✅ 추가
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

    // ✅ 3D 뷰어 열기
    void _open3DViewer() {
      context.push('/dental_viewer', extra: {
        'glbUrl': 'assets/web/model/open_mouth.glb', // 로컬 에셋 경로
      });
    }
  
    Future<Uint8List?> _loadImage(String url, String token) async {
      final res = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      return res.statusCode == 200 ? res.bodyBytes : null;
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToggleCard(),
              const SizedBox(height: 16),
              _buildXrayImage(),
              const SizedBox(height: 16),
              _buildXraySummaryCard(modelName, predictionCount),
              const SizedBox(height: 24),
              if (currentUser?.role == 'P') ...[
                _buildActionButton(Icons.download, '진단 결과 이미지 저장', () {}),
                const SizedBox(height: 12),
                _buildActionButton(Icons.image, '원본 이미지 저장', () {}),
                const SizedBox(height: 12),
                _buildActionButton(Icons.medical_services, 'AI 예측 기반 비대면 진단 신청', () => _submitConsultRequest(currentUser!)),
                const SizedBox(height: 12),
                _buildActionButton(Icons.chat, 'AI 소견 들어보기', _isLoadingGemini ? null : () async {
                  setState(() => _isLoadingGemini = true);
                  final token = await context.read<AuthViewModel>().getAccessToken();
                  final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini_xray');

                  final response = await http.post(
                    uri,
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $token",
                    },
                    body: jsonEncode({
                      "image_url": widget.originalImageUrl,
                      "inference_result_id": widget.inferenceResultId,
                      "model1Label": modelName,
                      "model1Confidence": widget.model1Result['confidence'] ?? 0.0,
                      "predictionCount": predictionCount,
                    }),
                  );

                  setState(() => _isLoadingGemini = false);

                  if (response.statusCode == 200) {
                    final result = jsonDecode(response.body);
                    final message = result['message'] ?? 'AI 응답이 없습니다.';
                    context.push('/multimodal_result', extra: {"responseText": message});
                  } else {
                    _showErrorDialog("AI 소견 요청에 실패했습니다.");
                  }
                }),
                const SizedBox(height: 12),
                _buildActionButton(Icons.view_in_ar, '3D로 보기', _open3DViewer),
              ]
            ],
          ),
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
              const Text('마스크 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildStyledToggle("YOLO 탐지 결과 (model1)", _showModel1, (val) => setState(() => _showModel1 = val)),
              _buildStyledToggle("추가 오버레이 (model2)", _showModel2, (val) => setState(() => _showModel2 = val)),
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

      String summaryText = '감지된 객체가 없습니다.';
      if (predictions != null && predictions.isNotEmpty) {
        final Map<String, int> classCounts = {};
        for (final pred in predictions) {
          final className = pred['class_name'] ?? 'Unknown';
          if (className == '정상치아') continue; // 제외
          classCounts[className] = (classCounts[className] ?? 0) + 1;
        }

        if (classCounts.isNotEmpty) {
          final lines = classCounts.entries
              .map((e) => '${e.key} ${e.value}개 감지')
              .toList();
          summaryText = lines.join('\n');
        }
      }

      if (_implantResults.isNotEmpty) {
        summaryText += "\n\n[임플란트 제조사 분류 결과]";
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
            backgroundColor: const Color(0xFF3869A8),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
  }