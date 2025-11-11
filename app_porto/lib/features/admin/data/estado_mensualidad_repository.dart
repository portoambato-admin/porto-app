import 'package:app_porto/core/network/http_client.dart';
import 'package:app_porto/core/constants/endpoints.dart';

class EstadoMensualidadRepository {
  final HttpClient _api;

  EstadoMensualidadRepository(this._api);

  Future<List<Map<String, dynamic>>> listByMensualidad(int mensualidadId) async {
    final res = await _api.get(
      Endpoints.adminEstadoMensualidad, // e.g. '/estado-mensualidad'
      query: {'mensualidadId': '$mensualidadId'}, headers: {},
    );
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> create({
    required int idMensualidad,
    required String estado, // 'pendiente' | 'pagado' | 'anulado'
  }) async {
    final res = await _api.post(
      Endpoints.adminEstadoMensualidad,
      body: {
        'id_mensualidad': idMensualidad,
        'estado': estado,
      }, headers: {},
    );
    // El backend retorna { ok: true, data: {...} }
    if (res is Map && res['data'] is Map) {
      return (res['data'] as Map).cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
