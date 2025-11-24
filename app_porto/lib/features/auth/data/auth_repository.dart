import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class AuthRepository {
  final HttpClient _http;
  const AuthRepository(this._http);

  // =========================================
  // LOGIN NORMAL
  // =========================================
  Future<({String token, Map<String, dynamic> user})> login({
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

  // =========================================
  // LOGIN CON GOOGLE (NUEVO)
  // =========================================
  Future<({String token, Map<String, dynamic> user})> loginGoogle(
      String idToken) async {
    final res = await _http.post(
      Endpoints.authLoginGoogle,
      body: {'id_token': idToken},
    );

    return _extractAuth(res);
  }

  // =========================================
  // HELPER PARA EXTRAER AUTH (MEJORADO)
  // =========================================
  ({String token, Map<String, dynamic> user}) _extractAuth(dynamic res) {
    // 1. Verificar si el backend nos mandó un mensaje de error explícito
    if (res is Map && res['message'] != null && res['token'] == null) {
      throw Exception(res['message']);
    }

    final token = res['token'];
    final usuario = (res["usuario"] ?? res["user"]) as Map?;

    if (token == null || usuario == null) {
      throw Exception("Respuesta inválida del servidor");
    }

    return (token: token, user: usuario.cast<String, dynamic>());
  }

  // =========================================
  // LOGOUT
  // =========================================
  Future<void> logout() async {
    await _http.post(Endpoints.authLogout, body: {});
  }

  // =========================================
  // PERFIL
  // =========================================
  Future<Map<String, dynamic>> me() async {
    final res = await _http.get(Endpoints.me);

    if (res is Map && res['usuario'] != null) {
      return Map<String, dynamic>.from(res['usuario']);
    }

    return Map<String, dynamic>.from(res);
  }
}