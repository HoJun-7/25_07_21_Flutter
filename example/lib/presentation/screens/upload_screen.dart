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
      final uri = Uri.parse('${widget.baseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = registerId;

      if (_imageFile != null) {
        final ext = path.extension(_imageFile!.path).toLowerCase(); // .jpg, .jpeg, .png

        String mimeType = 'image';
        String subType = 'jpeg'; // 기본값
        if (ext == '.png') subType = 'png';
        else if (ext == '.jpg' || ext == '.jpeg') subType = 'jpeg';

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
          filename: 'camera_upload_image.png',
          contentType: MediaType(mimeType, subType),  // ✅ 실제 파일 형식에 맞게 설정됨
        ));
      } else if (_webImage != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _webImage!,
          filename: 'web_image.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        final userId = registerId;
        final inferenceResultId = responseData['inference_result_id'] ?? 'UNKNOWN';
        final originalPath = responseData['original_image_path'];
        final processedPath = responseData['model1_image_path'];
        final inferenceData = responseData['model1_inference_result'];

        if (processedPath != null && inferenceData != null && originalPath != null) {
          final baseStaticUrl = widget.baseUrl.replaceFirst('/api', '');
          final originalImageUrl = '$baseStaticUrl$originalPath';
          final processedImageUrls = {
            1: '$baseStaticUrl${responseData['model1_image_path']}',
            2: '$baseStaticUrl${responseData['model2_image_path']}',
            3: '$baseStaticUrl${responseData['model3_image_path']}',
          };

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
                userId: userId,
                inferenceResultId: inferenceResultId,
                baseUrl: widget.baseUrl,
              ),
            ),
          );
        } else {
          throw Exception('model1_image_path 또는 model1_inference_result 없음');
        }
      } else {
        print('서버 오류: ${response.statusCode}');
        print('응답 본문: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 오류 발생')),
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
