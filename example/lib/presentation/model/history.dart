class HistoryRecord {
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

  final Map<String, dynamic>? model1InferenceResult;
  final Map<String, dynamic>? model2InferenceResult;
  final Map<String, dynamic>? model3InferenceResult;

  final String source; // 'AI' 또는 'DOCTOR'

  final String isRequested; // ✅ consult 여부
  final String isReplied;   // ✅ consult 응답 여부

  HistoryRecord({
    required this.id,
    required this.userId,
    required this.originalImageFilename,
    required this.originalImagePath,
    required this.processedImagePath,
    required this.timestamp,
    required this.source,
    required this.isRequested,
    required this.isReplied,
    this.confidence,
    this.modelUsed,
    this.className,
    this.lesionPoints,
    this.model1InferenceResult,
    this.model2InferenceResult,
    this.model3InferenceResult,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    final model1Inf = json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final model2Inf = json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final model3Inf = json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    return HistoryRecord(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      originalImageFilename: json['original_image_filename'] ?? '',
      originalImagePath: json['original_image_path'] ?? '',
      processedImagePath: json['processed_image_path'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      source: json['source'] ?? 'AI',
      isRequested: json['is_requested'] ?? 'N',
      isReplied: json['is_replied'] ?? 'N',
      confidence: (model1Inf['confidence'] as num?)?.toDouble(),
      modelUsed: model1Inf['used_model'] as String?,
      className: model1Inf['label'] as String?,
      lesionPoints: (model1Inf['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),
      model1InferenceResult: model1Inf,
      model2InferenceResult: model2Inf,
      model3InferenceResult: model3Inf,
    );
  }

  HistoryRecord copyWith({
    String? isRequested,
    String? isReplied,
  }) {
    return HistoryRecord(
      id: id,
      userId: userId,
      originalImageFilename: originalImageFilename,
      originalImagePath: originalImagePath,
      processedImagePath: processedImagePath,
      timestamp: timestamp,
      source: source,
      isRequested: isRequested ?? this.isRequested,
      isReplied: isReplied ?? this.isReplied,
      confidence: confidence,
      modelUsed: modelUsed,
      className: className,
      lesionPoints: lesionPoints,
      model1InferenceResult: model1InferenceResult,
      model2InferenceResult: model2InferenceResult,
      model3InferenceResult: model3InferenceResult,
    );
  }
}
