import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';

class DResultDetailScreen extends StatefulWidget {
  final String userId;
  final String originalImageUrl;
  final String baseUrl;

  const DResultDetailScreen({
    super.key,
    required this.userId,
    required this.originalImageUrl,
    required this.baseUrl,
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

  // Inference 결과에서 받아올 _id를 저장할 변수 추가 (백엔드 조회용)
  String? inferenceResultId;

  bool _isLoading = true;
  String? _error;

  String? aiOpinion;
  bool _isLoadingOpinion = false;

  final TextEditingController _doctorOpinionController = TextEditingController();
  bool _isSubmittingOpinion = false;

  @override
  void initState() {
    super.initState();
    // 초기 로드 시 inference 결과와 Gemini 의견을 모두 가져오도록 합니다.
    _fetchInferenceResult().then((_) {
      // Inference 결과가 성공적으로 로드된 후에만 Gemini 의견을 요청합니다.
      // 그렇지 않으면 model1Label 등의 값이 초기값으로 전송될 수 있습니다.
      if (_error == null && !_isLoading) {
        _fetchGeminiOpinion();
      } else {
        setState(() {
          aiOpinion = "진단 결과 로드 실패로 AI 소견을 요청할 수 없습니다.";
          _isLoadingOpinion = false; // 에러 발생 시 로딩 상태 해제
        });
      }
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

      final imagePath = widget.originalImageUrl;
      final uri = Uri.parse(
        '${widget.baseUrl}/inference_results?role=D&user_id=${widget.userId}&image_path=${Uri.encodeComponent(imagePath)}',
      );

      print('Fetching inference results from: $uri');
      print('Authorization Header (Inference): Bearer $accessToken'); // 명확한 로깅

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print('Inference Result Success: ${res.statusCode}');
        print('Inference Data: $data');

        setState(() {
          // Inference 결과에서 _id 값을 저장
          inferenceResultId = data['_id']; // 추가된 부분!

          overlay1Url = data['model1_image_path'];
          overlay2Url = data['model2_image_path'];
          overlay3Url = data['model3_image_path'];

          // null 체크를 좀 더 명시적으로 강화
          className = data['model1_inference_result']?['label'] as String? ?? 'Unknown';
          confidence = (data['model1_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          model2Label = data['model2_inference_result']?['label'] as String? ?? 'Unknown';
          model2Confidence = (data['model2_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          model3ToothNumber = data['model3_inference_result']?['tooth_number_fdi']?.toString() ?? 'Unknown';
          model3Confidence = (data['model3_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          _isLoading = false;
        });
      } else {
        print('Inference Result Failed: ${res.statusCode}');
        print('Inference Error Body: ${res.body}');
        setState(() {
          _error = '진단 결과 불러오기 실패: ${res.statusCode}. ${res.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Error fetching inference results: $e');
      setState(() {
        _error = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGeminiOpinion() async {
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

    // 서버의 Gemini API가 이미지 URL 대신 _id를 사용하여 분석 결과를 조회할 가능성이 있습니다.
    // 백엔드 개발자와 확인 후 필요하다면 아래 requestBody에 'inferenceResultId': inferenceResultId, 를 추가하거나,
    // image_url 대신 inferenceResultId만 보낼 수도 있습니다.
    // 현재는 image_url과 모든 추론 결과를 함께 보내는 방식입니다.
    if (className == 'Unknown' && confidence == 0.0 && model2Label == 'Unknown' && model3ToothNumber == 'Unknown') {
        print('Gemini opinion cannot be fetched: Inference results are not yet loaded or are invalid.');
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
        'image_url': widget.baseUrl.replaceAll('/api', '') + widget.originalImageUrl, // 현재는 상대 경로를 보내고 있음
        'model1Label': className,
        'model1Confidence': confidence,
        'model2Label': model2Label,
        'model2Confidence': model2Confidence,
        'model3ToothNumber': model3ToothNumber,
        'model3Confidence': model3Confidence,
        // 필요하다면 백엔드에서 분석 결과 조회를 위해 이 _id를 사용할 수 있습니다.
        // 백엔드 API 명세에 따라 추가하거나 제거하세요.
        'inference_result_id': inferenceResultId,  // <-- 백엔드 디버깅을 위해 추가.
      };
      final requestBody = jsonEncode(requestBodyMap);


      print('--- Gemini API Request Details ---'); // 디버깅을 위한 추가 로깅
      print('Request URL: $uri');
      print('Request Body (JSON): $requestBody');
      print('Request Body (Map): $requestBodyMap'); // 맵 형태로도 출력하여 확인 용이
      print('Authorization Header (Gemini): Bearer $accessToken');
      print('----------------------------------');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: requestBody,
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('Gemini Opinion Success: ${response.statusCode}');
        print('Gemini Opinion Data: ${result['message']}');
        setState(() {
          aiOpinion = result['message'] ?? 'AI 소견을 불러오지 못했습니다.';
        });
      } else {
        print('Gemini Opinion Failed: ${response.statusCode}');
        print('Gemini Opinion Error Body: ${response.body}');
        setState(() {
          aiOpinion = 'AI 소견 요청 실패: ${response.statusCode}. ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Error fetching Gemini opinion: $e');
      setState(() {
        aiOpinion = 'AI 소견 요청 중 오류: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingOpinion = false);
    }
  }

  Future<void> _submitDoctorOpinion() async {
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

    // 실제 서버 전송 로직이 필요하다면 여기에 추가 (현재는 2초 지연 후 완료 메시지 표시)
    // 예: await http.post(...)
    print('의사 의견 제출: $opinionText');

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmittingOpinion = false);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('제출 완료'),
        content: const Text('의사 의견이 환자에게 전송되었습니다.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color outerBackground = Color(0xFFE7F0FF);
    const Color buttonColor = Color(0xFF3869A8);

    // dentibot.png 에러 관련 주석 (이전과 동일):
    // 이 에러는 이 DResultDetailScreen 위젯 코드와 직접적인 관련이 없습니다.
    // 이는 앱의 다른 어딘가에서 'images/dentibot.png'라는 로컬 에셋을 로드하려고 시도했는데,
    // 해당 파일을 Flutter가 찾지 못해서 발생하는 문제입니다.
    //
    // 해결 방법:
    // 1. 'dentibot.png' 파일이 실제로 프로젝트 내의 'assets/images/' 폴더에 있는지 확인하세요.
    //    (예: project_root/assets/images/dentibot.png)
    // 2. pubspec.yaml 파일에 assets 섹션이 올바르게 설정되어 있는지 확인하세요.
    //    flutter:
    //      uses-material-design: true
    //      assets:
    //        - assets/images/
    //        # 또는 특정 파일만:
    //        # - assets/images/dentibot.png
    // 3. pubspec.yaml 수정 후에는 반드시 터미널에서 'flutter clean' 실행 후 'flutter pub get'을 실행하세요.
    // 4. 앱을 다시 빌드하고 실행하세요.

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
              Text(
                aiOpinion ?? '소견이 없습니다.',
                style: const TextStyle(fontSize: 16),
              ),
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
    // 이미지 오버레이를 위한 baseUrl 처리
    // 현재 로그를 보면, originalImageUrl, model1_image_path 등이 이미 '/'로 시작하는 상대 경로이므로,
    // widget.baseUrl에서 '/api'를 제거한 후 그 뒤에 붙이는 것이 적절해 보입니다.
    final cleanBaseUrl = widget.baseUrl.replaceAll('/api', '');
    final originalFullUrl = '$cleanBaseUrl$imageUrl';
    final ov1 = overlay1Url != null ? '$cleanBaseUrl$overlay1Url' : null;
    final ov2 = overlay2Url != null ? '$cleanBaseUrl$overlay2Url' : null;
    final ov3 = overlay3Url != null ? '$cleanBaseUrl$overlay3Url' : null;

    print('Original Image URL (for display): $originalFullUrl');
    print('Overlay 1 URL (for display): $ov1');
    print('Overlay 2 URL (for display): $ov2');
    print('Overlay 3 URL (for display): $ov3');

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
