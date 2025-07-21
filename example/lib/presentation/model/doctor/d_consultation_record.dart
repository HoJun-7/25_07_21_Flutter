class ConsultationRecord {
  final String id; // MongoDB ObjectId → String
  final String userId;
  final String originalImageFilename;
  final String originalImagePath;
  final String processedImagePath;
  final DateTime timestamp;

  final double? confidence;
  final String? modelUsed;
  final String? className;
  final List<List<int>>? lesionPoints;

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
  });

  // ✅ 날짜 getter
  String get consultationDate {
    return "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
  }

  // ✅ 시간 getter
  String get consultationTime {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  // ✅ AI 결과 getter
  String? get aiResult {
    if (confidence == null) return null;
    return "${(confidence! * 100).toStringAsFixed(1)}% 확신도";
  }

  // ✅ 증상 getter (임시)
  String? get chiefComplaint {
    return originalImageFilename; // 실제 증상이 없다면 파일 이름을 예시로 대체
  }

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    final inference = json['inference_result'] ?? {};

    return ConsultationRecord(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      originalImageFilename: json['original_image_filename'] ?? '',
      originalImagePath: json['original_image_path'] ?? '',
      processedImagePath: json['processed_image_path'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      confidence: (inference['confidence'] as num?)?.toDouble(),
      modelUsed: inference['model_used'] ?? '',
      className: inference['class_name'] ?? '',
      lesionPoints: (inference['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'original_image_filename': originalImageFilename,
      'original_image_path': originalImagePath,
      'processed_image_path': processedImagePath,
      'timestamp': timestamp.toIso8601String(),
      'inference_result': {
        'confidence': confidence,
        'model_used': modelUsed,
        'class_name': className,
        'lesion_points': lesionPoints,
      },
    };
  }
}
