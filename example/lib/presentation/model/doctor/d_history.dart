// lib/presentation/model/doctor/d_history.dart

import 'package:intl/intl.dart';

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

  // ✅ 의사용 진료 신청 리스트 기반 필드
  final int? requestId;         // ← 정렬용: 안전하게 int로 변환
  final String? userName;
  final String? imagePath;
  final bool? isReplied;        // ← bool로 변경!
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
    this.requestId,
    this.userName,
    this.imagePath,
    this.isReplied,
    this.doctorComment,
  });

  // 여러 날짜 포맷 시도
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString();
    // 1) 표준 ISO(스페이스 포함) 시도
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // 2) 백엔드 list에서 "yyyy-MM-dd HH:mm:ss"
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parseStrict(s);
    } catch (_) {}

    // 3) 환자쪽 결과에서 "Thu, 07 Aug 2025 15:38:06 GMT" (RFC1123 유사)
    try {
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(s).toLocal();
    } catch (_) {}

    return DateTime.now();
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
    }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == 'y' || s == 'yes' || s == '1') return true;
      if (s == 'false' || s == 'n' || s == 'no' || s == '0') return false;
    }
    return null;
  }

  static List<List<int>>? _parseLesionPoints(dynamic v) {
    final list = v as List?;
    if (list == null) return null;
    return list.map<List<int>>((pt) {
      final p = (pt as List).map((e) {
        if (e is int) return e;
        if (e is num) return e.toInt();
        if (e is String) return int.tryParse(e) ?? 0;
        return 0;
      }).toList();
      return List<int>.from(p);
    }).toList();
  }

  factory DoctorHistoryRecord.fromJson(Map<String, dynamic> json) {
    final model1Inf = json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final model2Inf = json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final model3Inf = json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    final isConsult = json.containsKey('request_id');

    return DoctorHistoryRecord(
      userId: (json['user_id'] ?? '').toString(),
      timestamp: _parseTimestamp(json['timestamp'] ?? json['request_datetime']),

      // 추론 결과용 필드
      id: json['_id']?.toString(),
      originalImageFilename: json['original_image_filename']?.toString(),
      // consult 응답엔 original_image_path가 없고 image_path만 오므로 fallback
      originalImagePath: (json['original_image_path'] ?? (isConsult ? json['image_path'] : null))?.toString(),
      processedImagePath: json['processed_image_path']?.toString(),
      confidence: (model1Inf['confidence'] is num)
          ? (model1Inf['confidence'] as num).toDouble()
          : (double.tryParse(model1Inf['confidence']?.toString() ?? '') ?? 0.0),
      modelUsed: model1Inf['used_model']?.toString(),
      className: model1Inf['label']?.toString(),
      lesionPoints: _parseLesionPoints(model1Inf['lesion_points']),
      model1InferenceResult: model1Inf.isEmpty ? null : model1Inf,
      model2InferenceResult: model2Inf.isEmpty ? null : model2Inf,
      model3InferenceResult: model3Inf.isEmpty ? null : model3Inf,

      // 진료 신청용 필드
      requestId: isConsult ? _toInt(json['request_id']) : null,
      userName: isConsult ? json['user_name']?.toString() : null,
      imagePath: isConsult ? json['image_path']?.toString() : null,
      isReplied: isConsult ? _toBool(json['is_replied']) : null, // ← bool로 받음
      doctorComment: isConsult ? json['doctor_comment']?.toString() : null,
    );
  }
}

extension DoctorHistoryRecordExtensions on DoctorHistoryRecord {
  String get inferenceResultId => id ?? '';

  Map<int, String> get processedImageUrls {
    final result = <int, String>{};
    final m1 = model1InferenceResult;
    final m2 = model2InferenceResult;
    final m3 = model3InferenceResult;
    if (m1 != null && m1['processed_image_path'] != null) {
      result[1] = m1['processed_image_path'].toString();
    }
    if (m2 != null && m2['processed_image_path'] != null) {
      result[2] = m2['processed_image_path'].toString();
    }
    if (m3 != null && m3['processed_image_path'] != null) {
      result[3] = m3['processed_image_path'].toString();
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

  String get originalImageUrl => (originalImagePath ?? imagePath ?? '');
}
