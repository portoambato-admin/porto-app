import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_env.dart';
import 'api_error.dart';

abstract class TokenProvider {
  Future<String?> getToken();
  Future<String?> refreshToken() async => null;
}

class HttpClient {
  final http.Client _client;
  final String baseUrl;
  final TokenProvider? tokenProvider;

  HttpClient({http.Client? client, String? baseUrl, this.tokenProvider})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? AppEnv.apiBase).replaceFirst(RegExp(r'\/$'), '');

  Uri _u(String path, [Map<String, String>? qp]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p').replace(queryParameters: qp);
  }

  Future<Map<String, String>> _headers({bool json = true, String? token}) async {
    final t = token ?? await tokenProvider?.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  ApiError _err(http.Response r) {
    try {
      final b = jsonDecode(r.body);
      final msg = (b is Map && (b['message'] ?? b['error']) != null)
          ? (b['message'] ?? b['error']).toString()
          : r.reasonPhrase ?? 'Error';
      return ApiError(msg, status: r.statusCode, body: b is Map ? Map<String, dynamic>.from(b) : null);
    } catch (_) {
      return ApiError('HTTP ${r.statusCode}: ${r.reasonPhrase}', status: r.statusCode);
    }
  }

  dynamic _decode(http.Response r) => r.body.isEmpty ? null : jsonDecode(r.body);

  // JSON
  Future<dynamic> get(String path, {Map<String, String>? query, required Map<String, String> headers}) async {
    final r = await _client.get(_u(path, query), headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }
   Future<Map<String, dynamic>> getWithHeaders(
    String path, {
    Map<String, String>? query, required Map<String, String> headers,
  }) async {
    final r = await _client.get(_u(path, query), headers: await _headers());
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    final data = _decode(r);
    return {
      'data': data,
      'headers': r.headers,
    };
  }

  Future<dynamic> post(String path, {Object? body, Map<String, String>? query, required Map<String, String> headers}) async {
    final r = await _client.post(_u(path, query), headers: await _headers(), body: jsonEncode(body ?? {}));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, String>? query, required Map<String, String> headers}) async {
    final r = await _client.put(_u(path, query), headers: await _headers(), body: jsonEncode(body ?? {}));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<dynamic> patch(String path, {Object? body, Map<String, String>? query}) async {
    final r = await _client.patch(_u(path, query), headers: await _headers(), body: jsonEncode(body ?? {}));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<void> delete(String path, {Map<String, String>? query, required Map<String, String> headers}) async {
    final r = await _client.delete(_u(path, query), headers: await _headers(json: false));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
  }

  // Multipart
  Future<dynamic> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'file',
    MediaType? contentType,
    Map<String, String>? fields,
  }) async {
    final req = http.MultipartRequest('POST', _u(path));
    req.headers.addAll(await _headers(json: false));
    if (fields != null) req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: contentType));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }
}
