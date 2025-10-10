// lib/features/admin/data/subcat_est_repository.dart
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class SubcatEstRepository {
  final HttpClient _http;
  SubcatEstRepository(this._http);

  Map<String, String> get _h => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Normaliza lo que venga del back
  Map<String, dynamic> _from(Map<String, dynamic> j) => {
    'idEstudiante'   : j['id_estudiante'] ?? j['idEstudiante'],
    'idSubcategoria' : j['id_subcategoria'] ?? j['idSubcategoria'],
    'fechaUnion'     : j['fecha_union'] ?? j['fechaUnion'],
    // Si tu back hace JOINs opcionales:
    'categoria'      : j['categoria'] ?? j['categoriaNombre'],
    'subcategoria'   : j['subcategoria'] ?? j['nombre_subcategoria'] ?? j['subcategoriaNombre'],
    'nombres'        : j['nombres'],
    'apellidos'      : j['apellidos'],
    'estudiante'     : j['estudiante'], // nombres + apellidos si el back lo envía junto
    'activo'         : j['activo'],
  };

  List<Map<String, dynamic>> _asList(dynamic res) {
    if (res is List) {
      return List<Map<String, dynamic>>.from(res).map(_from).toList();
    }
    if (res is Map && res['items'] is List) {
      return List<Map<String, dynamic>>.from(res['items']).map(_from).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  // ========== Lecturas ==========
  /// Trae TODAS las asignaciones (si tienes GET /subcategoria-estudiante)
  Future<List<Map<String, dynamic>>> todas() async {
    final res = await _http.get(Endpoints.subcatEst, headers: _h);
    return _asList(res);
  }

  /// Por estudiante (usa endpoint si existe; si no, filtra en cliente)
  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    try {
      final res = await _http.get(
        Endpoints.subcatEstPorEstudiante(idEstudiante),
        headers: _h,
      );
      return _asList(res);
    } catch (_) {
      // Fallback si el endpoint no existe: traer todo y filtrar
      final all = await todas();
      return all.where((m) => (m['idEstudiante'] as num?)?.toInt() == idEstudiante).toList();
    }
  }

  /// Por subcategoría (si no tienes endpoint dedicado, se filtra cliente)
  Future<List<Map<String, dynamic>>> porSubcategoria(int idSubcategoria) async {
    // Si más adelante expones GET /subcategoria-estudiante/subcategoria/:id, úsalo aquí.
    final all = await todas();
    return all.where((m) => (m['idSubcategoria'] as num?)?.toInt() == idSubcategoria).toList();
  }

  // ========== Mutaciones ==========
  Future<void> asignar({
    required int idEstudiante,
    required int idSubcategoria,
  }) async {
    await _http.post(
      Endpoints.subcatEst,
      headers: _h,
      body: {
        'id_estudiante': idEstudiante,
        'id_subcategoria': idSubcategoria,
      },
    );
  }

  Future<void> eliminar({
    required int idEstudiante,
    required int idSubcategoria,
  }) async {
    await _http.delete(
      Endpoints.subcatEstEliminar(idEstudiante, idSubcategoria),
      headers: _h,
    );
  }
}
