import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class NotificacionesRepository {
  final HttpClient _http;
  NotificacionesRepository(this._http);

  Future<List<Map<String, dynamic>>> listar({
    bool soloNoLeidas = false,
    int limit = 50,
    int offset = 0,
    int? idUsuarioAdmin,
  }) async {
    final qp = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (soloNoLeidas) 'solo_no_leidas': '1',
      if (idUsuarioAdmin != null) 'id_usuario': '$idUsuarioAdmin',
    };

    final data = await _http.get(Endpoints.notificaciones, query: qp);
    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Future<int> unreadCount() async {
    final data = await _http.get(Endpoints.notificacionesUnreadCount);
    if (data is Map && data['unread'] != null) {
      final n = int.tryParse('${data['unread']}') ?? 0;
      return n;
    }
    return 0;
  }

  Future<Map<String, dynamic>> marcarLeida(int idNotificacion) async {
    final data = await _http.patch(Endpoints.notificacionMarcarLeida(idNotificacion));
    return (data is Map)
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
  }

  Future<int> marcarTodasLeidas() async {
    final data = await _http.patch(Endpoints.notificacionesMarcarTodas);
    if (data is Map && data['updated'] != null) {
      return int.tryParse('${data['updated']}') ?? 0;
    }
    return 0;
  }

  // Admin
  Future<Map<String, dynamic>> crearAdmin({
    required int idUsuario,
    required String mensaje,
  }) async {
    final body = {'id_usuario': idUsuario, 'mensaje': mensaje};
    final data = await _http.post(Endpoints.notificaciones, body: body);
    return (data is Map)
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
  }

  Future<void> eliminarAdmin(int idNotificacion) async {
    await _http.delete(Endpoints.notificacionEliminar(idNotificacion));
  }
}
