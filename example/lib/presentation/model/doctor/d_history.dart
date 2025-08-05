// lib/presentation/model/doctor/d_history.dart

class DoctorHistoryRecord {
  // 공통 필드
  final String userId;
  final DateTime timestamp;

  // ✅ 환자 추론 결과 기반 필드
  final String? id;
  final String? originalImageFilename;
  final String? originalImagePath;
  final String? processedImagePath;
  final double? confidence;
  final String? modelUsed;
  final String? className;
  final List<List<int>>? lesionPoints;
  final Map<String, dynamic>? model1InferenceResult;
  final Map<String, dynamic>? model2InferenceResult;
  final Map<String, dynamic>? model3InferenceResult;

  // ✅ model3 관련 경로 (추가됨)
  final String? model3_1ImagePath;
  final String? model3_2ImagePath;

  // ✅ 의사용 진료 신청 리스트 기반 필드
  final int? requestId;
  final String? userName;
  final String? imagePath;
  final String? isReplied;
  final String? doctorComment;

  DoctorHistoryRecord({
    required this.userId,
    required this.timestamp,
    this.id,
    this.originalImageFilename,
    this.originalImagePath,
    this.processedImagePath,
    this.confidence,
    this.modelUsed,
    this.className,
    this.lesionPoints,
    this.model1InferenceResult,
    this.model2InferenceResult,
    this.model3InferenceResult,
    this.model3_1ImagePath,
    this.model3_2ImagePath,
    this.requestId,
    this.userName,
    this.imagePath,
    this.isReplied,
    this.doctorComment,
  });

  factory DoctorHistoryRecord.fromJson(Map<String, dynamic> json) {
    final model1Inf = json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final model2Inf = json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final model3Inf = json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    final isConsult = json.containsKey('request_id');

    return DoctorHistoryRecord(
      userId: json['user_id'] ?? '',
      timestamp: DateTime.tryParse(
        json['timestamp'] ?? json['request_datetime'] ?? '',
      ) ?? DateTime.now(),

      // 추론 결과용 필드
      id: json['_id'],
      originalImageFilename: json['original_image_filename'],
      originalImagePath: json['original_image_path'] ?? (isConsult ? json['image_path'] : null),
      processedImagePath: json['processed_image_path'],
      confidence: (model1Inf['confidence'] as num?)?.toDouble(),
      modelUsed: model1Inf['used_model'] as String?,
      className: model1Inf['label'] as String?,
      lesionPoints: (model1Inf['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),
      model1InferenceResult: model1Inf,
      model2InferenceResult: model2Inf,
      model3InferenceResult: model3Inf,

      // ✅ 추가된 model3 마스크 경로
      model3_1ImagePath: json['model3_1_image_path'],
      model3_2ImagePath: json['model3_2_image_path'],

      // 진료 신청용 필드
      requestId: isConsult ? json['request_id'] : null,
      userName: isConsult ? json['user_name'] : null,
      imagePath: isConsult ? json['image_path'] : null,
      isReplied: isConsult ? json['is_replied'] : null,
      doctorComment: isConsult ? json['doctor_comment'] : null,
    );
  }
}

extension DoctorHistoryRecordExtensions on DoctorHistoryRecord {
  String get inferenceResultId => id ?? '';

  /// ✅ model3_2 만 사용
  Map<int, String> get processedImageUrls {
    final result = <int, String>{};
    if (model1InferenceResult?['processed_image_path'] != null) {
      result[1] = model1InferenceResult!['processed_image_path'];
    }
    if (model2InferenceResult?['processed_image_path'] != null) {
      result[2] = model2InferenceResult!['processed_image_path'];
    }
    if (model3_2ImagePath != null) {
      result[3] = model3_2ImagePath!;
    }
    return result;
  }

  Map<int, Map<String, dynamic>> get modelInfos {
    final result = <int, Map<String, dynamic>>{};
    if (model1InferenceResult != null) result[1] = model1InferenceResult!;
    if (model2InferenceResult != null) result[2] = model2InferenceResult!;
    if (model3InferenceResult != null) result[3] = model3InferenceResult!;
    return result;
  }

  String get originalImageUrl => originalImagePath ?? imagePath ?? '';
}
