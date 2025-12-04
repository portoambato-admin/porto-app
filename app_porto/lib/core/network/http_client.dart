import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../services/session_token_provider.dart';
import 'api_error.dart';

class HttpClient {
  final http.Client _client;
  final String baseUrl;

  HttpClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? AppEnv.apiBase).replaceFirst(RegExp(r'\/$'), '');

  Uri _u(String path, [Map<String, String>? qp]) {
    final isAbs = path.startsWith('http://') || path.startsWith('https://');
    final uri = isAbs
        ? Uri.parse(path).replace(queryParameters: qp)
        : Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}')
            .replace(queryParameters: qp);
    return uri;
  }

  Future<String?> _resolveToken() async {
    final token = await SessionTokenProvider.instance.readToken();
    
    return token;
  }

  Future<Map<String, String>> _headers({
    bool json = true,
    String? overrideToken,
    Map<String, String>? extra,
  }) async {
    final t = overrideToken ?? await _resolveToken();
    final base = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
    if (extra == null || extra.isEmpty) return base;

    final ex = Map<String, String>.from(extra);
    if (ex['Authorization'] != null && ex['Authorization']!.trim().isEmpty) {
      ex.remove('Authorization');
    }
    return {...base, ...ex};
  }

  dynamic _checkResponse(http.Response r) {
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw UnauthorizedException("Sesión expirada");
    }    if (r.statusCode < 200 || r.statusCode >= 300) {

      throw _err(r);
    }
    return _decode(r);
  }

  ApiError _err(http.Response r) {
    try {
      final b = r.body.isEmpty ? null : jsonDecode(r.body);
      final msg = (b is Map && (b['message'] ?? b['error']) != null)
          ? (b['message'] ?? b['error']).toString()
          : r.reasonPhrase ?? 'Error desconocido';
      
      return ApiError(
        msg,
        status: r.statusCode,
        body: b is Map ? Map<String, dynamic>.from(b) : null,
      );
    } catch (_) {
      return ApiError('HTTP ${r.statusCode}: ${r.reasonPhrase}', status: r.statusCode);
    }
  }

  dynamic _decode(http.Response r) {
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      try {
        return jsonDecode(r.body);
      } catch (e) {
        return r.body; 
      }
    }
  }

  dynamic _encodeJsonBodyOnce(dynamic body) {
    if (body == null) return null;
    if (body is Map || body is List) return jsonEncode(body);
    if (body is String) {
      try {
        final parsed = json.decode(body);
        if (parsed is Map || parsed is List) return jsonEncode(parsed);
        return body;
      } catch (_) {
        return body;
      }
    }
    return jsonEncode(body);
  }

  Future<http.Response> _sendOnce(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool json = true,
  }) async {
    try {
      final uri = _u(path, query);
      final h = await _headers(json: json, extra: headers);


      switch (method) {
        case 'GET':
          return await _client.get(uri, headers: h);
        case 'POST':
          return await _client.post(
            uri,
            headers: h,
            body: json ? _encodeJsonBodyOnce(body) : body,
          );
        case 'PUT':
          return await _client.put(
            uri,
            headers: h,
            body: json ? _encodeJsonBodyOnce(body) : body,
          );
        case 'PATCH':
          return await _client.patch(
            uri,
            headers: h,
            body: json ? _encodeJsonBodyOnce(body) : body,
          );
        case 'DELETE':
          return await _client.delete(uri, headers: h);
        default:
          throw ApiError('Método HTTP no soportado: $method');
      }
    } on SocketException {
      throw ApiError('Sin conexión a internet.');
    }
  }

  // --- MÉTODOS PÚBLICOS ---

  Future<dynamic> get(String path, {
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('GET', path, query: query, headers: headers, json: true);
    return _checkResponse(r);
  }

  Future<Map<String, dynamic>> getWithHeaders(String path, {
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('GET', path, query: query, headers: headers, json: true);
    if (r.statusCode == 401 || r.statusCode == 403) throw UnauthorizedException("Sesión expirada");
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    
    return {'data': _decode(r), 'headers': r.headers};
  }

  Future<dynamic> post(String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('POST', path, body: body, query: query, headers: headers, json: true);
    return _checkResponse(r);
  }

  Future<dynamic> put(String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('PUT', path, body: body, query: query, headers: headers, json: true);
    return _checkResponse(r);
  }

  Future<dynamic> patch(String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('PATCH', path, body: body, query: query, headers: headers, json: true);
    return _checkResponse(r);
  }

  Future<void> delete(String path, {
    Map<String, String>? query,
    Map<String, String>? headers
  }) async {
    final r = await _sendOnce('DELETE', path, query: query, headers: headers, json: false);
    _checkResponse(r);
  }

  Future<dynamic> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'file',
    MediaType? contentType,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _u(path));
      req.headers.addAll(await _headers(json: false, extra: headers));
      
      if (fields != null) req.fields.addAll(fields);
      
      req.files.add(http.MultipartFile.fromBytes(
        field, 
        bytes, 
        filename: filename, 
        contentType: contentType
      ));
      
      final streamed = await req.send();
      final r = await http.Response.fromStream(streamed);
      
      return _checkResponse(r);
    } on SocketException {
      throw ApiError('Sin conexión a internet.');
    }
  }
}