import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// PUT 요청
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

  /// DELETE 요청
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
  Future<String?> readToken() async {
    return await _storage.read(key: 'access_token');
  }
}
