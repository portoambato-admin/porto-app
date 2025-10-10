import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

/// Helper chiquito para leer números aunque vengan como String "40.00"
double? _toDoubleSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    // Normaliza: quita miles con punto y usa punto como decimal
    final normalized = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? double.tryParse(s);
  }
  return null;
}

class MensualidadesRepository {
  final HttpClient _http;
  MensualidadesRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _from(Map<String, dynamic> j) => {
        'id': j['id_mensualidad'],
        'idMatricula': j['id_matricula'],
        'mes': j['mes'],
        'anio': j['anio'],
        // ⬇️ FIX: antes `(j['valor'] as num?)?.toDouble()`
        'valor': _toDoubleSafe(j['valor']),
        'estado': j['estado'],
        // Si viene por estudiante, puede incluir datos de categoría
        'idCategoria': j['id_categoria'],
        'categoriaNombre': j['nombre_categoria'],
      };

  // ✅ listar por estudiante
  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    final res = await _http.get(
      Endpoints.mensualidades,
      headers: _h,
      query: {'estudianteId': '$idEstudiante'},
    );
    final list = (res is List) ? res : <dynamic>[];
    return List<Map<String, dynamic>>.from(list).map(_from).toList();
  }

  // listar por matrícula
  Future<List<Map<String, dynamic>>> porMatricula(int idMatricula) async {
    final res = await _http.get(
      Endpoints.mensualidades,
      headers: _h,
      query: {'matriculaId': '$idMatricula'},
    );
    final list = (res is List) ? res : <dynamic>[];
    return List<Map<String, dynamic>>.from(list).map(_from).toList();
  }

  Future<Map<String, dynamic>> crear({
    required int idMatricula,
    required int mes,
    required int anio,
    required double valor,
    String estado = 'pendiente',
  }) async {
    final res = await _http.post(
      Endpoints.mensualidades,
      headers: _h,
      body: {
        'id_matricula': idMatricula,
        'mes': mes,
        'anio': anio,
        'valor': valor,
        'estado': estado,
      },
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> actualizar({
    required int idMensualidad,
    int? mes,
    int? anio,
    double? valor,
  }) async {
    final body = <String, dynamic>{};
    if (mes != null) body['mes'] = mes;
    if (anio != null) body['anio'] = anio;
    if (valor != null) body['valor'] = valor;
    final res = await _http.put(
      '${Endpoints.mensualidades}/$idMensualidad',
      headers: _h,
      body: body,
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> cambiarEstado({
    required int idMensualidad,
    required String estado, // 'pendiente'|'pagado'|'anulado'
  }) async {
    final res = await _http.patch(
      '${Endpoints.mensualidades}/$idMensualidad/estado',
      headers: _h,
      body: {'estado': estado},
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<void> eliminar(int idMensualidad) async {
    await _http.delete('${Endpoints.mensualidades}/$idMensualidad', headers: _h);
  }
}
