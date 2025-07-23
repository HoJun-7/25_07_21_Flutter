// lib/presentation/screens/doctor/d_consult_reply_detail_screen.dart
import 'package:flutter/material.dart';
import 'result_image_base.dart';

class DConsultReplyDetailScreen extends StatelessWidget {
  final String imageUrl;
  final Map<int, String> processedImageUrls;
  final Map<int, Map<String, dynamic>> modelInfos;
  final String doctorComment;

  const DConsultReplyDetailScreen({
    super.key,
    required this.imageUrl,
    required this.processedImageUrls,
    required this.modelInfos,
    required this.doctorComment,
  });

  @override
  Widget build(BuildContext context) {
    int selectedModelIndex = 1;
    final modelInfo = modelInfos[selectedModelIndex];

    return Scaffold(
      appBar: AppBar(title: const Text("답변 완료")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ResultImageWithToggle(
              selectedModelIndex: selectedModelIndex,
              onModelToggle: (_) {},
              imageUrl: processedImageUrls[selectedModelIndex] ?? imageUrl,
            ),
            const SizedBox(height: 12),
            if (modelInfo != null)
              AIResultBox(
                modelName: modelInfo['model_used'],
                confidence: modelInfo['confidence'],
                className: 'Dental Plaque',
              ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("🩺 의사 소견:\n$doctorComment"),
            ),
          ],
        ),
      ),
    );
  }
}
