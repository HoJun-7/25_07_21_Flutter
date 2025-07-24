import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  HttpService({required this.baseUrl});

  /// GET 요청 (헤더 자동 포함)
  Future<http.Response> get(String path, {Map<String, String>? extraHeaders}) async {
    final token = await _storage.read(key: 'access_token');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    return await http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  /// POST 요청 (헤더 자동 포함)
  Future<http.Response> post(String path, Map<String, dynamic> body, {Map<String, String>? extraHeaders}) async {
    final token = await _storage.read(key: 'access_token');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    return await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /// PUT 요청 (헤더 자동 포함)
  Future<http.Response> put(String path, Map<String, dynamic> body, {Map<String, String>? extraHeaders}) async {
    final token = await _storage.read(key: 'access_token');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    return await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  /// DELETE 요청 (헤더 자동 포함)
  Future<http.Response> delete(String path, {Map<String, dynamic>? body, Map<String, String>? extraHeaders}) async {
    final token = await _storage.read(key: 'access_token');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };

    return await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// JWT 토큰 직접 읽기
  Future<String?> readToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// ✅ JWT 포함 이미지 업로드 요청 (멀티파트)
  Future<http.StreamedResponse> uploadImageWithToken({
    required String userId,
    required Uint8List imageData,
    required String filename,
    String? yoloResultsJson,
  }) async {
    final token = await _storage.read(key: 'access_token');
    final uri = Uri.parse('$baseUrl/upload_image');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['user_id'] = userId;

    if (yoloResultsJson != null) {
      request.fields['yolo_results_json'] = yoloResultsJson;
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageData,
      filename: filename,
      contentType: MediaType('image', 'png'), // 확장자 따라 바꿔도 됨
    ));

    return await request.send();
  }
}
