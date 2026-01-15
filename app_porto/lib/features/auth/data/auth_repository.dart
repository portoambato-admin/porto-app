import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../features/admin/models/usuario_model.dart';

class AuthResponse {
  final String token;
  final Usuario usuario;
  AuthResponse({required this.token, required this.usuario});
}

class AuthRepository {
  final HttpClient _http;
  const AuthRepository(this._http);

  // Helper para desenvolver { usuario: {...} } de forma consistente
  Map<String, dynamic> _unwrapUser(dynamic payload) {
    if (payload is Usuario) return payload.toJson();

    if (payload is Map && payload['usuario'] is Map) {
      return Map<String, dynamic>.from(payload['usuario'] as Map);
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw Exception('Formato de usuario inválido');
  }

  // LOGIN NORMAL
  Future<AuthResponse> login({
    required String correo,
    required String contrasena,
  }) async {
    final res = await _http.post(
      Endpoints.authLogin,
      body: {
        'correo': correo,
        'contrasena': contrasena,
      },
    );

    return _extractAuth(res);
  }

  // LOGIN CON GOOGLE
  // ✅ En producción: permite enviar aceptación si el usuario es nuevo
  Future<AuthResponse> loginGoogle(
    String idToken, {
    bool? aceptaPoliticas,
    bool? aceptaPrivacidad,
    String? versionPoliticas,
  }) async {
    final body = <String, dynamic>{'id_token': idToken};

    // Solo enviamos estos campos si nos los pasan desde UI
    if (aceptaPoliticas != null) body['acepta_politicas'] = aceptaPoliticas;
    if (aceptaPrivacidad != null) body['acepta_privacidad'] = aceptaPrivacidad;
    if (versionPoliticas != null && versionPoliticas.trim().isNotEmpty) {
      body['version_politicas'] = versionPoliticas.trim();
    }

    final res = await _http.post(
      Endpoints.authLoginGoogle,
      body: body,
    );

    return _extractAuth(res);
  }

  // Helper para procesar la respuesta del backend
  AuthResponse _extractAuth(dynamic res) {
    if (res is Map &&
        (res['error'] != null ||
            (res['message'] != null && res['token'] == null))) {
      throw Exception(res['error'] ?? res['message']);
    }

    final token = res['token'] as String?;
    final userData = res['usuario'] ?? res['user'] ?? res['data']?['user'];

    if (token == null || userData == null) {
      throw Exception("Respuesta inválida del servidor.");
    }

    final userMap = _unwrapUser(userData);

    return AuthResponse(
      token: token,
      usuario: Usuario.fromJson(userMap),
    );
  }

  // LOGOUT
  Future<void> logout() async {
    try {
      await _http.post(Endpoints.authLogout, body: {});
    } catch (_) {
      // Ignorar error en logout: lo prioritario es limpiar la sesión local
    }
  }

  // PERFIL (ME)
  Future<Usuario> me() async {
    final res = await _http.get(Endpoints.me);
    final userMap = _unwrapUser(res);
    return Usuario.fromJson(userMap);
  }
}
