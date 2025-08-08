// d_result_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

class DResultDetailScreen extends StatefulWidget {
  final String userId; // 환자 register_id 또는 user_id (백엔드 스펙에 맞춰 전달 중)
  final String originalImageUrl; // '/images/original/....png' 같은 상대 경로
  final String baseUrl; // 예) 'http://192.168.0.135:5000/api'
  final int requestId; // ✅ consult/list에서 넘어온 request_id (정수)
  final String doctorRegisterId; // ✅ 의사 register_id (문자열)

  const DResultDetailScreen({
    super.key,
    required this.userId,
    required this.originalImageUrl,
    required this.baseUrl,
    required this.requestId,
    required this.doctorRegisterId,
  });

  @override
  State<DResultDetailScreen> createState() => _DResultDetailScreenState();
}

class _DResultDetailScreenState extends State<DResultDetailScreen> {
  bool _showDisease = true;
  bool _showHygiene = true;
  bool _showToothNumber = true;

  String? overlay1Url;
  String? overlay2Url;
  String? overlay3Url;

  String modelName = '';
  String className = ''; // model1Label
  double confidence = 0.0; // model1Confidence
  String model2Label = '';
  double model2Confidence = 0.0;
  String model3ToothNumber = '';
  double model3Confidence = 0.0;

  String? inferenceResultId;

  bool _isLoading = true;
  String? _error;

  String? aiOpinion;
  bool _isLoadingOpinion = false;

  String? doctorOpinion; // 표시용(있으면)
  final TextEditingController _doctorOpinionController = TextEditingController();
  bool _isSubmittingOpinion = false;

