import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_result.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart'; // YOLO 관련 클래스를 위해 추가
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '/models/model_type.dart';
import '/models/slider_type.dart';
import '/services/model_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // ✅ 추가
import '/data/service/http_service.dart'; // ✅ HttpService 사용 위해 추가

// Alpha 값 상수화
const int _kAlpha80Percent = 204; // 0.8 * 255
const int _kAlpha50Percent = 127; // 0.5 * 255
const int _kAlpha20Percent = 51; // 0.2 * 255
const int _kAlpha60Percent = 153; // 0.6 * 255
const int _kAlpha30Percent = 76; // 0.3 * 255 (for inactive track color)

int _captureIndex = 1;
DateTime? _lastCaptureDate;

//List<YOLOResult> _latestResults = []; //추론 결과를 저장할 변수 선언

class CameraInferenceScreen extends StatefulWidget {
  final String userId;
  final String baseUrl;

  const CameraInferenceScreen({
    Key? key,
    required this.userId,
    required this.baseUrl,
  }) : super(key: key);

  @override
  CameraInferenceScreenState createState() => CameraInferenceScreenState();
}

class CameraInferenceScreenState extends State<CameraInferenceScreen> {
  List<String> _classifications = [];
  int _detectionCount = 0;
  double _confidenceThreshold = 0.5;
  double _iouThreshold = 0.45;
  int _numItemsThreshold = 30;
  double _currentFps = 0.0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

  SliderType _activeSlider = SliderType.none;
  ModelType _selectedModel = ModelType.segment; // Set initial model to segment
  bool _isModelLoading = false;
  String? _modelPath; // 실제 로드된 모델의 파일 경로
  String _loadingMessage = '';
  double _downloadProgress = 0.0;
  double _currentZoomLevel = 1.0;
  bool _isFrontCamera = false;

  final _yoloController = YOLOViewController();
  final _yoloViewKey = GlobalKey<YOLOViewState>();
  final bool _useController = true;

  late final ModelManager _modelManager;

  // ✅ YOLO 추리 결과 저장 변수
  List<YOLOResult> _latestResults = [];

  // ✅ YOLOResult -> JSON 질리토클 함수
  List<Map<String, dynamic>> _serializeYOLOResults(List<YOLOResult> results) {
    return results.map((r) => {
      'className': r.className,
      'confidence': r.confidence,
      'box': [r.boundingBox.left, r.boundingBox.top, r.boundingBox.right, r.boundingBox.bottom],
      'classIndex': r.classIndex,
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    // Initialize ModelManager
    _modelManager = ModelManager(
      onDownloadProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() {
            _loadingMessage = message;
          });
        }
      },
    );

    // Load initial model
    _loadModelForPlatform();

