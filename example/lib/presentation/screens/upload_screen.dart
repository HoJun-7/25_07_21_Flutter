import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import 'upload_result_detail_screen.dart';
import '/presentation/viewmodel/upload_viewmodel.dart';
import '/data/service/http_service.dart';
import 'upload_xray_result_detail_screen.dart';

class UploadScreen extends StatefulWidget {
  final String baseUrl;

  const UploadScreen({super.key, required this.baseUrl});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  int _selectedTypeIndex = 0; // 0: 일반사진, 1: X-ray

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _imageFile = null;
      _webImage = null;
    });

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    } else {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) return;

    final authViewModel = context.read<AuthViewModel>();
    final registerId = authViewModel.currentUser?.registerId;

    if (registerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보가 없습니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ UploadViewModel 생성
      final uploadViewModel = UploadViewModel(
        httpService: HttpService(baseUrl: widget.baseUrl),
      );

      // ✅ ViewModel 통해 이미지 업로드
      final responseData = await uploadViewModel.uploadImage(
        userId: registerId,
        imageFile: _imageFile,
        webImage: _webImage,
        imageType: _selectedTypeIndex == 0 ? 'normal' : 'xray', // ✅ 추가
      );
      print("✅ 서버 응답 전체: $responseData"); // ← 이 줄 추가!

      if (responseData == null) {
        throw Exception('서버 응답 없음');
      }

      final inferenceResultId = responseData['inference_result_id'] ?? 'UNKNOWN';
      final baseStaticUrl = widget.baseUrl.replaceFirst('/api', '');

      final originalImageUrl = '$baseStaticUrl${responseData['original_image_path']}';
      final processedImageUrls = {
        1: '$baseStaticUrl${responseData['model1_image_path']}',
        2: '$baseStaticUrl${responseData['model2_image_path']}',
        3: '$baseStaticUrl${responseData['model3_image_path']}',
      };

      if (_selectedTypeIndex == 0) {
        // 일반 사진 → 기존 화면
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadResultDetailScreen(
              originalImageUrl: originalImageUrl,
              processedImageUrls: processedImageUrls,
              modelInfos: {
                1: responseData['model1_inference_result'],
                2: responseData['model2_inference_result'],
                3: responseData['model3_inference_result'],
              },
              userId: registerId,
              inferenceResultId: inferenceResultId,
              baseUrl: widget.baseUrl,
            ),
          ),
        );
      } else {
        // X-ray 사진 → 새로운 화면
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadXrayResultDetailScreen(
              originalImageUrl: originalImageUrl,
              model1ImageUrl: processedImageUrls[1] ?? '',
              model2ImageUrl: processedImageUrls[2] ?? '',
              model1Result: responseData['model1_inference_result'],
              userId: registerId,
              inferenceResultId: inferenceResultId,
              baseUrl: widget.baseUrl,
            ),
          ),
        );
      }
    } catch (e) {
      print('업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 실패')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 진단'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3869A8),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFA9CCF7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                width: 360,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF3869A8), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '진단할 사진을 업로드하세요',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ToggleButtons(
                  isSelected: [_selectedTypeIndex == 0, _selectedTypeIndex == 1],
                  onPressed: (int index) {
                    setState(() {
                      _selectedTypeIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF3869A8),
                  color: Colors.black87,
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 140),
                  children: const [
                    Text("일반사진", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("X-ray 사진", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 360,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF3869A8), width: 1.5),
                ),
                child: (_imageFile != null || _webImage != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb && _webImage != null
                            ? Image.memory(_webImage!, fit: BoxFit.cover, width: 360, height: 280)
                            : Image.file(_imageFile!, fit: BoxFit.cover, width: 360, height: 280),
                      )
                    : Center(
                        child: Text(
                          '선택된 이미지 없음',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 360,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.image),
                  label: const Text('+ 사진 선택'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3869A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 360,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_imageFile != null || _webImage != null) && !_isLoading
                      ? _uploadImage
                      : null,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: const Text('제출'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3869A8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
