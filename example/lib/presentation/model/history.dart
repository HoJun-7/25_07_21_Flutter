class HistoryRecord {
  final String id;
  final String userId;
  final String originalImageFilename;
  final String originalImagePath;
  final String processedImagePath;
  final DateTime timestamp;

  final double? confidence; // model1 confidence
  final String? modelUsed;
  final String? className;
  final List<List<int>>? lesionPoints;

  final Map<String, dynamic>? model1InferenceResult;
  final Map<String, dynamic>? model2InferenceResult;
  final Map<String, dynamic>? model3InferenceResult;

  final String source;
  final String isRequested;
  final String isReplied;

  final String imageType;

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
    required this.imageType,
    this.confidence,
    this.modelUsed,
    this.className,
    this.lesionPoints,
    this.model1InferenceResult,
    this.model2InferenceResult,
    this.model3InferenceResult,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    String? _toStr(dynamic value) => value?.toString();
    double? _toDouble(dynamic value) => (value is num) ? value.toDouble() : null;

    final model1Inf = json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final model2Inf = json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final model3Inf = json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    return HistoryRecord(
      id: _toStr(json['_id']) ?? '',
      userId: _toStr(json['user_id']) ?? '',
      originalImageFilename: _toStr(json['original_image_filename']) ?? '',
      originalImagePath: _toStr(json['original_image_path']) ?? '',
      processedImagePath: _toStr(json['processed_image_path']) ?? '',
      timestamp: DateTime.tryParse(_toStr(json['timestamp']) ?? '') ?? DateTime.now(),
      source: _toStr(json['source']) ?? 'AI',
      isRequested: _toStr(json['is_requested']) ?? 'N',
      isReplied: _toStr(json['is_replied']) ?? 'N',
      imageType: _toStr(json['image_type']) ?? 'normal',

      // model1
      confidence: _toDouble(model1Inf['confidence']),
      modelUsed: _toStr(model1Inf['used_model']),
      className: _toStr(model1Inf['label']),
      lesionPoints: (model1Inf['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),

      // 모든 모델 inference 결과 - confidence는 double, 나머지는 그대로
      model1InferenceResult: {
        ...model1Inf,
        'confidence': _toDouble(model1Inf['confidence']),
      },
      model2InferenceResult: {
        ...model2Inf,
        'confidence': _toDouble(model2Inf['confidence']),
      },
      model3InferenceResult: {
        ...model3Inf,
        'confidence': _toDouble(model3Inf['confidence']),
      },
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
      imageType: imageType,
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


