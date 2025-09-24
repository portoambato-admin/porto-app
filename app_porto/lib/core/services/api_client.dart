import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

abstract class TokenProvider {
  Future<String?> getToken();
  Future<String?> refreshToken(); // opcional
}

class HttpError implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic>? body;
  HttpError(this.status, this.message, {this.body});
  @override
  String toString() => 'HttpError($status): $message';
}

class ApiClient {
  final http.Client _client;
  final TokenProvider? _tokenProvider;

  ApiClient({http.Client? client, TokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  Map<String, String> _jsonHeaders({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Exception _errorFromResponse(http.Response r) {
    try {
      final map = jsonDecode(r.body);
      final msg = (map is Map && (map['message'] ?? map['error']) != null)
          ? (map['message'] ?? map['error']).toString()
          : r.reasonPhrase ?? 'Error';
      return HttpError(r.statusCode, msg, body: map is Map ? Map<String, dynamic>.from(map) : null);
    } catch (_) {
      return HttpError(r.statusCode, r.reasonPhrase ?? 'HTTP ${r.statusCode}');
    }
  }

  Future<http.Response> _sendWithAuth(
    Future<http.Response> Function(String? token) fn, {
    bool retryOn401 = true,
  }) async {
    final token = await _tokenProvider?.getToken();
    var r = await fn(token);

    if (r.statusCode == 401 && retryOn401 && _tokenProvider != null) {
      final newTok = await _tokenProvider.refreshToken();
      if (newTok != null) {
        r = await fn(newTok); // reintenta una vez
      }
    }
    return r;
  }

  // -------- JSON --------
  Future<Map<String, dynamic>> getJson(Uri url) async {
    final r = await _sendWithAuth((tok) => _client.get(url, headers: _jsonHeaders(token: tok)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }

  Future<List<dynamic>> getList(Uri url) async {
    final r = await _sendWithAuth((tok) => _client.get(url, headers: _jsonHeaders(token: tok)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is List ? body : [];
  }

  Future<Map<String, dynamic>> postJson(Uri url, Map<String, dynamic> data) async {
    final r = await _sendWithAuth((tok) => _client.post(url, headers: _jsonHeaders(token: tok), body: jsonEncode(data)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }

  Future<Map<String, dynamic>> putJson(Uri url, Map<String, dynamic> data) async {
    final r = await _sendWithAuth((tok) => _client.put(url, headers: _jsonHeaders(token: tok), body: jsonEncode(data)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }

  Future<Map<String, dynamic>> patchJson(Uri url, Map<String, dynamic> data) async {
    final r = await _sendWithAuth((tok) => _client.patch(url, headers: _jsonHeaders(token: tok), body: jsonEncode(data)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }

  Future<void> delete(Uri url) async {
    final r = await _sendWithAuth((tok) => _client.delete(url, headers: _jsonHeaders(token: tok)));
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
  }

  // -------- Multipart --------
  Future<Map<String, dynamic>> uploadBytes(
    Uri url, {
    required Uint8List bytes,
    required String field,
    required String filename,
    MediaType? contentType,
  }) async {
    final req = http.MultipartRequest('POST', url);
    final tok = await _tokenProvider?.getToken();
    if (tok != null) req.headers['Authorization'] = 'Bearer $tok';

    req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: contentType));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);

    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    final body = jsonDecode(r.body);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }
}
