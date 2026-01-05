import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiService {
  /// Base del backend (SIN /auth al final)
  static const String API_BASE = String.fromEnvironment(
    'API_BASE',
    //defaultValue: 'https://backend-production-cb2d.up.railway.app',
    defaultValue: 'http://localhost:3000',
  );

  // ---------- Headers ----------
  static Map<String, String> _jsonHeaders({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
      };

  // ---------- Helpers ----------
  static Exception _errorFromResponse(http.Response r) {
    try {
      final map = jsonDecode(r.body);
      final msg = (map is Map && (map['message'] ?? map['error']) != null)
          ? (map['message'] ?? map['error']).toString()
          : r.reasonPhrase ?? 'Error';
      return Exception('$msg (HTTP ${r.statusCode})');
    } catch (_) {
      return Exception('Error HTTP ${r.statusCode}: ${r.reasonPhrase}');
    }
  }

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

  static String? _extractToken(Map<String, dynamic> body) {
    final tok = body['token'];
    if (tok is Map && tok['token'] is String) return tok['token'] as String;
    if (body['token'] is String) return body['token'] as String;
    if (body['access_token'] is String) return body['access_token'] as String;
    if (body['jwt'] is String) return body['jwt'] as String;

    final data = body['data'];
    if (data is Map && data['token'] is String) return data['token'] as String;
    if (data is Map && data['token'] is Map && data['token']['token'] is String) {
      return data['token']['token'] as String;
    }
    return _findJwt(body);
  }

  static Map<String, dynamic>? _extractUserMap(Map<String, dynamic> body) {
    if (body['usuario'] is Map) return Map<String, dynamic>.from(body['usuario'] as Map);
    if (body['user'] is Map) return Map<String, dynamic>.from(body['user'] as Map);
    final data = body['data'];
    if (data is Map && data['usuario'] is Map) return Map<String, dynamic>.from(data['usuario'] as Map);
    if (data is Map && data['user'] is Map) return Map<String, dynamic>.from(data['user'] as Map);

    final u = body['usuario'] ?? body['user'] ?? (data is Map ? (data['usuario'] ?? data['user']) : null);
    if (u is String) {
      try {
        final parsed = jsonDecode(u);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return null;
  }

  // =========================================================
  //                        AUTH
  // =========================================================
  static Uri _auth(String path) => Uri.parse('$API_BASE/auth$path');

  /// Devuelve SIEMPRE: {'token': String, 'usuarioJson': String}
  static Future<Map<String, String>> login({
    required String correo,
    required String contrasena,
  }) async {
    final r = await http.post(
      _auth('/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
    );
    if (r.statusCode != 200) throw _errorFromResponse(r);

    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final token = _extractToken(body);
    final userMap = _extractUserMap(body);
    if (token == null || userMap == null) {
      throw Exception('Respuesta inválida del login');
    }
    return {'token': token, 'usuarioJson': jsonEncode(userMap)};
  }

  static Future<Map<String, String>> registerAndLogin({
    required String nombre,
    required String correo,
    required String contrasena,
    int? idRol,
  }) async {
    final r = await http.post(
      _auth('/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        if (idRol != null) 'id_rol': idRol,
      }),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _errorFromResponse(r);
    // Auto-login
    return login(correo: correo, contrasena: contrasena);
  }

  static Future<void> logout(String token) async {
    final r = await http.post(_auth('/logout'), headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }

  // =========================================================
  //                        PERFIL /me
  // =========================================================
  static Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse('$API_BASE/me');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final map = jsonDecode(r.body);
    if (map is Map && map['usuario'] is Map) {
      return Map<String, dynamic>.from(map['usuario']);
    }
    return Map<String, dynamic>.from(map as Map);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nombre,
    String? avatarUrl,
    String? avatarPublicId,
  }) async {
    final url = Uri.parse('$API_BASE/me');
    final body = <String, dynamic>{
      'nombre': nombre,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (avatarPublicId != null) 'avatar_public_id': avatarPublicId,
    };
    final r = await http.patch(url, headers: _jsonHeaders(token: token), body: jsonEncode(body));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final map = jsonDecode(r.body);
    if (map is Map && map['usuario'] is Map) {
      return Map<String, dynamic>.from(map['usuario']);
    }
    return Map<String, dynamic>.from(map as Map);
  }

  static Future<String> uploadAvatar({
    required String token,
    required Uint8List bytes,
    required String filename,
  }) async {
    final url = Uri.parse('$API_BASE/me/avatar');

    MediaType? _typeFor(String name) {
      final ext = name.split('.').last.toLowerCase();
      switch (ext) {
        case 'png':
          return MediaType('image', 'png');
        case 'jpg':
        case 'jpeg':
          return MediaType('image', 'jpeg');
        case 'webp':
          return MediaType('image', 'webp');
        default:
          return null;
      }
    }

    final req = http.MultipartRequest('POST', url);
    req.headers.addAll(_authHeaders(token));
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _typeFor(filename),
      ),
    );

    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode != 201 && r.statusCode != 200) throw _errorFromResponse(r);

    final map = jsonDecode(r.body);
    final urlStr = (map['avatar_url'] ?? map['url'] ?? map['avatar']) as String?;
    if (urlStr == null) throw Exception('Respuesta inválida al subir avatar');
    return urlStr;
  }

  static Future<void> changePassword({
    required String token,
    required String actual,
    required String nueva,
  }) async {
    final url = Uri.parse('$API_BASE/me/password');
    final r = await http.patch(
      url,
      headers: _jsonHeaders(token: token),
      body: jsonEncode({'contrasena_actual': actual, 'nueva_contrasena': nueva}),
    );
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }

  // =========================================================
  //                    USUARIOS (solo ADMIN)
  // =========================================================

  // ---- Listas rápidas (sin paginación)
  static Future<List<Map<String, dynamic>>> getUsuariosTodos(String token) async {
    final url = Uri.parse('$API_BASE/usuarios');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> getUsuariosActivos(String token) async {
    final url = Uri.parse('$API_BASE/usuarios/activos');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> getUsuariosInactivos(String token) async {
    final url = Uri.parse('$API_BASE/usuarios/inactivos');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  /// ✅ PUT /usuarios/:id — actualización parcial (solo envía las claves NO nulas)
  static Future<Map<String, dynamic>> putUsuario({
    required String token,
    required int idUsuario,
    String? nombre,
    String? correo,
    int? idRol,
    bool? activo,
    String? avatarUrl,
    bool? verificado,
    int? idAcademia,
  }) async {
    final url = Uri.parse('$API_BASE/usuarios/$idUsuario');
    final body = <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (correo != null) 'correo': correo,
      if (idRol != null) 'id_rol': idRol,
      if (activo != null) 'activo': activo,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (verificado != null) 'verificado': verificado,
      if (idAcademia != null) 'id_academia': idAcademia,
    };
    final r = await http.put(url, headers: _jsonHeaders(token: token), body: jsonEncode(body));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  static Future<void> deleteUsuario({
    required String token,
    required int idUsuario,
  }) async {
    final url = Uri.parse('$API_BASE/usuarios/$idUsuario');
    final r = await http.delete(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }

  static Future<void> activarUsuario({
    required String token,
    required int idUsuario,
  }) async {
    final url = Uri.parse('$API_BASE/usuarios/$idUsuario/activar');
    final r = await http.post(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }

  // ---------- USUARIOS paginados ----------
  static Future<Map<String, dynamic>> _usersPaged(
    String token, {
    required String path, // "", "/activos", "/inactivos"
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'creado_en', // id_usuario|nombre|correo|creado_en
    String order = 'desc',     // asc|desc
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'sort': sort,
      'order': order,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    final url = Uri.parse('$API_BASE/usuarios$path').replace(queryParameters: qp);
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);

    final list = jsonDecode(r.body);
    final items = (list is List)
        ? list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final totalStr = r.headers['x-total-count'];
    final total = int.tryParse(totalStr ?? '') ?? items.length;

    return {'items': items, 'total': total, 'page': page, 'pageSize': pageSize};
  }

  static Future<Map<String, dynamic>> getUsuariosTodosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) {
    return _usersPaged(token, path: '', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  static Future<Map<String, dynamic>> getUsuariosActivosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) {
    return _usersPaged(token, path: '/activos', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  static Future<Map<String, dynamic>> getUsuariosInactivosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) {
    return _usersPaged(token, path: '/inactivos', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  /// 🔎 Buscar usuarios (GET /usuarios/buscar)
  static Future<List<Map<String, dynamic>>> searchUsuarios(
    String token, {
    required String q,
    bool activosOnly = true,
    int? rol, // 1=admin,2=profesor,3=padre,4=usuario
    int limit = 10,
  }) async {
    final qp = <String, String>{
      'q': q,
      'limit': '$limit',
      if (activosOnly) 'activosOnly': 'true',
      if (rol != null) 'rol': '$rol',
    };
    final url = Uri.parse('$API_BASE/usuarios/buscar').replace(queryParameters: qp);
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  /// 🔎 Buscar usuarios con rol=2 (profesores) — usa /usuarios/buscar
  static Future<List<Map<String, dynamic>>> searchUsuariosProfesores(
    String token, {
    required String q,
    int limit = 10,
  }) async {
    return searchUsuarios(token, q: q, activosOnly: true, rol: 2, limit: limit);
  }

  // =========================================================
  //                    PROFESORES (solo ADMIN)
  // =========================================================

  // ---- Compat: SIN paginación ----
  static Future<List<Map<String, dynamic>>> getProfesoresTodos(String token) async {
    final url = Uri.parse('$API_BASE/profesores');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> getProfesoresActivos(String token) async {
    final url = Uri.parse('$API_BASE/profesores/activos');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> getProfesoresInactivos(String token) async {
    final url = Uri.parse('$API_BASE/profesores/inactivos');
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    final list = jsonDecode(r.body);
    if (list is List) {
      return list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  // ---- Paginados ----
  static Future<Map<String, dynamic>> _profesoresPaged(
    String token, {
    required String path, // "", "/activos", "/inactivos"
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'id_profesor', // id_profesor|especialidad|nombre_usuario|id_usuario
    String order = 'desc',       // asc|desc
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'sort': sort,
      'order': order,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };
    final url = Uri.parse('$API_BASE/profesores$path').replace(queryParameters: qp);
    final r = await http.get(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);

    final list = jsonDecode(r.body);
    final items = (list is List)
        ? list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final totalStr = r.headers['x-total-count'];
    final total = int.tryParse(totalStr ?? '') ?? items.length;

    return {'items': items, 'total': total, 'page': page, 'pageSize': pageSize};
  }

  static Future<Map<String, dynamic>> getProfesoresTodosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'id_profesor',
    String order = 'desc',
  }) {
    return _profesoresPaged(token, path: '', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  static Future<Map<String, dynamic>> getProfesoresActivosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'id_profesor',
    String order = 'desc',
  }) {
    return _profesoresPaged(token, path: '/activos', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  static Future<Map<String, dynamic>> getProfesoresInactivosPaged(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'id_profesor',
    String order = 'desc',
  }) {
    return _profesoresPaged(token, path: '/inactivos', page: page, pageSize: pageSize, q: q, sort: sort, order: order);
  }

  /// POST /profesores — idempotente por id_usuario
  static Future<Map<String, dynamic>> postProfesor({
    required String token,
    required int idUsuario,
    String? especialidad,
    String? telefono,
    String? direccion,
    bool? activo,
  }) async {
    final url = Uri.parse('$API_BASE/profesores');
    final body = {
      'id_usuario': idUsuario,
      if (especialidad != null) 'especialidad': especialidad,
      if (telefono != null) 'telefono': telefono,
      if (direccion != null) 'direccion': direccion,
      if (activo != null) 'activo': activo,
    };
    final r = await http.post(url, headers: _jsonHeaders(token: token), body: jsonEncode(body));
    if (r.statusCode != 201 && r.statusCode != 200) throw _errorFromResponse(r);
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  /// PUT /profesores/:id
  static Future<Map<String, dynamic>> putProfesor({
    required String token,
    required int idProfesor,
    String? especialidad,
    String? telefono,
    String? direccion,
    bool? activo,
  }) async {
    final url = Uri.parse('$API_BASE/profesores/$idProfesor');
    final body = <String, dynamic>{
      if (especialidad != null) 'especialidad': especialidad,
      if (telefono != null) 'telefono': telefono,
      if (direccion != null) 'direccion': direccion,
      if (activo != null) 'activo': activo,
    };
    final r = await http.put(url, headers: _jsonHeaders(token: token), body: jsonEncode(body));
    if (r.statusCode != 200) throw _errorFromResponse(r);
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  /// DELETE /profesores/:id (soft)
  static Future<void> deleteProfesor({
    required String token,
    required int idProfesor,
  }) async {
    final url = Uri.parse('$API_BASE/profesores/$idProfesor');
    final r = await http.delete(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }

  /// POST /profesores/:id/activar
  static Future<void> activarProfesor({
    required String token,
    required int idProfesor,
  }) async {
    final url = Uri.parse('$API_BASE/profesores/$idProfesor/activar');
    final r = await http.post(url, headers: _authHeaders(token));
    if (r.statusCode != 200) throw _errorFromResponse(r);
  }
}
