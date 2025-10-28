// lib/features/admin/data/pagos_repository.dart
import 'dart:convert';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class PagosRepository {
  final HttpClient _http;
  const PagosRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _mapPago(Map j) => {
        'id': j['id_pago'],
        'id_mensualidad': j['id_mensualidad'],
        'fecha': j['fecha_pago'],
        'monto': (j['monto_pagado'] as num?)?.toDouble() ?? 0.0,
        'metodo': j['metodo_pago'],
        'obs': j['observaciones'],
        'activo': j['activo'] == true,
        'motivo': j['motivo_anulacion'],
      };

  // ⬇️ AHORA con parámetros nombrados (como lo llama tu panel)
  Future<List<Map<String, dynamic>>> byMensualidad({
    required int idMensualidad,
    bool soloActivos = false,
  }) async {
    final url =
        '${Endpoints.pagos}?mensualidadId=$idMensualidad&soloActivos=$soloActivos';
    final res = await _http.get(url, headers: _h);
    final List list = res is List ? res : (res['data'] ?? []);
    return list.cast<Map>().map((e) => _mapPago(e)).toList();
  }

  Future<Map<String, dynamic>?> crear({
    required int idMensualidad,
    required double monto,
    required String metodo,
    String? observaciones,
    DateTime? fecha,
  }) async {
    final body = jsonEncode({
      'id_mensualidad': idMensualidad,
      'monto_pagado': monto, // <- double
      'metodo_pago': metodo,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
      if (fecha != null) 'fecha_pago': fecha.toUtc().toIso8601String(),
    });
    final res = await _http.post(Endpoints.pagos, headers: _h, body: body);
    final map = (res is Map && res['data'] is Map) ? res['data'] : res;
    if (map is! Map) return null;
    return _mapPago(map);
  }

  Future<bool> anular({required int idPago, required String motivo}) async {
    final res = await _http.patch(
      '${Endpoints.pagos}/$idPago/anular',
      headers: _h,
      body: jsonEncode({'motivo': motivo}),
    );
    return (res is Map && res['ok'] == true);
  }

  Future<bool> activar({required int idPago}) async {
    final res =
        await _http.patch('${Endpoints.pagos}/$idPago/activar', headers: _h);
    return (res is Map && res['ok'] == true);
  }

  Future<Map<String, dynamic>?> actualizar({
    required int idPago,
    double? monto,
    String? metodo,
    String? observaciones,
    DateTime? fecha,
  }) async {
    final body = jsonEncode({
      if (monto != null) 'monto_pagado': monto,
      if (metodo != null) 'metodo_pago': metodo,
      if (observaciones != null) 'observaciones': observaciones,
      if (fecha != null) 'fecha_pago': fecha.toUtc().toIso8601String(),
    });
    final res =
        await _http.put('${Endpoints.pagos}/$idPago', headers: _h, body: body);
    final map = (res is Map && res['data'] is Map) ? res['data'] : res;
    if (map is! Map) return null;
    return _mapPago(map);
  }
}
