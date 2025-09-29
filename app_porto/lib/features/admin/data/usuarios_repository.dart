import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class UsuariosRepository {
  final HttpClient _http;
  const UsuariosRepository(this._http);

  // ---- Listas rápidas (sin paginación) ----
  Future<List<Map<String, dynamic>>> todos() async {
    final res = await _http.get(Endpoints.usuarios, headers: {});
    if (res is List) {
      return res.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> activos() async {
    final res = await _http.get(Endpoints.usuariosActivos, headers: {});
    if (res is List) {
      return res.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> inactivos() async {
    final res = await _http.get(Endpoints.usuariosInactivos, headers: {});
    if (res is List) {
      return res.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  // ---- Paginado ----
  Future<Map<String, dynamic>> paged({
    required int page,
    required int pageSize,
    String? q,
    String sort = 'creado_en', // id_usuario|nombre|correo|creado_en
    String order = 'desc',     // asc|desc
    String path = '',          // "", "/activos", "/inactivos"
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'sort': sort,
      'order': order,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
    };

    final res = await _http.getWithHeaders('${Endpoints.usuarios}$path', query: qp, headers: {});
    final data = res['data'];
    final headers = (res['headers'] as Map).cast<String, String>();

    final items = (data is List)
        ? data.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final totalStr = headers['x-total-count'];
    final total = int.tryParse(totalStr ?? '') ?? items.length;

    return {'items': items, 'total': total, 'page': page, 'pageSize': pageSize};
  }

  Future<Map<String, dynamic>> pagedTodos({
    required int page,
    required int pageSize,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      paged(page: page, pageSize: pageSize, q: q, sort: sort, order: order, path: '');

  Future<Map<String, dynamic>> pagedActivos({
    required int page,
    required int pageSize,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      paged(page: page, pageSize: pageSize, q: q, sort: sort, order: order, path: '/activos');

  Future<Map<String, dynamic>> pagedInactivos({
    required int page,
    required int pageSize,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      paged(page: page, pageSize: pageSize, q: q, sort: sort, order: order, path: '/inactivos');

  // ---- Mutaciones ----
  Future<Map<String, dynamic>> update({
    required int idUsuario,
    String? nombre,
    String? correo,
    int? idRol,
    bool? activo,
    String? avatarUrl,
    bool? verificado,
    int? idAcademia,
  }) async {
    final body = <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (correo != null) 'correo': correo,
      if (idRol != null) 'id_rol': idRol,
      if (activo != null) 'activo': activo,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (verificado != null) 'verificado': verificado,
      if (idAcademia != null) 'id_academia': idAcademia,
    };
    final res = await _http.put(Endpoints.usuarioId(idUsuario), body: body, headers: {});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> remove(int idUsuario) async {
    await _http.delete(Endpoints.usuarioId(idUsuario), headers: {});
  }

  Future<void> activate(int idUsuario) async {
    await _http.post(Endpoints.usuarioActivar(idUsuario), body: const {}, headers: {});
  }

  // ---- Búsquedas ----
  Future<List<Map<String, dynamic>>> search({
    required String q,
    bool activosOnly = true,
    int? rol, // 1=admin,2=profesor,3=padre,4=usuario
    int limit = 10,
  }) async {
    final qp = <String, String>{
      'q': q,
      'limit': '$limit',
      if (activosOnly) 'activosOnly': 'true',
      if (rol != null) 'rol': '$rol',
    };
    final res = await _http.get(Endpoints.usuariosBuscar, query: qp, headers: {});
    if (res is List) {
      return res.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> searchProfesores({
    required String q,
    int limit = 10,
  }) async {
    return search(q: q, activosOnly: true, rol: 2, limit: limit);
  }
}
