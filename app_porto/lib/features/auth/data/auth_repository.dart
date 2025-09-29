import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class AuthRepository {
  final HttpClient _http;
  const AuthRepository(this._http);

  Future<({String token, Map<String, dynamic> user})> login({
    required String correo,
    required String contrasena,
  }) async {
    final res = await _http.post(Endpoints.authLogin, body: {
      'correo': correo,
      'contrasena': contrasena,
    }, headers: {});

    String? _findJwt(dynamic v) {
      final re = RegExp(r'^[A-Za-z0-9\\-\\_=]+\\.[A-Za-z0-9\\-\\_=]+\\.[A-Za-z0-9\\-\\_=]+$');
      if (v is String && re.hasMatch(v)) return v;
      if (v is Map) for (final e in v.entries) { final t = _findJwt(e.value); if (t != null) return t; }
      if (v is Iterable) for (final e in v) { final t = _findJwt(e); if (t != null) return t; }
      return null;
    }

    String? token;
    Map<String, dynamic>? user;

    if (res is Map) {
      token = (res['token'] ?? res['access_token']) as String?;
      user  = (res['usuario'] ?? res['user']) as Map<String, dynamic>?;

      final data = res['data'];
      if (token == null && data is Map) {
        token ??= (data['token'] is String)
            ? data['token'] as String
            : (data['token'] is Map && data['token']['token'] is String)
                ? data['token']['token'] as String
                : null;

        user ??= (data['usuario'] ?? data['user']) as Map<String, dynamic>?;
      }
      token ??= _findJwt(res);
    }

    if (token == null || user == null) {
      throw Exception('Respuesta inválida de login');
    }
    return (token: token, user: Map<String, dynamic>.from(user));
  }

  Future<void> logout() async {
    await _http.post(Endpoints.authLogout, body: const {}, headers: {});
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _http.get(Endpoints.me, headers: {});
    if (res is Map && res['usuario'] is Map) {
      return Map<String, dynamic>.from(res['usuario'] as Map);
    }
    return Map<String, dynamic>.from(res as Map);
  }
}
