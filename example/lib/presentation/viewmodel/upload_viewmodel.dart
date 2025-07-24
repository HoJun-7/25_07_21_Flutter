import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '/data/service/http_service.dart';

class UploadViewModel with ChangeNotifier {
  final HttpService httpService;

  UploadViewModel({required this.httpService});

  Future<Map<String, dynamic>?> uploadImage({
    required String userId,
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      final uri = Uri.parse('${httpService.baseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId;

      if (imageFile != null) {
        final ext = p.extension(imageFile.path).toLowerCase();
        final subType = ext == '.png' ? 'png' : 'jpeg';

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'camera_upload_image.$subType',
          contentType: MediaType('image', subType),
        ));
      } else if (webImage != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          webImage,
          filename: 'web_image.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      // ✅ JWT 헤더 추가
      final token = await httpService.readToken();
      request.headers['Authorization'] = 'Bearer $token';

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        debugPrint("업로드 실패: $responseBody");
        return null;
      }
    } catch (e) {
      debugPrint("업로드 중 오류: $e");
      return null;
    }
  }
}