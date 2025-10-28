import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import 'dart:convert';
import 'dart:developer' as dev;

/// Convierte dinámicos a double de forma tolerante (números con coma, strings, etc.)
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

  /// Normaliza el mapa de la API a un formato consistente para la app.
  Map<String, dynamic> _from(Map<String, dynamic> j) => {
        'id'              : j['id_mensualidad'] ?? j['id'],
        'idMatricula'     : j['id_matricula'],
        'mes'             : j['mes'],
        'anio'            : j['anio'],
        'valor'           : _toDoubleSafe(j['valor']) ?? 0.0,
        'estado'          : j['estado'], // 'pendiente' | 'pagado' | 'anulado'
        'idEstudiante'    : j['id_estudiante'],
        'idCategoria'     : j['id_categoria'],
        'categoriaNombre' : j['nombre_categoria'],
        'pagado'          : _toDoubleSafe(j['pagado']) ?? 0.0,
        'creadoEn'        : j['creado_en'] ?? j['creadoEn'],
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
    return const [];
  }

  Map<String, dynamic>? _unwrapMap(dynamic r) {
    if (r is Map<String, dynamic>) {
      if (r['data'] is Map<String, dynamic>) return r['data'] as Map<String, dynamic>;
      return r;
    }
    return null;
  }

  // ================================
  // LISTADOS
  // ================================

  /// Alias en inglés para compatibilidad
  Future<List<Map<String, dynamic>>> byEstudiante(int idEstudiante) =>
      porEstudiante(idEstudiante);

  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    // 0) Ruta dedicada
    try {
      final r0 = await _http.get(
        Endpoints.mensualidadesPorEstudiante(idEstudiante),
        headers: _h,
      );
      final l0 = _unwrapList(r0);
      if (l0.isNotEmpty) {
        final out0 = List<Map<String, dynamic>>.from(l0)
            .map(_from)
            .where((e) => '${e['idEstudiante']}' == '$idEstudiante')
            .toList();
        dev.log('[MensRepo] mapped=${out0.length} est=$idEstudiante (ruta dedicada)');
        return out0;
      }
    } catch (_) {}

    // 1) ?estudianteId=
    try {
      final url = '${Endpoints.mensualidades}${_q({'estudianteId': idEstudiante})}';
      final r1 = await _http.get(url, headers: _h);
      final l1 = _unwrapList(r1);
      if (l1.isNotEmpty) {
        final out1 = List<Map<String, dynamic>>.from(l1)
            .map(_from)
            .where((e) => '${e['idEstudiante']}' == '$idEstudiante')
            .toList();
        dev.log('[MensRepo] mapped=${out1.length} est=$idEstudiante (estudianteId)');
        return out1;
      }
    } catch (e) {
      dev.log('[MensRepo] r1 error: $e');
    }

    // 2) ?idEstudiante=
    try {
      final url = '${Endpoints.mensualidades}${_q({'idEstudiante': idEstudiante})}';
      final r2 = await _http.get(url, headers: _h);
      final l2 = _unwrapList(r2);
      if (l2.isNotEmpty) {
        final out2 = List<Map<String, dynamic>>.from(l2)
            .map(_from)
            .where((e) => '${e['idEstudiante']}' == '$idEstudiante')
            .toList();
        dev.log('[MensRepo] mapped=${out2.length} est=$idEstudiante (idEstudiante)');
        return out2;
      }
    } catch (e) {
      dev.log('[MensRepo] r2 error: $e');
    }

    // 3) ?id_estudiante=
    try {
      final url = '${Endpoints.mensualidades}${_q({'id_estudiante': idEstudiante})}';
      final r3 = await _http.get(url, headers: _h);
      final l3 = _unwrapList(r3);
      if (l3.isNotEmpty) {
        final out3 = List<Map<String, dynamic>>.from(l3)
            .map(_from)
            .where((e) => '${e['idEstudiante']}' == '$idEstudiante')
            .toList();
        dev.log('[MensRepo] mapped=${out3.length} est=$idEstudiante (id_estudiante)');
        return out3;
      }
    } catch (e) {
      dev.log('[MensRepo] r3 error: $e');
    }

    // 4) fallback: all
    try {
      final all = await _http.get(Endpoints.mensualidades, headers: _h);
      final la = _unwrapList(all);
      final outA = List<Map<String, dynamic>>.from(la)
          .map(_from)
          .where((e) => '${e['idEstudiante']}' == '$idEstudiante')
          .toList();
      dev.log('[MensRepo] mapped=${outA.length} est=$idEstudiante (fallback ALL)');
      return outA;
    } catch (e) {
      dev.log('[MensRepo] all error: $e');
    }

    dev.log('[MensRepo] mapped=0 est=$idEstudiante (sin datos)');
    return const <Map<String, dynamic>>[];
  }

  /// Alias en inglés
  Future<List<Map<String, dynamic>>> byMatricula(int idMatricula) =>
      porMatricula(idMatricula);

  Future<List<Map<String, dynamic>>> porMatricula(int idMatricula) async {
    final url = '${Endpoints.mensualidades}${_q({'matriculaId': idMatricula})}';
    final res = await _http.get(url, headers: _h);
    final List list = _unwrapList(res);
    return List<Map<String, dynamic>>.from(list).map(_from).toList();
  }

  Future<List<Map<String, dynamic>>> listar({
    int? estudianteId,
    int? matriculaId,
    int? anio,
    int? mes,
    String? estado, // 'pendiente'|'pagado'|'anulado'
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
  // CRUD
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

  Future<Map<String, dynamic>?> cambiarEstado({
    required int idMensualidad,
    required String estado, // 'pendiente' | 'pagado' | 'anulado'
  }) async {
    final payload = jsonEncode({'estado': estado});
    try {
      final r1 = await _http.patch(
        '${Endpoints.mensualidades}/$idMensualidad/estado',
        headers: _h,
        body: payload,
      );
      final m1 = _unwrapMap(r1);
      if (m1 != null) return _from(m1);
    } catch (e) {
      dev.log('[MensRepo] cambiarEstado r1 error: $e');
    }
    try {
      final r2 = await _http.patch(
        '${Endpoints.mensualidades}/$idMensualidad',
        headers: _h,
        body: payload,
      );
      final m2 = _unwrapMap(r2);
      if (m2 != null) return _from(m2);
    } catch (e) {
      dev.log('[MensRepo] cambiarEstado r2 error: $e');
    }
    try {
      final r3 = await _http.post(
        '${Endpoints.mensualidades}/$idMensualidad/estado',
        headers: _h,
        body: payload,
      );
      final m3 = _unwrapMap(r3);
      if (m3 != null) return _from(m3);
    } catch (e) {
      dev.log('[MensRepo] cambiarEstado r3 error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> anular(int idMensualidad) =>
      cambiarEstado(idMensualidad: idMensualidad, estado: 'anulado');

  Future<bool> eliminar(int idMensualidad) async {
    try {
      // Tu HttpClient.delete devuelve Future<void>, no hay valor que usar.
      await _http.delete(
        '${Endpoints.mensualidades}/$idMensualidad',
        headers: _h,
      );
      // Si no lanzó excepción, lo damos por correcto.
      return true;
    } catch (e) {
      // Si falla el DELETE, intentamos anular como fallback.
      dev.log('[MensRepo] eliminar error: $e');
    }

    try {
      final m = await anular(idMensualidad);
      return m != null && (m['estado']?.toString().toLowerCase() == 'anulado');
    } catch (_) {
      return false;
    }
  }
}
