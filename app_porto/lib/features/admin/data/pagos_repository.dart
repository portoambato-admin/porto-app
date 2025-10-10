import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class PagosRepository {
  final HttpClient _http;
  PagosRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _from(Map<String, dynamic> j) => {
    'id': j['id_pago'],
    'idMensualidad': j['id_mensualidad'],
    'fecha': j['fecha_pago'],
    'monto': (j['monto_pagado'] is num)
        ? (j['monto_pagado'] as num).toDouble()
        : double.tryParse('${j['monto_pagado']}'),
    'metodo': j['metodo_pago'],
    'observaciones': j['observaciones'],
    'activo': j['activo'],
  };

  Future<Map<String, dynamic>> crear({
    required int idMensualidad,
    required double monto,
    String metodo = 'efectivo',
    String? observaciones,
  }) async {
    final res = await _http.post(
      Endpoints.pagos,
      headers: _h,
      body: {
        'id_mensualidad': idMensualidad,
        'monto_pagado': monto,
        'metodo_pago': metodo,
        if (observaciones != null && observaciones.trim().isNotEmpty)
          'observaciones': observaciones.trim(),
      },
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<List<Map<String, dynamic>>> porMensualidad(int idMensualidad) async {
    try {
      final res = await _http.get(
        Endpoints.pagos,
        headers: _h,
        query: {'idMensualidad': '$idMensualidad'},
      );
      if (res is List) {
        return List<Map<String, dynamic>>.from(res).map(_from).toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }
}
