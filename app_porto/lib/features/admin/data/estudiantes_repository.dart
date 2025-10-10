import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class EstudiantesRepository {
  final HttpClient _http;
  EstudiantesRepository(this._http);

  Map<String, String> get _h => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _from(Map<String, dynamic> r) => {
        'id': r['id_estudiante'],
        'nombres': r['nombres'],
        'apellidos': r['apellidos'],
        'telefono': r['telefono'],
        'direccion': r['direccion'],
        'fechaNacimiento': r['fecha_nacimiento'],
        'idAcademia': r['id_academia'],
        'activo': r['activo'],
        // Estos pueden venir nulos si tu SELECT por id no los incluye:
        'idMatricula': r['id_matricula'],
        'idCategoria': r['id_categoria'],
        'categoriaNombre': r['nombre_categoria'],
      };

  Future<Map<String, dynamic>> paged({
    int page = 1,
    int pageSize = 20,
    String? q,
    int? categoriaId,
    bool? onlyActive,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (categoriaId != null) 'categoriaId': '$categoriaId',
      if (onlyActive != null) 'onlyActive': onlyActive.toString(),
    };

    final res = await _http.get(Endpoints.estudiantes, headers: _h, query: query);
    if (res is Map && res['items'] is List) {
      final items = List<Map<String, dynamic>>.from(res['items']).map(_from).toList();
      final total = (res['total'] as num?)?.toInt() ?? items.length;
      return {'items': items, 'total': total, 'page': page, 'pageSize': pageSize};
    }

    final list = (res is List) ? res : [];
    final items = List<Map<String, dynamic>>.from(list).map(_from).toList();
    return {'items': items, 'total': items.length, 'page': 1, 'pageSize': items.length};
  }

  Future<Map<String, dynamic>?> byId(int id) async {
    final res = await _http.get(Endpoints.estudianteId(id), headers: _h);
    if (res == null) return null;
    return _from(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> crear({
    required String nombres,
    required String apellidos,
    String? fechaNacimiento,
    String? direccion,
    String? telefono,
    required int idAcademia,
  }) async {
    final body = {
      'nombres': nombres,
      'apellidos': apellidos,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      'id_academia': idAcademia,
    };
    final res = await _http.post(Endpoints.estudiantes, headers: _h, body: body);
    return _from(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> update({
    required int idEstudiante,
    String? nombres,
    String? apellidos,
    String? fechaNacimiento,
    String? direccion,
    String? telefono,
    int? idAcademia,
    bool? activo,
  }) async {
    final body = <String, dynamic>{};
    if (nombres != null) body['nombres'] = nombres;
    if (apellidos != null) body['apellidos'] = apellidos;
    if (fechaNacimiento != null) body['fecha_nacimiento'] = fechaNacimiento;
    if (direccion != null) body['direccion'] = direccion;
    if (telefono != null) body['telefono'] = telefono;
    if (idAcademia != null) body['id_academia'] = idAcademia;
    if (activo != null) body['activo'] = activo;

    final res = await _http.put(Endpoints.estudianteId(idEstudiante), headers: _h, body: body);
    return _from(Map<String, dynamic>.from(res));
  }

  Future<void> deactivate(int idEstudiante) async {
    await _http.delete(Endpoints.estudianteId(idEstudiante), headers: _h);
  }

  /// Back: PATCH /estudiantes/activar/:id — usamos POST al mismo path
  Future<void> activate(int idEstudiante) async {
    await _http.post(Endpoints.estudianteActivar(idEstudiante), headers: _h, body: const {});
  }
}
