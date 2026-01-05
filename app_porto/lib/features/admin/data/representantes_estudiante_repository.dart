import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class RepresentantesEstudianteRepository {
  final HttpClient _http;
  const RepresentantesEstudianteRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<List<Map<String, dynamic>>> tiposRelacion() async {
    final res = await _http.get(Endpoints.tiposRelacion, headers: _h);
    final list = (res is List) ? res : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<Map<String, dynamic>>> listarVinculos(int idEstudiante, {bool incluirInactivos = false}) async {
    final res = await _http.get(
      Endpoints.representantesDeEstudiante(idEstudiante),
      headers: _h,
      query: {'incluirInactivos': incluirInactivos.toString()},
    );
    final list = (res is List) ? res : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<List<Map<String, dynamic>>> buscarRepresentantes(String q) async {
    final res = await _http.get(
      Endpoints.usuariosBuscarGeneral,
      headers: _h,
      query: {
        'q': q,
        'rol': '3', // Representante
        'activosOnly': 'true',
      },
    );
    final list = (res is List) ? res : [];
    return List<Map<String, dynamic>>.from(list);
  }

  Future<Map<String, dynamic>> vincular({
    required int idEstudiante,
    required int idUsuarioRepresentante,
    required int idRelacion,
  }) async {
    final res = await _http.post(
      Endpoints.representantesEstudiante,
      headers: _h,
      body: {
        'id_estudiante': idEstudiante,
        'id_usuario_representante': idUsuarioRepresentante,
        'id_relacion': idRelacion,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> desactivar({required int idUsuarioRepresentante, required int idEstudiante}) async {
    await _http.patch(
      Endpoints.repEstDesactivar(idUsuarioRepresentante, idEstudiante),
      headers: _h,
    );
  }

  Future<void> activar({required int idUsuarioRepresentante, required int idEstudiante}) async {
    await _http.patch(
      Endpoints.repEstActivar(idUsuarioRepresentante, idEstudiante),
      headers: _h,
    );
  }
}
