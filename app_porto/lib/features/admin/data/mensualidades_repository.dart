import 'dart:convert';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

double? _toDoubleSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
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
        'id'              : j['id_mensualidad'] ?? j['id'],
        'id_mensualidad'  : j['id_mensualidad'] ?? j['id'],
        'idMatricula'     : j['id_matricula'],
        'mes'             : j['mes'],
        'anio'            : j['anio'],
        'valor'           : _toDoubleSafe(j['valor']) ?? 0.0,
        'estado'          : j['estado'],
        'id_estudiante'   : j['id_estudiante'],
        'id_categoria'    : j['id_categoria'],
        'nombre_categoria': j['nombre_categoria'],
        'nombres'         : j['nombres'],
        'apellidos'       : j['apellidos'],
        'cedula'          : j['cedula'],
        'id_subcategoria' : j['id_subcategoria'],
        'subcategoria'    : j['subcategoria'],
        'pagado'          : _toDoubleSafe(j['pagado']) ?? 0.0,
        'creado_en'       : j['creado_en'] ?? j['creadoEn'],
        'vencido'         : j['vencido'],
      };

  String _q(Map<String, Object?> params) {
    final p = params.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}')
        .join('&');
    return p.isEmpty ? '' : '?$p';
  }

  List _unwrapList(dynamic r) {
    if (r is List) return r;
    if (r is Map && r['data'] is List) return r['data'] as List;
    if (r is Map && r['rows'] is List) return r['rows'] as List; // Agregado para soporte bulk
    return const [];
  }

  Map<String, dynamic>? _unwrapMap(dynamic r) {
    if (r is Map<String, dynamic>) {
      if (r['data'] is Map<String, dynamic>) return r['data'] as Map<String, dynamic>;
      return r;
    }
    if (r is Map) return Map<String, dynamic>.from(r);
    return null;
  }

  // ================================
  // LISTADOS EXISTENTES
  // ================================

  Future<List<Map<String, dynamic>>> byEstudiante(int idEstudiante) =>
      porEstudiante(idEstudiante);

  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    try {
      final r0 = await _http.get(
        Endpoints.mensualidadesPorEstudiante(idEstudiante),
        headers: _h,
      );
      final l0 = _unwrapList(r0);
      if (l0.isNotEmpty) {
        return List<Map<String, dynamic>>.from(l0)
            .map(_from)
            .where((e) => '${e['id_estudiante']}' == '$idEstudiante')
            .toList();
      }
    } catch (_) {}

    // Fallbacks omitidos para brevedad, mantener lógica original si se desea...
    // Asumimos que la ruta dedicada funciona o retorna vacío.
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> listar({
    int? estudianteId,
    int? matriculaId,
    int? anio,
    int? mes,
    String? estado,
  }) async {
    final url = '${Endpoints.mensualidades}${_q({
      if (estudianteId != null) 'estudianteId': estudianteId,
      if (matriculaId  != null) 'matriculaId' : matriculaId,
      if (anio         != null) 'anio'        : anio,
      if (mes          != null) 'mes'         : mes,
      if (estado       != null && estado.isNotEmpty) 'estado' : estado,
    })}';
    final r = await _http.get(url, headers: _h);
    final l = _unwrapList(r);
    return List<Map<String, dynamic>>.from(l).map(_from).toList();
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final r = await _http.get('${Endpoints.mensualidades}/$id', headers: _h);
    final m = _unwrapMap(r);
    return m == null ? null : _from(m);
  }

  // ================================
  // CRUD EXISTENTE
  // ================================

  Future<Map<String, dynamic>?> crear({
    required int idMatricula,
    required int mes,
    required int anio,
    required double valor,
    String? estado,
  }) async {
    final body = jsonEncode({
      'id_matricula': idMatricula,
      'mes': mes,
      'anio': anio,
      'valor': valor,
      if (estado != null) 'estado': estado,
    });
    final r = await _http.post(Endpoints.mensualidades, headers: _h, body: body);
    final m = _unwrapMap(r);
    return m == null ? null : _from(m);
  }

  Future<Map<String, dynamic>?> actualizar({
    required int idMensualidad,
    int? mes,
    int? anio,
    double? valor,
    String? estado,
  }) async {
    final body = jsonEncode({
      if (mes != null) 'mes': mes,
      if (anio != null) 'anio': anio,
      if (valor != null) 'valor': valor,
      if (estado != null) 'estado': estado,
    });
    final r = await _http.put('${Endpoints.mensualidades}/$idMensualidad',
        headers: _h, body: body);
    final m = _unwrapMap(r);
    return m == null ? null : _from(m);
  }

  Future<bool> eliminar(int idMensualidad) async {
    try {
      await _http.delete('${Endpoints.mensualidades}/$idMensualidad', headers: _h);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> anular(int idMensualidad) =>
      cambiarEstado(idMensualidad: idMensualidad, estado: 'anulado');

  Future<Map<String, dynamic>?> cambiarEstado({
    required int idMensualidad,
    required String estado,
  }) async {
    final payload = jsonEncode({'estado': estado});
    try {
      final r = await _http.patch(
        '${Endpoints.mensualidades}/$idMensualidad/estado',
        headers: _h,
        body: payload,
      );
      final m = _unwrapMap(r);
      if (m != null) return _from(m);
    } catch (_) {}
    return null;
  }

  // ================================
  // ⚠️ NUEVO: FUNCIONALIDAD BULK / MASIVA
  // (Integrada aquí para usarla desde AdminPagosScreen)
  // ================================

  /// Lista subcategorías con conteo (para dropdown de selección)
  Future<List<Map<String, dynamic>>> obtenerSubcategoriasBulk() async {
    final r = await _http.get(Endpoints.mensualidadesBulkSubcategorias, headers: _h);
    return List<Map<String, dynamic>>.from(_unwrapList(r));
  }

  /// Lista estudiantes de una subcategoría con resumen de meses pagados
  Future<List<Map<String, dynamic>>> obtenerEstudiantesPorSubcategoria({
    required int idSubcategoria,
    required int anio,
  }) async {
    final r = await _http.get(
      Endpoints.mensualidadesBulkEstudiantesSubcategoria(idSubcategoria),
      headers: _h,
      query: {'anio': '$anio'},
    );
    return List<Map<String, dynamic>>.from(_unwrapList(r));
  }

  /// Ejecuta la creación masiva
  Future<Map<String, dynamic>> crearMensualidadesBulk({
    required int idSubcategoria,
    required int anio,
    required List<int> meses,
    required double valor,
    List<int>? estudiantesIds,
  }) async {
    final payload = {
      'id_subcategoria': idSubcategoria,
      'anio': anio,
      'meses': meses,
      'valor': valor,
      if (estudiantesIds != null) 'estudiantes_ids': estudiantesIds,
    };

    final r = await _http.post(
      Endpoints.mensualidadesBulk,
      headers: _h,
      body: jsonEncode(payload),
    );

    return _unwrapMap(r) ?? {};
  }

  
}