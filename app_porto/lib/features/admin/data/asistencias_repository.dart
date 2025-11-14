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
    // ===== RECOMENDACIÓN: Añade filtros de rango para el historial =====
    String? desde, 
    String? hasta,
  }) async {
    final q = <String, String>{};
    if (idSubcategoria != null) q['id_subcategoria'] = '$idSubcategoria';
    if (fechaISO != null) q['fecha'] = fechaISO;
    if (desde != null) q['desde'] = desde; // Para _fetchSesionesHistorial
    if (hasta != null) q['hasta'] = hasta; // Para _fetchSesionesHistorial

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

  /// NOTA: Tu backend debe devolver aquí el campo 'estatus' (string)
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

  /// marcas: [{ id_estudiante, estatus: 'presente', observaciones? }, ...]
  // ===== MODIFICADO: Envía 'estatus' (string) =====
  Future<void> marcarBulk(int idSesion, List<Map<String, dynamic>> marcas) async {
    await _http.post(
      Endpoints.asistenciasSesionMarcar(idSesion),
      headers: _h,
      body: { 'marcas': marcas }, // El body ya está formateado correctamente por la UI
    );
  }
  // ================================================

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
  
  // ===== NUEVO: Método para el reporte por alumno (Pestaña 4) =====
  /// NOTA: Tu backend debe devolver aquí el campo 'estatus' (string)
  Future<List<Map<String, dynamic>>> asistenciaPorEstudiante({
    required int idSubcategoria,
    required int idEstudiante,
    required String desde,
    required String hasta,
  }) async {
    final q = <String, String>{
      'id_subcategoria': '$idSubcategoria',
      'id_estudiante': '$idEstudiante',
      'desde': desde,
      'hasta': hasta,
    };
    
    // Asume un endpoint nuevo, o modifica el existente
    final endpoint = Endpoints.asistenciasHistorialEstudiante; // (ej: '/asistencias/historial-estudiante')

    final res = await _http.get(
      endpoint,
      headers: _h,
      query: q,
    );
    return (res as List)
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}