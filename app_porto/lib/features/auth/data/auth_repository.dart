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

  // ✅ Helper para desenvolver { usuario: {...} } de forma consistente
  Map<String, dynamic> _unwrapUser(dynamic payload) {
    if (payload is Usuario) {
      return payload.toJson(); // Si ya es un Usuario, convertir a JSON
    }
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
  Future<AuthResponse> loginGoogle(String idToken) async {
    final res = await _http.post(
      Endpoints.authLoginGoogle,
      body: {'id_token': idToken},
    );

    return _extractAuth(res);
  }

  // Helper para procesar la respuesta del backend
  AuthResponse _extractAuth(dynamic res) {
    if (res is Map && (res['error'] != null || (res['message'] != null && res['token'] == null))) {
      throw Exception(res['error'] ?? res['message']);
    }

    final token = res['token'] as String?;
    final userData = res['usuario'] ?? res['user'] ?? res['data']?['user'];

    if (token == null || userData == null) {
      throw Exception("Respuesta inválida del servidor.");
    }

    // ✅ Asegurar que userData sea un Map antes de crear el Usuario
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
      // Ignoramos error en logout, lo prioritario es limpiar la sesión local
    }
  }

  // PERFIL (ME)
  Future<Usuario> me() async {
    final res = await _http.get(Endpoints.me);
    
    // ✅ Desenvolver correctamente
    final userMap = _unwrapUser(res);
    
    return Usuario.fromJson(userMap);
  }
}