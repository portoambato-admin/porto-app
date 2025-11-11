import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class AsistenciasRepository {
  final HttpClient _http;
  AsistenciasRepository(this._http);

  Map<String, String> get _h => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ==== Sesiones ====

  Future<Map<String, dynamic>> crearSesion({
    required int idSubcategoria,
    required String fechaISO,       // 'YYYY-MM-DD'
    String? horaInicio,             // 'HH:mm'
    String? horaFin,
    int? idProfesor,
    String? observaciones,
  }) async {
    final body = {
      'id_subcategoria': idSubcategoria,
      'fecha': fechaISO,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFin != null) 'hora_fin': horaFin,
      if (idProfesor != null) 'id_profesor': idProfesor,
      if (observaciones != null) 'observaciones': observaciones,
    };
    final res = await _http.post(
      Endpoints.asistenciasSesiones,
      headers: _h,
      body: body,
    );
    return Map<String, dynamic>.from(res);
  }

  Future<List<Map<String, dynamic>>> listarSesiones({
    int? idSubcategoria,
    String? fechaISO,
  }) async {
    final q = <String, String>{};
    if (idSubcategoria != null) q['id_subcategoria'] = '$idSubcategoria';
    if (fechaISO != null) q['fecha'] = fechaISO;

    final res = await _http.get(
      Endpoints.asistenciasSesiones,
      headers: _h,
      query: q, // tu HttpClient ya soporta query
    );
    return (res as List)
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> detalleSesion(int idSesion) async {
    final res = await _http.get(
      Endpoints.asistenciasSesionId(idSesion),
      headers: _h,
    );
    return (res as List)
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// marcas: [{ id_estudiante, presente, observaciones?, orden_lista? }, ...]
  Future<void> marcarBulk(int idSesion, List<Map<String, dynamic>> marcas) async {
    await _http.post(
      Endpoints.asistenciasSesionMarcar(idSesion),
      headers: _h,
      body: { 'marcas': marcas },
    );
  }

  // ==== Apoyos existentes ====

  /// Lista de estudiantes asignados a una subcategoría (ordenados)
  Future<List<Map<String, dynamic>>> estudiantesPorSubcategoria(int idSubcategoria) async {
    final res = await _http.get(
      Endpoints.subcatEstPorSubcategoria(idSubcategoria),
      headers: _h,
    );
    return (res as List)
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
