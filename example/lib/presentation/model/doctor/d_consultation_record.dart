class ConsultationRecord {
  final String id;
  final String userId;
  final String originalImageFilename;
  final String originalImagePath;
  final String processedImagePath;
  final DateTime timestamp;
  final double? confidence; // model1의 confidence
  final String? modelUsed; // model1의 used_model
  final String? className; // model1의 label
  final List<List<int>>? lesionPoints; // model1의 lesion_points

  // ✅ 새롭게 추가될 필드들
  final Map<String, dynamic>? model1InferenceResult;
  final Map<String, dynamic>? model2InferenceResult;
  final Map<String, dynamic>? model3InferenceResult;
  
  // 이전결과보기에서 답변중, 답변완료
  final String isRequested;
  final String isReplied;

  ConsultationRecord({
    required this.id,
    required this.userId,
    required this.originalImageFilename,
    required this.originalImagePath,
    required this.processedImagePath,
    required this.timestamp,
    this.confidence,
    this.modelUsed,
    this.className,
    this.lesionPoints,
    this.model1InferenceResult, // 새 필드 추가
    this.model2InferenceResult, // 새 필드 추가
    this.model3InferenceResult, // 새 필드 추가
    required this.isRequested, // 이전결과보기에서 답변중, 답변완료
    required this.isReplied, // 이전결과보기에서 답변중, 답변완료
  });

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    // 백엔드에서 각 모델별 inference_result를 직접 제공한다고 가정
    final model1Inf = json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final model2Inf = json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final model3Inf = json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    return ConsultationRecord(
      id: json['_id'] ?? '', // MongoDB _id
      userId: json['user_id'] ?? '',
      originalImageFilename: json['original_image_filename'] ?? '',
      originalImagePath: json['original_image_path'] ?? '',
      processedImagePath: json['processed_image_path'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      // 기존 필드는 model1 정보로 채움 (호환성 유지)
      confidence: (model1Inf['confidence'] as num?)?.toDouble(),
      modelUsed: model1Inf['used_model'] as String?,
      className: model1Inf['label'] as String?,
      lesionPoints: (model1Inf['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),
      // ✅ 각 모델의 전체 추론 결과 맵을 저장
      model1InferenceResult: model1Inf,
      model2InferenceResult: model2Inf,
      model3InferenceResult: model3Inf,
      isRequested: (json['is_requested'].toString().toUpperCase().startsWith('Y')) ? 'Y' : 'N', // 이전결과보기에서 답변중, 답변완료
      isReplied: (json['is_replied'].toString().toUpperCase().startsWith('Y')) ? 'Y' : 'N', // 이전결과보기에서 답변중, 답변완료
    );
  }
}