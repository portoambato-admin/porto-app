import 'dart:math';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class MatriculasRepository {
  final HttpClient _http;
  MatriculasRepository(this._http);

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _fromApi(Map<String, dynamic> j) => {
        'id': j['id_matricula'],
        'idEstudiante': j['id_estudiante'],
        'idCategoria': j['id_categoria'],
        'fecha': j['fecha_matricula'],
        'ciclo': j['ciclo'],
        'activo': j['activo'],
        'estudiante': j['estudiante'],
        'categoriaNombre': j['nombre_categoria'],
      };

  Map<String, dynamic> _toCreateBody({
    required int idEstudiante,
    required int idCategoria,
    String? ciclo,
  }) =>
      {
        'id_estudiante': idEstudiante,
        'id_categoria': idCategoria,
        if (ciclo != null && ciclo.trim().isNotEmpty) 'ciclo': ciclo.trim(),
      };

  Map<String, dynamic> _toUpdateBody({
    int? idCategoria,
    String? ciclo,
    bool? activo,
  }) =>
      {
        if (idCategoria != null) 'id_categoria': idCategoria,
        if (ciclo != null) 'ciclo': ciclo,
        if (activo != null) 'activo': activo,
      };

  Map<String, dynamic> _clientSidePage(
    List<Map<String, dynamic>> raw, {
    required int page,
    required int pageSize,
    String sort = 'fecha_matricula',
    String order = 'desc',
    String? q,
    int? idCategoria,
    int? idEstudiante,
    bool? onlyActive,
  }) {
    Iterable<Map<String, dynamic>> it = raw;

    if (idEstudiante != null) {
      it = it.where((r) => (r['id_estudiante'] as num?)?.toInt() == idEstudiante);
    }
    if (onlyActive != null) {
      it = it.where((r) => (r['activo'] ?? false) == onlyActive);
    }
    if (idCategoria != null) {
      it = it.where((r) => (r['id_categoria'] as num?)?.toInt() == idCategoria);
    }
    if (q != null && q.trim().isNotEmpty) {
      final needle = q.trim().toLowerCase();
      it = it.where((r) {
        final est = (r['estudiante'] ?? '').toString().toLowerCase();
        final cat = (r['nombre_categoria'] ?? '').toString().toLowerCase();
        final ciclo = (r['ciclo'] ?? '').toString().toLowerCase();
        return est.contains(needle) || cat.contains(needle) || ciclo.contains(needle);
      });
    }

    int s(x, y) {
      if (x == null && y == null) return 0;
      if (x == null) return -1;
      if (y == null) return 1;
      return '$x'.compareTo('$y');
    }

    int cmp(a, b) {
      switch (sort) {
        case 'id_matricula':
          return ((a['id_matricula'] ?? 0) as int).compareTo((b['id_matricula'] ?? 0) as int);
        case 'ciclo':
          return s(a['ciclo'], b['ciclo']);
        case 'nombre_categoria':
          return s(a['nombre_categoria'], b['nombre_categoria']);
        case 'estudiante':
          return s(a['estudiante'], b['estudiante']);
        default:
          return s(a['fecha_matricula'], b['fecha_matricula']);
      }
    }

    final list = it.toList()
      ..sort((a, b) {
        final r = cmp(a, b);
        return order.toLowerCase() == 'desc' ? -r : r;
      });

    final total = list.length;
    final start = max(0, (page - 1) * pageSize);
    final end = min(total, start + pageSize);
    final pageItems =
        (start < end) ? list.sublist(start, end) : <Map<String, dynamic>>[];

    return {
      'items': pageItems.map(_fromApi).toList(),
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }

  Future<Map<String, dynamic>> paged({
    int page = 1,
    int pageSize = 10,
    String? q,
    String sort = 'fecha_matricula',
    String order = 'desc',
    int? idCategoria,
    int? idEstudiante,
    bool? onlyActive,
  }) async {
    try {
      final res = await _http.get(
        Endpoints.matriculas,
        headers: _headers,
        query: <String, String>{
          'page': '$page',
          'pageSize': '$pageSize',
          'sort': sort,
          'order': order,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (idCategoria != null) 'idCategoria': '$idCategoria',
          if (idEstudiante != null) 'idEstudiante': '$idEstudiante',
          if (onlyActive != null) 'onlyActive': onlyActive.toString(),
        },
      );

      if (res is Map && res['items'] is List) {
        final items = List<Map<String, dynamic>>.from(res['items'])
            .map(_fromApi)
            .toList();
        final total = (res['total'] as num?)?.toInt() ?? items.length;
        return {'items': items, 'total': total, 'page': page, 'pageSize': pageSize};
      }

      if (res is List) {
        return _clientSidePage(
          List<Map<String, dynamic>>.from(res),
          page: page,
          pageSize: pageSize,
          q: q,
          sort: sort,
          order: order,
          idCategoria: idCategoria,
          idEstudiante: idEstudiante,
          onlyActive: onlyActive,
        );
      }
    } catch (_) {
      // silenciamos y hacemos fallback
    }

    // Fallback duro a /todas
    try {
      final all = await _http.get(Endpoints.matriculasTodas, headers: _headers);
      final list = (all is List) ? List<Map<String, dynamic>>.from(all) : <Map<String, dynamic>>[];
      return _clientSidePage(
        list,
        page: page,
        pageSize: pageSize,
        q: q,
        sort: sort,
        order: order,
        idCategoria: idCategoria,
        idEstudiante: idEstudiante,
        onlyActive: onlyActive,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> porEstudiante(int idEstudiante) async {
    final res = await paged(page: 1, pageSize: 999, idEstudiante: idEstudiante);
    return List<Map<String, dynamic>>.from(res['items']);
  }

  Future<Map<String, dynamic>> crear({
    required int idEstudiante,
    required int idCategoria,
    String? ciclo,
  }) async {
    final res = await _http.post(
      Endpoints.matriculas,
      headers: _headers,
      body: _toCreateBody(
        idEstudiante: idEstudiante,
        idCategoria: idCategoria,
        ciclo: ciclo,
      ),
    );
    return _fromApi(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> update({
    required int idMatricula,
    int? idCategoria,
    String? ciclo,
    bool? activo,
  }) async {
    final res = await _http.put(
      Endpoints.matriculaId(idMatricula),
      headers: _headers,
      body: _toUpdateBody(
        idCategoria: idCategoria,
        ciclo: ciclo,
        activo: activo,
      ),
    );
    return _fromApi(Map<String, dynamic>.from(res));
  }

  Future<void> remove(int idMatricula) async {
    await _http.delete(Endpoints.matriculaId(idMatricula), headers: _headers);
  }

  Future<void> activate(int idMatricula) async {
    await _http.patch(
      Endpoints.matriculaActivar(idMatricula),
      headers: _headers,
      body: const {},
    );
  }

  Future<void> deactivate(int idMatricula) async {
    await _http.delete(Endpoints.matriculaId(idMatricula), headers: _headers);
  }
}
