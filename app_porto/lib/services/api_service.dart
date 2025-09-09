import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Cambia si tu host/puerto cambian
  static const String API_BASE = 'http://localhost:3000/auth';

  static Map<String, String> _jsonHeaders([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ---------- Helpers robustos ----------

  // Encuentra el primer JWT en cualquier estructura (string con 2 puntos)
  static String? _findJwt(dynamic v) {
    if (v == null) return null;
    final jwtRe = RegExp(r'^[A-Za-z0-9\-\_=]+\.[A-Za-z0-9\-\_=]+\.[A-Za-z0-9\-\_=]+$');
    if (v is String && jwtRe.hasMatch(v)) return v;
    if (v is Map) {
      for (final e in v.entries) {
        final maybe = _findJwt(e.value);
        if (maybe != null) return maybe;
      }
    } else if (v is Iterable) {
      for (final item in v) {
        final maybe = _findJwt(item);
        if (maybe != null) return maybe;
      }
    }
    return null;
    }

  // Tu caso + variantes comunes + búsqueda recursiva como fallback
  static String? _extractToken(Map<String, dynamic> body) {
    // Caso 1: { token: { token: '...' } }
    final tok = body['token'];
    if (tok is Map && tok['token'] is String) return tok['token'] as String;

    // Variantes directas
    if (body['token'] is String) return body['token'] as String;
    if (body['access_token'] is String) return body['access_token'] as String;
    if (body['jwt'] is String) return body['jwt'] as String;

    // Variantes anidadas bajo data
    final data = body['data'];
    if (data is Map && data['token'] is String) return data['token'] as String;
    if (data is Map && data['token'] is Map && data['token']['token'] is String) {
      return data['token']['token'] as String;
    }

    // Fallback: busca cualquier JWT en todo el body
    return _findJwt(body);
  }

  static Map<String, dynamic>? _extractUserMap(Map<String, dynamic> body) {
    if (body['usuario'] is Map) return Map<String, dynamic>.from(body['usuario'] as Map);
    if (body['user'] is Map) return Map<String, dynamic>.from(body['user'] as Map);
    final data = body['data'];
    if (data is Map && data['usuario'] is Map) return Map<String, dynamic>.from(data['usuario'] as Map);
    if (data is Map && data['user'] is Map) return Map<String, dynamic>.from(data['user'] as Map);
    // Fallback: intenta si vino como string JSON
    final u = body['usuario'] ?? body['user'] ?? (data is Map ? (data['usuario'] ?? data['user']) : null);
    if (u is String) {
      try {
        final parsed = jsonDecode(u);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return null;
  }

  static Never _throwInvalid(http.Response res, String where) {
    final body = res.body;
    final snippet = body.length > 700 ? '${body.substring(0, 700)}…' : body;
    throw Exception('Respuesta inválida de $where. Body: $snippet');
  }

  // -------------- LOGIN --------------
  /// Devuelve SIEMPRE strings: { 'token': String, 'usuarioJson': String }
  static Future<Map<String, String>> login({
    required String correo,
    required String contrasena,
  }) async {
    final url = Uri.parse('$API_BASE/login'); // /auth/login
    final res = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final err = jsonDecode(res.body);
        final msg = (err is Map && err['message'] != null)
            ? err['message'].toString()
            : 'Error ${res.statusCode}';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Error ${res.statusCode}');
      }
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = _extractToken(body);
    final userMap = _extractUserMap(body);
    if (token == null || userMap == null) _throwInvalid(res, 'login');

    return {'token': token, 'usuarioJson': jsonEncode(userMap)};
  }

  // -------- REGISTER + AUTO-LOGIN --------
  static Future<Map<String, String>> registerAndLogin({
    required String nombre,
    required String correo,
    required String contrasena,
    int? idRol,
  }) async {
    final url = Uri.parse('$API_BASE/register'); // /auth/register
    final res = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        if (idRol != null) 'id_rol': idRol,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final err = jsonDecode(res.body);
        final msg = (err is Map && err['message'] != null)
            ? err['message'].toString()
            : 'No se pudo registrar';
        throw Exception(msg);
      } catch (_) {
        throw Exception('No se pudo registrar (${res.statusCode})');
      }
    }

    // Autologin con las mismas credenciales
    return login(correo: correo, contrasena: contrasena);
  }

  // -------------- LOGOUT --------------
  static Future<void> logout(String token) async {
    final url = Uri.parse('$API_BASE/logout'); // /auth/logout
    try {
      await http.post(url, headers: _jsonHeaders(token));
    } catch (_) {/* ignore */}
  }
}
