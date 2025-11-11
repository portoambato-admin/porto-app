// lib/core/network/http_client.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

  HttpClient({
    http.Client? client,
    String? baseUrl,
    this.tokenProvider,
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
    String? t = await tokenProvider?.getToken();
    if ((t == null || t.isEmpty) && kIsWeb) {
      final s = html.window.localStorage;
      t = s['auth_token'] ??
          s['porto_token'] ??
          s['token'] ??
          s['jwt'] ??
          s['access_token'];
    }
    return (t != null && t.isNotEmpty) ? t : null;
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
    // si viene 'Authorization': '' lo quitamos para no romper el header
    if (ex['Authorization'] != null && ex['Authorization']!.trim().isEmpty) {
      ex.remove('Authorization');
    }
    return {...base, ...ex};
  }

  ApiError _err(http.Response r) {
    try {
      final b = r.body.isEmpty ? null : jsonDecode(r.body);
      final msg = (b is Map && (b['message'] ?? b['error']) != null)
          ? (b['message'] ?? b['error']).toString()
          : r.reasonPhrase ?? 'Error';
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
      return jsonDecode(r.body);
    } catch (_) {
      return r.body; // por si el backend respondió texto plano
    }
  }

  // --- evita doble jsonEncode ---
  dynamic _encodeJsonBodyOnce(dynamic body) {
    if (body == null) return null;
    if (body is Map || body is List) return jsonEncode(body);
    if (body is String) {
      try {
        final parsed = json.decode(body);
        if (parsed is Map || parsed is List) {
          // venía como string JSON; normalizamos a un único encode
          return jsonEncode(parsed);
        }
        return body; // string plano
      } catch (_) {
        return body; // string plano
      }
    }
    // tipos primitivos u otros serializables
    return jsonEncode(body);
  }

  Future<http.Response> _sendOnce(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool json = true,
    String? forcedToken,
  }) async {
    final uri = _u(path, query);
    final h = await _headers(json: json, extra: headers, overrideToken: forcedToken);

    switch (method) {
      case 'GET':
        return _client.get(uri, headers: h);
      case 'POST':
        return _client.post(
          uri,
          headers: h,
          body: json ? _encodeJsonBodyOnce(body) : body,
        );
      case 'PUT':
        return _client.put(
          uri,
          headers: h,
          body: json ? _encodeJsonBodyOnce(body) : body,
        );
      case 'PATCH':
        return _client.patch(
          uri,
          headers: h,
          body: json ? _encodeJsonBodyOnce(body) : body,
        );
      case 'DELETE':
        return _client.delete(uri, headers: h);
      default:
        throw ApiError('Método HTTP no soportado: $method');
    }
  }

  Future<http.Response> _sendWith401Retry(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool json = true,
  }) async {
    var r = await _sendOnce(method, path, body: body, query: query, headers: headers, json: json);

    if (r.statusCode == 401 && tokenProvider != null) {
      final newTok = await tokenProvider!.refreshToken();
      if (newTok != null && newTok.isNotEmpty) {
        r = await _sendOnce(
          method,
          path,
          body: body,
          query: query,
          headers: headers,
          json: json,
          forcedToken: newTok,
        );
      }
    }
    return r;
  }

  // ---------- JSON ----------
  Future<dynamic> get(String path, {Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('GET', path, query: query, headers: headers, json: true);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<Map<String, dynamic>> getWithHeaders(String path,
      {Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('GET', path, query: query, headers: headers, json: true);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return {'data': _decode(r), 'headers': r.headers};
  }

  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('POST', path, body: body, query: query, headers: headers, json: true);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<dynamic> put(String path,
      {Object? body, Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('PUT', path, body: body, query: query, headers: headers, json: true);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<dynamic> patch(String path,
      {Object? body, Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('PATCH', path, body: body, query: query, headers: headers, json: true);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }

  Future<void> delete(String path, {Map<String, String>? query, Map<String, String>? headers}) async {
    final r = await _sendWith401Retry('DELETE', path, query: query, headers: headers, json: false);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
  }

  // ---------- Multipart ----------
  Future<dynamic> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    String field = 'file',
    MediaType? contentType,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final req = http.MultipartRequest('POST', _u(path));
    req.headers.addAll(await _headers(json: false, extra: headers));
    if (fields != null) req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename, contentType: contentType));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode < 200 || r.statusCode >= 300) throw _err(r);
    return _decode(r);
  }
}