  @override
  void initState() {
    super.initState();
    // 비동기 작업 시작 전, mounted 상태를 확인하여 안전하게 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchInferenceResult().then((_) {
        if (!mounted) return;
        if (_error == null && !_isLoading) {
          _fetchGeminiOpinion();
        } else {
          setState(() {
            aiOpinion = "진단 결과 로드 실패로 AI 소견을 요청할 수 없습니다.";
            _isLoadingOpinion = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _doctorOpinionController.dispose();
    super.dispose();
  }

  Future<void> _fetchInferenceResult() async {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final accessToken = await authViewModel.getAccessToken();
      if (accessToken == null) {
        if (!mounted) return;
        setState(() {
          _error = '토큰이 없습니다. 로그인 상태를 확인해주세요.';
          _isLoading = false;
        });
        return;
      }

      // 의사용 단건 조회(이미지 기준)
      final imagePath = widget.originalImageUrl; // 이미 상대경로
      final uri = Uri.parse(
        '${widget.baseUrl}/inference_results?role=D&user_id=${widget.userId}&image_path=${Uri.encodeComponent(imagePath)}',
      );

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      // http 요청 완료 후 mounted 상태 확인
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          inferenceResultId = data['_id'];
          overlay1Url = data['model1_image_path'];
          overlay2Url = data['model2_image_path'];
          overlay3Url = data['model3_image_path'];

          className = data['model1_inference_result']?['label'] as String? ?? 'Unknown';
          confidence = (data['model1_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;
          model2Label = data['model2_inference_result']?['label'] as String? ?? 'Unknown';
          model2Confidence = (data['model2_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;
          model3ToothNumber = data['model3_inference_result']?['tooth_number_fdi']?.toString() ?? 'Unknown';
          model3Confidence = (data['model3_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          // ⚠️ doctor_opinion은 inference 결과에 없을 수 있음(ConsultRequest 테이블에 저장됨)
          // 필요하면 별도 API가 필요. 일단 입력 값만 유지.
          doctorOpinion = null;

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '진단 결과 불러오기 실패: ${res.statusCode}. ${res.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGeminiOpinion() async {
    if (!mounted) return; // 비동기 작업 시작 전 mounted 상태 확인
    setState(() => _isLoadingOpinion = true);

    final authViewModel = context.read<AuthViewModel>();
    final accessToken = await authViewModel.getAccessToken();
    if (accessToken == null) {
      if (!mounted) return;
      setState(() {
        aiOpinion = 'AI 소견 요청 실패: 토큰이 없습니다.';
        _isLoadingOpinion = false;
      });
      return;
    }

    if (className == 'Unknown' && confidence == 0.0 && model2Label == 'Unknown' && model3ToothNumber == 'Unknown') {
      if (!mounted) return;
      setState(() {
        aiOpinion = 'AI 소견 요청 실패: 진단 결과가 유효하지 않습니다.';
        _isLoadingOpinion = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('${widget.baseUrl}/multimodal_gemini');
      final requestBodyMap = {
        'image_url': widget.baseUrl.replaceAll('/api', '') + widget.originalImageUrl,
        'model1Label': className,
        'model1Confidence': confidence,
        'model2Label': model2Label,
        'model2Confidence': model2Confidence,
        'model3ToothNumber': model3ToothNumber,
        'model3Confidence': model3Confidence,
        'inference_result_id': inferenceResultId,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBodyMap),
      );

      // http 요청 완료 후 mounted 상태 확인
      if (!mounted) return;
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          aiOpinion = result['message'] ?? 'AI 소견을 불러오지 못했습니다.';
        });
      } else {
        setState(() {
          aiOpinion = 'AI 소견 요청 실패: ${response.statusCode}. ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiOpinion = 'AI 소견 요청 중 오류: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingOpinion = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submitDoctorOpinion() async {
    if (!mounted) return; // 비동기 작업 시작 전 mounted 상태 확인
    setState(() => _isSubmittingOpinion = true);

    final opinionText = _doctorOpinionController.text.trim();
    if (opinionText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('의견을 입력해주세요.')),
      );
      setState(() => _isSubmittingOpinion = false);
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final accessToken = await authViewModel.getAccessToken();
    if (accessToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
      );
      setState(() => _isSubmittingOpinion = false);
      return;
    }

    try {
      // ✅ 백엔드 스펙: /api/consult/reply (POST)
      final now = DateTime.now();
      final ts = '${now.year}${_two(now.month)}${_two(now.day)}${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';

      final uri = Uri.parse('${widget.baseUrl}/consult/reply');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      final body = jsonEncode({
        'request_id': widget.requestId, // ✅ 정수
        'doctor_id': widget.doctorRegisterId, // ✅ 문자열(register_id)
        'comment': opinionText,
        'reply_datetime': ts,
      });

      debugPrint('[reply] POST $uri');
      debugPrint('[reply] body=$body');

      final res = await http.post(uri, headers: headers, body: body);

      // http 요청 완료 후 mounted 상태 확인
      if (!mounted) return;
      if (res.statusCode == 200) {
        // 성공: 화면 갱신 및 알림
        setState(() {
          doctorOpinion = opinionText;
        });
        
        // showDialog 호출 전 mounted 상태 확인
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('제출 완료'),
            content: const Text('의사 의견이 성공적으로 저장되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              )
            ],
          ),
        );
      } else {
        // 실패: Snackbar 호출 전 mounted 상태 확인
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('의견 제출 실패: ${res.statusCode} ${res.body}')),
        );
      }
    } catch (e) {
      // 예외 발생 시 Snackbar 호출 전 mounted 상태 확인
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmittingOpinion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color outerBackground = Color(0xFFE7F0FF);
    const Color buttonColor = Color(0xFF3869A8);

    return Scaffold(
      backgroundColor: outerBackground,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text('진단 결과', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildToggleCard(),
                      const SizedBox(height: 16),
                      _buildFixedImageCard(widget.originalImageUrl),
                      const SizedBox(height: 16),
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildAiOpinionCard(),
                      const SizedBox(height: 16),
                      _buildDoctorOpinionDisplayCard(),
                      const SizedBox(height: 16),
                      _buildDoctorOpinionCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAiOpinionCard() => Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI 소견', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_isLoadingOpinion)
              const Center(child: CircularProgressIndicator())
            else
              Text(aiOpinion ?? '소견이 없습니다.', style: const TextStyle(fontSize: 16)),
          ],
        ),
      );

  Widget _buildDoctorOpinionDisplayCard() => Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('의사 의견', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(doctorOpinion ?? '아직 의사 의견이 없습니다.', style: const TextStyle(fontSize: 16)),
          ],
        ),
      );

  Widget _buildDoctorOpinionCard() {
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
            decoration: InputDecoration(
              hintText: '환자에게 전달할 진단 결과 및 조언을 작성하세요.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSubmittingOpinion ? null : _submitDoctorOpinion,
            icon: _isSubmittingOpinion
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.white),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _isSubmittingOpinion ? '전송 중...' : '보내기',
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

  Widget _buildFixedImageCard(String imageUrl) {
    final cleanBaseUrl = widget.baseUrl.replaceAll('/api', '');
    final originalFullUrl = '$cleanBaseUrl$imageUrl';
    final ov1 = overlay1Url != null ? '$cleanBaseUrl$overlay1Url' : null;
    final ov2 = overlay2Url != null ? '$cleanBaseUrl$overlay2Url' : null;
    final ov3 = overlay3Url != null ? '$cleanBaseUrl$overlay3Url' : null;

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('진단 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    originalFullUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                  ),
                  if (_showDisease && ov1 != null)
                    Image.network(ov1, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                  if (_showHygiene && ov2 != null)
                    Image.network(ov2, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                  if (_showToothNumber && ov3 != null)
                    Image.network(ov3, fit: BoxFit.fill, opacity: const AlwaysStoppedAnimation(0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() => Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('진단 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("모델1 (질병): $className, ${(confidence * 100).toStringAsFixed(1)}%"),
            Text("모델2 (위생): $model2Label, ${(model2Confidence * 100).toStringAsFixed(1)}%"),
            Text("모델3 (치아번호): $model3ToothNumber, ${(model3Confidence * 100).toStringAsFixed(1)}%"),
          ],
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
      );
}

