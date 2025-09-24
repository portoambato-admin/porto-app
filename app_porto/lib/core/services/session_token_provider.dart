import '../network/http_client.dart';
import 'session.dart';

class SessionTokenProvider implements TokenProvider {
  @override
  Future<String?> getToken() => Session.getToken();

  @override
  Future<String?> refreshToken() async {
    // Si tienes refresh real en Session, usa:
    // return Session.refreshToken();

    // Por ahora no hay refresh → devuelve null para que el cliente no reintente.
    return null;
  }
}
