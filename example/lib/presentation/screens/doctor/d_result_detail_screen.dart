import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ⬅ 웹 폭 고정용
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';

class DResultDetailScreen extends StatefulWidget {
  final String userId;
  final String originalImageUrl;
  final String baseUrl;
  final int? requestId; // ⬅ consult_request.id (선택 전달)

  const DResultDetailScreen({
    super.key,
    required this.userId,
    required this.originalImageUrl,
    required this.baseUrl,
    this.requestId, // ⬅ 추가
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
  String? _doctorCommentFromDb; // ⬅ DB에서 불러올 의사 소견
  bool _isReplied = false; // ⬅ 답변 완료 여부

  bool _isLoading = true;
  String? _error;

  String? aiOpinion;
  bool _isLoadingOpinion = false;

  final TextEditingController _doctorOpinionController = TextEditingController();
  bool _isSubmittingOpinion = false;

  // ⬅ 추가된 변수들 (오류 해결)
  List<String> get filteredDiseaseLabels {
    // model1Label에서 질병 관련 라벨들을 필터링하는 로직을 여기에 추가
    // 예시: className에 따라 리스트를 반환
    if (className.toLowerCase().contains('caries')) {
      return ['충치'];
    } else if (className.toLowerCase().contains('gingivitis')) {
      return ['치은염 (잇몸 염증)'];
    } else if (className.toLowerCase().contains('periodontitis')) {
      return ['치주질환 (잇몸 뼈 염증)'];
    }
    return [];
  }

  List<String> get hygieneLabels {
    // model2Label에서 위생 관련 라벨들을 필터링하는 로직을 여기에 추가
    // 예시: model2Label에 따라 리스트를 반환
    final labels = <String>[];
    if (model2Label.toLowerCase().contains('calculus')) {
      labels.add('치석');
    }
    if (model2Label.toLowerCase().contains('crown')) {
      labels.add('크라운');
    }
    // TODO: 충전재(filling) 등 추가
    return labels;
  }

  final Map<String, String> diseaseLabelMap = {
    '충치': '🦷',
    '치은염 (잇몸 염증)': '🦷',
    '치주질환 (잇몸 뼈 염증)': '🦴',
  };

  final Map<String, String> hygieneLabelMap = {
    '치석': '🔍',
    '크라운': '👑',
    '충전재': 'Filling', // 예시
  };

  Future<int?> _fetchRequestIdIfNull() async {
    if (widget.requestId != null) return widget.requestId;
    try {
      final uri = Uri.parse(
        '${widget.baseUrl}/consult/status'
        '?user_id=${Uri.encodeComponent(widget.userId)}'
        '&image_path=${Uri.encodeComponent(widget.originalImageUrl)}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final m = json.decode(res.body);
        final id = m['request_id'];
        final String isRepliedStatus = m['is_replied'] ?? 'N';
        final String? commentFromDb = m['doctor_comment']; // DB에서 의사 소견 받아오기

        setState(() {
          _isReplied = (isRepliedStatus == 'Y');
          _doctorCommentFromDb = commentFromDb;
          // DB에서 불러온 코멘트가 있다면 컨트롤러에 설정
          if (_isReplied && _doctorCommentFromDb != null) {
            _doctorOpinionController.text = _doctorCommentFromDb!;
          }
        });

        if (id == null) return null;
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchRequestIdIfNull().then((_) {
      _fetchInferenceResult().then((_) {
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

      final imagePath = widget.originalImageUrl;
      final uri = Uri.parse(
        '${widget.baseUrl}/inference_results?role=D&user_id=${widget.userId}&image_path=${Uri.encodeComponent(imagePath)}',
      );

      print('Fetching inference results from: $uri');
      print('Authorization Header (Inference): Bearer $accessToken');

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print('Inference Result Success: ${res.statusCode}');
        print('Inference Data: $data');

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
        'image_url': widget.baseUrl.replaceAll('/api', '') + widget.originalImageUrl,
        'model1Label': className,
        'model1Confidence': confidence,
        'model2Label': model2Label,
        'model2Confidence': model2Confidence,
        'model3ToothNumber': model3ToothNumber,
        'model3Confidence': model3Confidence,
        'inference_result_id': inferenceResultId,
      };
      final requestBody = jsonEncode(requestBodyMap);

      print('--- Gemini API Request Details ---');
      print('Request URL: $uri');
      print('Request Body (JSON): $requestBody');
      print('Request Body (Map): $requestBodyMap');
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

    try {
      final authViewModel = context.read<AuthViewModel>();
      final accessToken = await authViewModel.getAccessToken();
      if (accessToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        setState(() => _isSubmittingOpinion = false);
        return;
      }

      int? reqId = widget.requestId;
      if (reqId == null) {
        reqId = await _fetchRequestIdIfNull();
      }
      if (reqId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요청 ID를 찾을 수 없습니다.')),
        );
        setState(() => _isSubmittingOpinion = false);
        return;
      }

      final uri = Uri.parse('${widget.baseUrl}/consult/reply');
      final body = jsonEncode({
        'request_id': reqId,
        'comment': opinionText,
      });

      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: body,
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _isReplied = true;
          _doctorCommentFromDb = opinionText; // 현재 제출된 의견을 저장
          _doctorOpinionController.text = opinionText; // 컨트롤러 텍스트를 최신 의견으로 업데이트
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('제출 완료'),
            content: const Text('의사 의견이 저장되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 팝업창 닫기
                  context.pop(true); // 이전 화면(목록)으로 돌아가면서 새로고침 신호 전달
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmittingOpinion = false);
    }
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
  );

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
    // 힌트 텍스트를 결정합니다.
    String currentHintText = '환자에게 전달할 진단 결과 및 조언을 작성하세요.';
    // _isReplied가 true이고, 컨트롤러에 텍스트가 이미 있다면 힌트를 표시하지 않습니다.
    // 이는 컨트롤러의 텍스트가 실제 값이고 힌트가 필요 없음을 의미합니다.
    if (_isReplied && _doctorOpinionController.text.isNotEmpty) {
      currentHintText = '';
    } else if (_isReplied) {
      // 답변 완료되었지만, 컨트롤러가 비어있는 경우 (초기 로딩 시)
      currentHintText = '작성 완료된 의사 소견입니다.';
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
            enabled: !_isReplied, // 답변 완료되면 비활성화
            decoration: InputDecoration(
              hintText: currentHintText, // 동적으로 힌트 텍스트 설정
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (_isSubmittingOpinion || _isReplied) ? null : _submitDoctorOpinion,
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

  Widget _buildToggleCard() => Container(
    decoration: _cardDecoration(),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('인공지능 분석 결과', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),// 250814 변경
        const SizedBox(height: 12),
        _buildStyledToggle("질병", _showDisease, (val) => setState(() => _showDisease = val)),// 250814 변경
        _buildStyledToggle("위생", _showHygiene, (val) => setState(() => _showHygiene = val)),// 250814 변경
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
        if (filteredDiseaseLabels.isNotEmpty) ...[
          const Text('충치/치은염(잇몸 염증)/치주질환(잇몸 뼈까지 진행된 염증)', style: TextStyle(fontWeight: FontWeight.w600)),// 250814 변경
          ...filteredDiseaseLabels.map((label) {
            final icon = diseaseLabelMap[label] ?? "❓";
            return Text("$icon : $label", style: Theme.of(context).textTheme.bodyMedium);
          }),
          const SizedBox(height: 8),
        ],
        if (_showHygiene) ...[
          const Text('치석/크라운/충전재', style: TextStyle(fontWeight: FontWeight.w600)),// 250814 변경
          if (hygieneLabels.isNotEmpty)
            ...hygieneLabels.map((l) => Text("${hygieneLabelMap[l]} : $l", style: Theme.of(context).textTheme.bodyMedium))
          else
            Text('감지되지 않음', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
      ],
    ),
  );

  Widget _buildBodyContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null
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
              ));
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