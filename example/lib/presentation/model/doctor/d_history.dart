// lib/presentation/model/doctor/d_history.dart

class DoctorHistoryRecord {
  // 공통
  final String userId;
  final DateTime timestamp;

  // 추론 결과 기반
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

  // 상담 리스트 기반
  final int? requestId;
  final String? userName;
  final String? imagePath;      // /consult/list 의 image_path (상대경로)
  final String? isReplied;
  final String? doctorComment;

  // 이미지 타입 (normal | xray | null → 서버값 없을 때만 휴리스틱)
  final String? imageType;

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
    this.imageType,
  });

  factory DoctorHistoryRecord.fromJson(Map<String, dynamic> json) {
    // ── 모델별 결과 맵 안전 추출
    final Map<String, dynamic> m1 =
        json['model1_inference_result'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> m2 =
        json['model2_inference_result'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> m3 =
        json['model3_inference_result'] as Map<String, dynamic>? ?? {};

    // 이 레코드가 /consult/list 기반인지 여부
    final bool isConsult = json.containsKey('request_id');

    // 공용 원본 경로: inference 결과는 original_image_path, /consult/list는 image_path
    final String? originalPath =
        json['original_image_path']?.toString() ??
        (isConsult ? json['image_path']?.toString() : null);

    // 타임스탬프 파싱 (예: "2025-01-01 12:34:56" → "2025-01-01T12:34:56")
    final String tsRaw =
        (json['timestamp'] ?? json['request_datetime'] ?? '').toString();
    DateTime ts = DateTime.now();
    if (tsRaw.isNotEmpty) {
      final iso = tsRaw.contains(' ') ? tsRaw.replaceFirst(' ', 'T') : tsRaw;
      try {
        ts = DateTime.parse(iso);
      } catch (_) {
        ts = DateTime.now();
      }
    }

    // 이미지 타입: 서버가 내려주는 값을 우선 신뢰 (소문자 정규화)
    String? imageType = (json['image_type'] as String?)?.toLowerCase().trim();
    if (imageType != null && imageType != 'xray' && imageType != 'normal') {
      imageType = null; // 알 수 없는 값은 null
    }

    // 휴리스틱(백업): 서버값이 없을 때만 추론
    if (imageType == null) {
      String collectText(Object? v) => (v ?? '').toString().toLowerCase();

      bool looksXray(String s) {
        final v = s.toLowerCase();
        return v.contains('xray') ||
            v.contains('panoramic') ||
            v.contains('panorama') ||
            v.contains('pano') ||
            RegExp(r'\bpan\b').hasMatch(v) ||
            v.endsWith('.dcm') ||
            v.contains('/xray/') ||
            v.contains('/xmodel');
      }

      final used = collectText(m1['used_model'] ?? json['model_used']);
      final fname = collectText(json['original_image_filename']);
      final path = collectText(originalPath);

      if (looksXray(used) || used.contains('implant')) {
        imageType = 'xray';
      } else if (looksXray(path) || looksXray(fname)) {
        imageType = 'xray';
      } else {
        imageType = 'normal';
      }
    }

    return DoctorHistoryRecord(
      userId: json['user_id']?.toString() ?? '',
      timestamp: ts,

      // 추론용
      id: json['_id']?.toString(),
      originalImageFilename: json['original_image_filename']?.toString(),
      originalImagePath: originalPath,
      processedImagePath: json['processed_image_path']?.toString(),
      confidence: (m1['confidence'] as num?)?.toDouble(),
      modelUsed: (m1['used_model'] ?? json['model_used'])?.toString(),
      className: m1['label']?.toString(),
      lesionPoints: (m1['lesion_points'] as List?)
          ?.map<List<int>>((pt) => List<int>.from(pt))
          .toList(),
      model1InferenceResult: m1,
      model2InferenceResult: m2,
      model3InferenceResult: m3,

      // 상담용
      requestId: isConsult ? (json['request_id'] as num?)?.toInt() : null,
      userName: isConsult ? json['user_name']?.toString() : null,
      imagePath: isConsult ? json['image_path']?.toString() : null,
      isReplied: isConsult ? json['is_replied']?.toString() : null,
      doctorComment: isConsult ? json['doctor_comment']?.toString() : null,

      // 최종 이미지 타입
      imageType: imageType,
    );
  }
}

extension DoctorHistoryRecordExtensions on DoctorHistoryRecord {
  String get inferenceResultId => id ?? '';

  /// 원본 이미지 상대경로(또는 절대경로). 화면에서 baseUrl을 붙여 사용.
  String get originalImageUrl => originalImagePath ?? imagePath ?? '';

  /// 모델별 후처리 이미지 경로 맵 (1/2/3)
  Map<int, String> get processedImageUrls {
    final r = <int, String>{};
    final m1 = model1InferenceResult?['processed_image_path']?.toString();
    final m2 = model2InferenceResult?['processed_image_path']?.toString();
    final m3 = model3InferenceResult?['processed_image_path']?.toString();
    if (m1 != null && m1.isNotEmpty) r[1] = m1;
    if (m2 != null && m2.isNotEmpty) r[2] = m2;
    if (m3 != null && m3.isNotEmpty) r[3] = m3;
    return r;
  }

  /// 모델 인포 집계
  Map<int, Map<String, dynamic>> get modelInfos {
    final r = <int, Map<String, dynamic>>{};
    if (model1InferenceResult != null) r[1] = model1InferenceResult!;
    if (model2InferenceResult != null) r[2] = model2InferenceResult!;
    if (model3InferenceResult != null) r[3] = model3InferenceResult!;
    return r;
  }

  /// 파일명 헬퍼(환자쪽과 동일한 방식으로 오버레이 URL을 만들 때 필요)
  String get modelFilename {
    final p = originalImageUrl;
    if (p.isEmpty) return '';
    final parts = p.split('/');
    return parts.isNotEmpty ? parts.last : p;
  }

  /// 최우선: 서버가 내려준 imageType 신뢰. 없을 때만 휴리스틱 보조 판단.
  bool get isXray {
    if (imageType?.toLowerCase() == 'xray') return true;
    if (imageType?.toLowerCase() == 'normal') return false;

    // 백업 휴리스틱
    bool hint(String s) => s.toLowerCase().contains('xray') ||
        s.toLowerCase().contains('panoramic') ||
        s.toLowerCase().contains('panorama') ||
        s.toLowerCase().contains('pano') ||
        RegExp(r'\bpan\b').hasMatch(s.toLowerCase()) ||
        s.toLowerCase().endsWith('.dcm') ||
        s.toLowerCase().contains('/xmodel');

    if (hint(originalImageUrl)) return true;

    final used =
        (model1InferenceResult?['used_model'] ?? modelUsed ?? '').toString();
    if (hint(used) || used.toLowerCase().contains('implant')) return true;

    final t = (model1InferenceResult?['image_type'] ??
            model2InferenceResult?['image_type'] ??
            model3InferenceResult?['image_type'])
        ?.toString()
        .toLowerCase();
    if (t == 'xray' || (t != null && hint(t))) return true;

    return false;
  }
}
