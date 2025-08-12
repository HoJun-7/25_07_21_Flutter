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
  String className = '';
  double confidence = 0.0;
  String model2Label = '';
  double model2Confidence = 0.0;
  String model3ToothNumber = '';
  double model3Confidence = 0.0;

  bool _isLoading = true;
  String? _error;

  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;
  String? _commentSendError;

  @override
  void initState() {
    super.initState();
    _fetchInferenceResult();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchInferenceResult() async {
    try {
      final authViewModel = context.read<AuthViewModel>();
      final accessToken = await authViewModel.getAccessToken();
      if (accessToken == null) {
        setState(() {
          _error = '토큰이 없습니다';
          _isLoading = false;
        });
        return;
      }

      final imagePath = widget.originalImageUrl;
      final uri = Uri.parse(
        '${widget.baseUrl}/inference_results'
        '?role=D'
        '&user_id=${widget.userId}'
        '&image_path=${Uri.encodeComponent(imagePath)}',
      );

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $accessToken',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          overlay1Url = data['model1_image_path'];
          overlay2Url = data['model2_image_path'];
          overlay3Url = data['model3_image_path'];

          modelName = data['model1_inference_result']?['model_used'] ?? 'N/A';
          className = data['model1_inference_result']?['label'] ?? 'Unknown';
          confidence = (data['model1_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          model2Label = data['model2_inference_result']?['label'] ?? 'Unknown';
          model2Confidence = (data['model2_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          model3ToothNumber = data['model3_inference_result']?['tooth_number_fdi']?.toString() ?? 'Unknown';
          model3Confidence = (data['model3_inference_result']?['confidence'] as num?)?.toDouble() ?? 0.0;

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '불러오기 실패: ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isSendingComment = true;
      _commentSendError = null;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final accessToken = await authViewModel.getAccessToken();
      if (accessToken == null) {
        setState(() {
          _commentSendError = '토큰이 없습니다.';
          _isSendingComment = false;
        });
        return;
      }

      final uri = Uri.parse('${widget.baseUrl}/comments/send');
      final response = await http.post(uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'user_id': widget.userId,
            'comment': comment,
          }));

      if (response.statusCode == 200) {
        setState(() {
          _isSendingComment = false;
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코멘트가 성공적으로 전송되었습니다.')),
        );
      } else {
        setState(() {
          _commentSendError = '전송 실패: ${response.statusCode}';
          _isSendingComment = false;
        });
      }
    } catch (e) {
      setState(() {
        _commentSendError = '오류 발생: $e';
        _isSendingComment = false;
      });
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
                      const SizedBox(height: 24),
                      _buildCommentInputCard(),
                    ],
                  ),
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
                    Image.network(
                      ov1,
                      fit: BoxFit.fill,
                      opacity: const AlwaysStoppedAnimation(0.5),
                    ),
                  if (_showHygiene && ov2 != null)
                    Image.network(
                      ov2,
                      fit: BoxFit.fill,
                      opacity: const AlwaysStoppedAnimation(0.5),
                    ),
                  if (_showToothNumber && ov3 != null)
                    Image.network(
                      ov3,
                      fit: BoxFit.fill,
                      opacity: const AlwaysStoppedAnimation(0.5),
                    ),
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

  Widget _buildCommentInputCard() => Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '의사 코멘트 작성',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '여기에 코멘트를 입력하세요.',
              ),
            ),
            if (_commentSendError != null) ...[
              const SizedBox(height: 8),
              Text(
                _commentSendError!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingComment ? null : _sendComment,
                child: _isSendingComment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('환자에게 코멘트 보내기'),
              ),
            ),
          ],
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3869A8), width: 1.5),
      );
}