    // Set initial thresholds after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useController) {
        _yoloController.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      } else {
        _yoloViewKey.currentState?.setThresholds(
          confidenceThreshold: _confidenceThreshold,
          iouThreshold: _iouThreshold,
          numItemsThreshold: _numItemsThreshold,
        );
      }
    });
  }


  /// YOLO 추론 결과가 발생할 때 호출되는 콜백 함수.
  ///
  /// 이 함수는 감지된 객체의 개수를 업데이트하고,
  /// 분류(Classification) 모드일 경우 가장 확률이 높은 3개의 클래스를 표시합니다.
  void _onDetectionResults(List<YOLOResult> results) {
    _latestResults = results; // 직렬화를 위해 저장
    debugPrint('🟦 onDetectionResults called: ${results.length}개');
    results.asMap().forEach((i, r) => debugPrint(' - $i: ${r.className} (${r.confidence})'));
    if (!mounted) return;

    // FPS 카운터 업데이트
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;
    if (elapsed >= 1000) {
      _currentFps = _frameCount * 1000 / elapsed;
      _frameCount = 0;
      _lastFpsUpdate = now;
      debugPrint('Calculated FPS: ${_currentFps.toStringAsFixed(1)}');
    }

    // UI에 감지된 객체 수 업데이트
    setState(() {
      _detectionCount = results.length;
      // 분류(Classification) 모드일 때: top 3개 뽑아서 사용
      if (_selectedModel.task == YOLOTask.classify) { // ModelType.classify 대신 YOLOTask.classify 사용
        for (final r in results) {
          debugPrint('${r.className} (${(r.confidence * 100).toStringAsFixed(1)}%)');
        }
        // 분류 결과 3개까지
        _classifications = results
            .take(3)
            .map((r) => r.confidence < 0.5
                ? "알 수 없음"
                : "${r.className} ${(r.confidence * 100).toStringAsFixed(1)}%")
            .toList();
      } else {
        // detect/segment: 분류 정보 필요 없음
        _classifications = [];
      }
      debugPrint('_classifications: $_classifications');
    });
  }

  /// 캡처 버튼 로직: 모델 일시 중지 후 원본 이미지 캡처 및 서버 전송
  Future<void> _captureAndSendToServer() async {
    debugPrint('🟢 _captureAndSendToServer: Start');
    try {
      if (!_yoloController.isInitialized) {
        throw Exception('YOLO 컨트롤러가 초기화되지 않았습니다.');
      }

      final viewKey = _yoloViewKey.currentState;
      viewKey?.setVisibility(false);

      setState(() {
        _isModelLoading = true;
        _loadingMessage = '원본 이미지 캡처 중...';
      });

      Uint8List? imageData;
      const maxWait = Duration(seconds: 1);
      final start = DateTime.now();

      while (imageData == null && DateTime.now().difference(start) < maxWait) {
        imageData = await _yoloController.captureRawFrame();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      viewKey?.setVisibility(true);

      if (imageData == null) {
        throw Exception('이미지 캡처에 실패했습니다.');
      }

      // ✅ Android 권한 요청 (Android 13+)
      if (Platform.isAndroid) {
        var status = await Permission.photos.request();
        if (!status.isGranted) {
          throw Exception('사진 저장 권한이 필요합니다.');
        }
      }

      // ✅ 갤러리에 저장
      final galleryFilename = 'YOLO_${DateTime.now().toIso8601String().replaceAll(':', '_')}.png';
      final result = await ImageGallerySaver.saveImage(
        imageData,
        name: galleryFilename.split('.').first,
        quality: 100,
      );

      if (result['isSuccess'] == true) {
        debugPrint('✅ 갤러리에 저장 성공: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📷 사진이 갤러리에 저장되었습니다')),
          );
        }
      } else {
        debugPrint('❌ 갤러리 저장 실패: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('갤러리 저장 실패')),
          );
        }
      }

      // ✅ HttpService 사용하여 서버 업로드
      final String filename = 'realtime_image.png';
      final String yoloJson = jsonEncode(_serializeYOLOResults(_latestResults));

      final httpService = HttpService(baseUrl: widget.baseUrl);
      final response = await httpService.uploadImageWithToken(
        userId: widget.userId,
        imageData: imageData,
        filename: filename,
        yoloResultsJson: yoloJson,
      );

      if (response.statusCode == 200) {
        debugPrint('📤 $filename 업로드 성공!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📷 $filename 업로드 완료')),
          );
        }
      } else {
        final body = await response.stream.bytesToString();
        debugPrint('❌ 업로드 실패: ${response.statusCode}, $body');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업로드 실패: ${response.statusCode}')),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${e.toString()}')),
        );
      }
    } finally {
      debugPrint('🟢 _captureAndSendToServer: 완료');
      setState(() {
        _isModelLoading = false;
        _loadingMessage = '';
      });
    }
  }


  /// 새로운 캡쳐 버튼 위젯을 빌드합니다.
  Widget _buildCaptureButton() {
    return FloatingActionButton(
      onPressed: _captureAndSendToServer, // 통합된 캡쳐 함수 호출
      backgroundColor: Colors.orange,
      child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          // YOLO View: 맨 뒤에 위치해야 함
          if (_modelPath != null && !_isModelLoading) // _modelPath가 null이 아니고 로딩 중이 아닐 때만 표시
            YOLOView(
              // ⚠️ 수정된 부분: _useController 조건 없이 _yoloViewKey를 사용
              key: _yoloViewKey,
              controller: _useController ? _yoloController : null,
              modelPath: _modelPath!, // _modelPath 사용
              task: _selectedModel.task,
              onResult: _onDetectionResults,
              onPerformanceMetrics: (metrics) {
                if (mounted) {
                  setState(() {
                    _currentFps = metrics.fps;
                  });
                }
              },
              onZoomChanged: (zoomLevel) {
                if (mounted) {
                  setState(() {
                    _currentZoomLevel = zoomLevel;
                  });
                }
              },
            )
          else if (_isModelLoading)
            IgnorePointer(
              child: Container(
                color: Colors.black.withAlpha(_kAlpha80Percent),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ultralytics 로고
                      Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                        color: Colors.white.withAlpha(_kAlpha80Percent),
                      ),
                      const SizedBox(height: 32),
                      // 로딩 메시지
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // 진행률 표시기
                      if (_downloadProgress > 0)
                        Column(
                          children: [
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                backgroundColor: Colors.white.withAlpha(_kAlpha20Percent),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Text(
                '모델이 로드되지 않았습니다',
                style: TextStyle(color: Colors.white),
              ),
            ),

          if (_classifications.isNotEmpty)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _classifications.map((txt) =>
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.7 * 255).toInt()), // 0.7 투명도에 해당하는 alpha 값
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: Text(
                        txt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ).toList(),
              ),
            ),

          // 상단 정보 필 (감지 수, FPS, 현재 임계값)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 16),
            left: isLandscape ? 8 : 16,
            right: isLandscape ? 8 : 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 모델 선택기 - REMOVED
                // _buildModelSelector(),
                SizedBox(height: isLandscape ? 8 : 12),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "DETECTIONS" -> "SEGMENTATION"으로 변경
                      Text(
                        'SEGMENTATION: $_detectionCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'FPS: ${_currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_activeSlider == SliderType.confidence)
                  _buildTopPill(
                    '신뢰도 임계값: ${_confidenceThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.iou)
                  _buildTopPill(
                    'IOU 임계값: ${_iouThreshold.toStringAsFixed(2)}',
                  ),
                if (_activeSlider == SliderType.numItems)
                  _buildTopPill('항목 최대: $_numItemsThreshold'),
              ],
            ),
          ),

          // 중앙 로고 - 카메라가 활성화될 때만 표시
          if (_modelPath != null && !_isModelLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: isLandscape ? 0.3 : 0.5,
                    heightFactor: isLandscape ? 0.3 : 0.5,
                    child: Image.asset(
                      'assets/logo.png',
                      color: Colors.white.withAlpha(_kAlpha50Percent),
                    ),
                  ),
                ),
              ),
            ),

          // 제어 버튼
          Positioned(
            bottom: isLandscape ? 16 : 32,
            right: isLandscape ? 8 : 16,
            child: Column(
              children: [
                _buildCaptureButton(), // 통합된 캡쳐 버튼
                if (!_isFrontCamera) ...[
                  SizedBox(height: isLandscape ? 8 : 12),
                  _buildCircleButton(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    onPressed: () {
                      // 줌 레벨 순환: 0.5x -> 1.0x -> 3.0x -> 0.5x
                      double nextZoom;
                      if (_currentZoomLevel < 0.75) {
                        nextZoom = 1.0;
                      } else if (_currentZoomLevel < 2.0) {
                        nextZoom = 3.0;
                      } else {
                        nextZoom = 0.5;
                      }
                      _setZoomLevel(nextZoom);
                    },
                  ),
                ],
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton(Icons.layers, () {
                  _toggleSlider(SliderType.numItems);
                }),
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton(Icons.adjust, () {
                  _toggleSlider(SliderType.confidence);
                }),
                SizedBox(height: isLandscape ? 8 : 12),
                _buildIconButton('assets/iou.png', () {
                  _toggleSlider(SliderType.iou);
                }),
                SizedBox(height: isLandscape ? 16 : 40),
              ],
            ),
          ),

          // 하단 슬라이더 오버레이
          if (_activeSlider != SliderType.none)
            Positioned(
              left: 0,
              right: 0,
              bottom: isLandscape ? 40 : 80,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 16 : 24,
                  vertical: isLandscape ? 8 : 12,
                ),
                color: Colors.black.withAlpha(_kAlpha80Percent),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.yellow,
                    inactiveTrackColor: Colors.white.withAlpha(_kAlpha30Percent),
                    thumbColor: Colors.yellow,
                    overlayColor: Colors.yellow.withAlpha(_kAlpha20Percent),
                  ),
                  child: Slider(
                    value: _getSliderValue(),
                    min: _getSliderMin(),
                    max: _getSliderMax(),
                    divisions: _getSliderDivisions(),
                    label: _getSliderLabel(),
                    onChanged: (value) {
                      setState(() {
                        _updateSliderValue(value);
                      });
                    },
                  ),
                ),
              ),
            ),

          // 카메라 전환 버튼 (오른쪽 상단)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isLandscape ? 8 : 16),
            right: isLandscape ? 8 : 16,
            child: CircleAvatar(
              radius: isLandscape ? 20 : 24,
              backgroundColor: Colors.black.withAlpha(_kAlpha50Percent),
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isFrontCamera = !_isFrontCamera;
                    // 전면 카메라로 전환 시 줌 레벨 재설정
                    if (_isFrontCamera) {
                      _currentZoomLevel = 1.0;
                    }
                  });
                  if (_useController) {
                    _yoloController.switchCamera();
                  } else {
                    _yoloViewKey.currentState?.switchCamera();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 아이콘 또는 이미지로 원형 버튼을 생성합니다.
  ///
  /// [iconOrAsset]은 IconData 또는 asset 경로 문자열이 될 수 있습니다.
  /// [onPressed]는 버튼 탭 시 호출됩니다.
  Widget _buildIconButton(dynamic iconOrAsset, VoidCallback onPressed) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black.withAlpha(_kAlpha20Percent),
      child: IconButton(
        icon: iconOrAsset is IconData
            ? Icon(iconOrAsset, color: Colors.white)
            : Image.asset(
                iconOrAsset,
                width: 24,
                height: 24,
                color: Colors.white,
              ),
        onPressed: onPressed,
      ),
    );
  }

  /// 텍스트로 원형 버튼을 생성합니다.
  ///
  /// [label]은 버튼에 표시할 텍스트입니다.
  /// [onPressed]는 버튼 탭 시 호출됩니다.
  Widget _buildCircleButton(String label, {required VoidCallback onPressed}) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black.withAlpha(_kAlpha20Percent),
      child: TextButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// 활성 슬라이더 유형을 전환합니다.
  ///
  /// 동일한 슬라이더 유형이 다시 선택되면 슬라이더가 숨겨집니다.
  /// 그렇지 않으면 새 슬라이더 유형이 표시됩니다.
  void _toggleSlider(SliderType type) {
    setState(() {
      _activeSlider = (_activeSlider == type) ? SliderType.none : type;
    });
  }

  /// 텍스트가 있는 알약 모양 컨테이너를 빌드합니다.
  ///
  /// [label]은 알약에 표시할 텍스트입니다.
  Widget _buildTopPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(_kAlpha60Percent),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 활성 슬라이더의 현재 값을 가져옵니다.
  double _getSliderValue() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return _numItemsThreshold.toDouble();
      case SliderType.confidence:
        return _confidenceThreshold;
      case SliderType.iou:
        return _iouThreshold;
      default:
        return 0;
    }
  }

  /// 활성 슬라이더의 최소값을 가져옵니다.
  double _getSliderMin() => _activeSlider == SliderType.numItems ? 5 : 0.1;

  /// 활성 슬라이더의 최대값을 가져옵니다.
  double _getSliderMax() => _activeSlider == SliderType.numItems ? 50 : 0.9;

  /// 활성 슬라이더의 분할 수를 가져옵니다.
  int _getSliderDivisions() => _activeSlider == SliderType.numItems ? 9 : 8;

  /// 활성 슬라이더의 레이블 텍스트를 가져옵니다.
  String _getSliderLabel() {
    switch (_activeSlider) {
      case SliderType.numItems:
        return '$_numItemsThreshold';
      case SliderType.confidence:
        return _confidenceThreshold.toStringAsFixed(1);
      case SliderType.iou:
        return _iouThreshold.toStringAsFixed(1);
      default:
        return '';
    }
  }

  /// 활성 슬라이더의 값을 업데이트합니다.
  ///
  /// 이 메서드는 UI 상태와 YOLO 뷰 컨트롤러를 새 임계값으로 업데이트합니다.
  void _updateSliderValue(double value) {
    setState(() {
      switch (_activeSlider) {
        case SliderType.numItems:
          _numItemsThreshold = value.toInt();
          if (_useController) {
            _yoloController.setNumItemsThreshold(_numItemsThreshold);
          } else {
            _yoloViewKey.currentState?.setNumItemsThreshold(_numItemsThreshold);
          }
          break;
        case SliderType.confidence:
          _confidenceThreshold = value;
          if (_useController) {
            _yoloController.setConfidenceThreshold(value);
          } else {
            _yoloViewKey.currentState?.setConfidenceThreshold(value);
          }
          break;
        case SliderType.iou:
          _iouThreshold = value;
          if (_useController) {
            _yoloController.setIoUThreshold(value);
          } else {
            _yoloViewKey.currentState?.setIoUThreshold(value);
          }
          break;
        default:
          break;
      }
    });
  }

  /// 카메라 줌 레벨을 설정합니다.
  ///
  /// UI 상태와 YOLO 뷰 컨트롤러를 새 줌 레벨로 모두 업데이트합니다.
  void _setZoomLevel(double zoomLevel) {
    setState(() {
      _currentZoomLevel = zoomLevel;
    });
    if (_useController) {
      _yoloController.setZoomLevel(zoomLevel);
    } else {
      _yoloViewKey.currentState?.setZoomLevel(zoomLevel);
    }
  }

  /// 모델 선택기 위젯을 빌드합니다. (이전 요청에서 제거됨)
  ///
  /// 이 메서드는 제거되었으므로 더 이상 사용되지 않습니다.
  Widget _buildModelSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(_kAlpha60Percent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ModelType.values.map((model) {
          final isSelected = _selectedModel == model;
          return GestureDetector(
            onTap: () {
              if (!_isModelLoading && model != _selectedModel) {
                setState(() {
                  _selectedModel = model;
                });
                _loadModelForPlatform();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                model.name.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ModelType에 따라 모델 파일 이름을 반환합니다.
  ///
  /// 현재는 ModelType.segment에 대해서만 특정 파일 이름을 반환하고
  /// 다른 모든 모델 타입은 기본값으로 pill_best_float16.tflite를 반환합니다.
  String _getModelFileName(ModelType modelType) {
    switch (modelType) {
      case ModelType.detect:
        return 'best_8n_float16.tflite';
      case ModelType.segment:
        return 'dental_best_float32.tflite'; // 이 모델만 사용될 것
      case ModelType.classify:
        return 'yolo11n-cls.tflite';
      case ModelType.pose: // pose 모델 추가 (만약 있다면)
        return 'yolo11n-pose.tflite';
      case ModelType.obb: // obb 모델 추가 (만약 있다면)
        return 'yolo11n-obb.tflite';
      default:
        return 'pill_best_float16.tflite'; // 기본값 (다른 모델 타입에 대한 폴백)
    }
  }

  /// 플랫폼에 맞는 모델을 로드합니다.
  ///
  /// _selectedModel에 따라 해당 모델 파일을 assets/models에서 로드하고,
  /// 이를 애플리케이션 문서 디렉토리에 복사한 후, _modelPath에 설정합니다.
  /// 모델 로딩 중 상태를 업데이트하여 사용자에게 진행 상황을 보여줍니다.
  Future<void> _loadModelForPlatform() async {
    setState(() {
      _isModelLoading = true;
      _loadingMessage = '${_selectedModel.modelName} 모델 로딩 중...';
      _downloadProgress = 0.0;
      _detectionCount = 0;
      _currentFps = 0.0;
      _frameCount = 0;
      _lastFpsUpdate = DateTime.now();
    });

    try {
      final fileName = _getModelFileName(_selectedModel);
      final ByteData data = await rootBundle.load('assets/models/$fileName');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory modelDir = Directory('${appDir.path}/assets/models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final File file = File('${modelDir.path}/$fileName');
      // 파일이 존재하지 않을 때만 복사하여 불필요한 IO 작업 방지
      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List());
      }

      final modelPath = file.path;

      if (mounted) {
        setState(() {
          _modelPath = modelPath; // 실제 로드된 모델 경로 설정
          _isModelLoading = false;
          _loadingMessage = '';
          _downloadProgress = 0.0;
        });

        debugPrint('CameraInferenceScreen: 모델 경로 설정: $modelPath');

        // YOLOViewController에 새 모델 경로와 작업 유형을 전달하여 모델 전환
        await _yoloController.switchModel(modelPath, _selectedModel.task);
      }
    } catch (e) {
      debugPrint('모델 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isModelLoading = false;
          _loadingMessage = '모델 로드 실패';
          _downloadProgress = 0.0;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('모델 로딩 오류'),
            content: Text(
              '${_selectedModel.modelName} 모델 로드에 실패했습니다: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // YOLOViewController 리소스 정리 (필요시)
    super.dispose();
  }
}