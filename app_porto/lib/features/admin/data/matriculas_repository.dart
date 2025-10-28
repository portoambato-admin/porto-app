import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class MatriculasRepository {
  final HttpClient _http;
  MatriculasRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _from(Map<String, dynamic> j) => {
        'id': j['id_matricula'] ?? j['id'],
        'idEstudiante':
            j['id_estudiante'] ?? j['estudianteId'] ?? j['idEstudiante'],
        'idCategoria':
            j['id_categoria'] ?? j['categoriaId'] ?? j['idCategoria'],
        'categoriaNombre': j['categoria_nombre'] ?? j['categoriaNombre'],
        'ciclo': j['ciclo'],
        'fecha': j['fecha_matricula'] ?? j['fecha'] ?? j['creado_en'],
        'activo': j['activo'] ?? true,
      };

  /// ✅ por estudiante - intenta con varios nombres de parámetro
  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    // 0) Preferir ruta dedicada si tu back la tiene
    try {
      final r0 = await _http.get(
        Endpoints.matriculasPorEstudiante(idEstudiante),
        headers: _h,
      );
      if (r0 is List && r0.isNotEmpty) {
        return List<Map<String, dynamic>>.from(r0).map(_from).toList();
      }
    } catch (_) {/* ignorar y probar otras formas */}

    // 1) estudianteId
    final r1 = await _http.get(
      Endpoints.matriculas,
      headers: _h,
      query: {'estudianteId': '$idEstudiante'},
    );
    if (r1 is List && r1.isNotEmpty) {
      return List<Map<String, dynamic>>.from(r1).map(_from).toList();
    }

    // 2) idEstudiante
    final r2 = await _http.get(
      Endpoints.matriculas,
      headers: _h,
      query: {'idEstudiante': '$idEstudiante'},
    );
    if (r2 is List && r2.isNotEmpty) {
      return List<Map<String, dynamic>>.from(r2).map(_from).toList();
    }

    // 3) id_estudiante
    final r3 = await _http.get(
      Endpoints.matriculas,
      headers: _h,
      query: {'id_estudiante': '$idEstudiante'},
    );
    if (r3 is List && r3.isNotEmpty) {
      return List<Map<String, dynamic>>.from(r3).map(_from).toList();
    }

    // 4) Fallback: trae todo y filtra en cliente
    final all = await _http.get(Endpoints.matriculas, headers: _h);
    if (all is List && all.isNotEmpty) {
      final filtered = List<Map<String, dynamic>>.from(all)
          .where((e) =>
              (e['id_estudiante']?.toString() == '$idEstudiante') ||
              (e['idEstudiante']?.toString() == '$idEstudiante') ||
              (e['estudianteId']?.toString() == '$idEstudiante'))
          .map(_from)
          .toList();
      return filtered;
    }

    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> crear({
    required int idEstudiante,
    required int idCategoria,
    String? ciclo,
    String? fechaISO, // YYYY-MM-DD
  }) async {
    final body = <String, dynamic>{
      'id_estudiante': idEstudiante,
      'id_categoria': idCategoria,
      if (ciclo != null) 'ciclo': ciclo,
      if (fechaISO != null) 'fecha_matricula': fechaISO,
    };

    final res = await _http.post(
      Endpoints.matriculas,
      headers: _h,
      body: body,
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> update({
    required int idMatricula,
    int? idCategoria,
    String? ciclo,
    String? fechaISO, // YYYY-MM-DD
    bool? activo,
  }) async {
    final body = <String, dynamic>{};
    if (idCategoria != null) body['id_categoria'] = idCategoria;
    if (ciclo != null) body['ciclo'] = ciclo;
    if (fechaISO != null) body['fecha_matricula'] = fechaISO;
    if (activo != null) body['activo'] = activo;

    final res = await _http.put(
      Endpoints.matriculaId(idMatricula),
      headers: _h,
      body: body,
    );
    return _from(Map<String, dynamic>.from(res));
  }

  Future<void> activate(int idMatricula) async {
    await _http.patch(
      '${Endpoints.matriculas}/$idMatricula/activar',
      headers: _h,
    );
  }

  Future<void> deactivate(int idMatricula) async {
    await _http.patch(
      '${Endpoints.matriculas}/$idMatricula/desactivar',
      headers: _h,
    );
  }

  Future<Map<String, dynamic>?> byId(int id) async {
    final res = await _http.get(Endpoints.matriculaId(id), headers: _h);
    return (res is Map) ? Map<String, dynamic>.from(res) : null;
  }
}
