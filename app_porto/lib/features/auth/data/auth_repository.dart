import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../features/admin/models/usuario_model.dart';

class AuthResponse {
  final String token;
  final Usuario usuario; // Cambiado de User a Usuario
  AuthResponse({required this.token, required this.usuario});
}

class AuthRepository {
  final HttpClient _http;
  const AuthRepository(this._http);

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

    return AuthResponse(
      token: token,
      // Usamos tu clase Usuario
      usuario: Usuario.fromJson(Map<String, dynamic>.from(userData)),
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
    
    final userData = (res is Map && res['usuario'] != null) 
        ? res['usuario'] 
        : res;

    return Usuario.fromJson(Map<String, dynamic>.from(userData));
  }
}