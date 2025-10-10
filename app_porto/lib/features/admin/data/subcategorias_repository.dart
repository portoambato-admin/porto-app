import 'dart:math';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

class SubcategoriasRepository {
  final HttpClient _http;
  SubcategoriasRepository(this._http);

  // headers requeridos por tu HttpClient
  static const Map<String, String> _h = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _fromApi(Map<String, dynamic> j) => {
        'id': j['id_subcategoria'],
        'idCategoria': j['id_categoria'],
        'nombre': j['nombre_subcategoria'],
        'codigo': j['codigo_unico'],
        'activo': j['activo'],
        'creadoEn': j['creado_en'],
        'categoriaNombre': j['nombre_categoria'],
      };

  Map<String, dynamic> _toCreateBody({
    required int idCategoria,
    required String nombre,
    required String codigo, // <-- obligatorio
  }) =>
      {
        'id_categoria': idCategoria,
        'nombre_subcategoria': nombre,
        'codigo_unico': codigo,
      };

  Map<String, dynamic> _toUpdateBody({
    String? nombre,
    String? codigo,
    int? idCategoria,
    bool? activo,
  }) =>
      {
        if (nombre != null) 'nombre_subcategoria': nombre,
        if (codigo != null) 'codigo_unico': codigo,
        if (idCategoria != null) 'id_categoria': idCategoria,
        if (activo != null) 'activo': activo,
      };

  // ---------- Helpers ----------
  List<Map<String, dynamic>> _asItems(dynamic res) {
    if (res is List) return List<Map<String, dynamic>>.from(res);
    if (res is Map && res['items'] is List) {
      return List<Map<String, dynamic>>.from(res['items']);
    }
    throw Exception('Respuesta inesperada del servidor');
  }

  int _asTotal(dynamic res) {
    if (res is Map && res['total'] is num) return (res['total'] as num).toInt();
    if (res is List) return res.length;
    return 0;
  }

  Map<String, dynamic> _clientSidePage(
    List<Map<String, dynamic>> raw, {
    required int page,
    required int pageSize,
    String sort = 'nombre_subcategoria',
    String order = 'asc',
    String? q,
    int? idCategoria,
    bool? onlyActive,
  }) {
    Iterable<Map<String, dynamic>> it = raw;

    if (onlyActive != null) {
      it = it.where((r) => (r['activo'] ?? false) == onlyActive);
    }
    if (idCategoria != null) {
      it = it.where((r) => (r['id_categoria'] as num?)?.toInt() == idCategoria);
    }
    if (q != null && q.trim().isNotEmpty) {
      final needle = q.trim().toLowerCase();
      it = it.where((r) {
        final n = (r['nombre_subcategoria'] ?? '').toString().toLowerCase();
        final c = (r['codigo_unico'] ?? '').toString().toLowerCase();
        final cat = (r['nombre_categoria'] ?? '').toString().toLowerCase();
        return n.contains(needle) || c.contains(needle) || cat.contains(needle);
      });
    }

    int cmp(a, b) {
      int s(x, y) {
        if (x == null && y == null) return 0;
        if (x == null) return -1;
        if (y == null) return 1;
        return '$x'.compareTo('$y');
      }

      switch (sort) {
        case 'id_subcategoria':
          return ((a['id_subcategoria'] ?? 0) as int)
              .compareTo((b['id_subcategoria'] ?? 0) as int);
        case 'codigo_unico':
          return s(a['codigo_unico'], b['codigo_unico']);
        case 'creado_en':
          return s(a['creado_en'], b['creado_en']);
        default:
          return s(a['nombre_subcategoria'], b['nombre_subcategoria']);
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

  // ---------- Listas simples ----------
  Future<List<Map<String, dynamic>>> activas() async {
    final res = await _http.get(Endpoints.subcategorias + '/activas', headers: _h);
    return _asItems(res).map(_fromApi).toList();
  }

  Future<List<Map<String, dynamic>>> inactivas() async {
    final res =
        await _http.get(Endpoints.subcategorias + '/inactivas', headers: _h);
    return _asItems(res).map(_fromApi).toList();
  }

  Future<List<Map<String, dynamic>>> todas() async {
    final res = await _http.get(Endpoints.subcategorias, headers: _h);
    return _asItems(res).map(_fromApi).toList();
  }

  // ---------- Paginado (con fallback en cliente) ----------
  Future<Map<String, dynamic>> paged({
    int page = 1,
    int pageSize = 10,
    String? q,
    String sort = 'nombre_subcategoria',
    String order = 'asc',
    int? idCategoria,
    bool? onlyActive,
  }) async {
    final res = await _http.get(
      Endpoints.subcategorias,
      headers: _h,
      query: <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
        'sort': sort,
        'order': order,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (idCategoria != null) 'idCategoria': '$idCategoria',
        if (onlyActive != null) 'onlyActive': onlyActive.toString(),
      },
    );

    if (res is Map && res['items'] is List) {
      final items =
          List<Map<String, dynamic>>.from(res['items']).map(_fromApi).toList();
      final total = _asTotal(res);
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
        onlyActive: onlyActive,
      );
    }

    final list = await todas();
    final raw = list
        .map((e) => {
              'id_subcategoria': e['id'],
              'id_categoria': e['idCategoria'],
              'nombre_subcategoria': e['nombre'],
              'codigo_unico': e['codigo'],
              'activo': e['activo'],
              'creado_en': e['creadoEn'],
              'nombre_categoria': e['categoriaNombre'],
            })
        .toList();

    return _clientSidePage(
      raw,
      page: page,
      pageSize: pageSize,
      q: q,
      sort: sort,
      order: order,
      idCategoria: idCategoria,
      onlyActive: onlyActive,
    );
  }

  // ---------- CRUD ----------
  Future<Map<String, dynamic>> crear({
    required int idCategoria,
    required String nombre,
    required String codigo, // <-- obligatorio
  }) async {
    final body = _toCreateBody(
      idCategoria: idCategoria,
      nombre: nombre,
      codigo: codigo,
    );
    final res = await _http.post(
      Endpoints.subcategorias,
      headers: _h,
      body: body,
    );
    return _fromApi(Map<String, dynamic>.from(res));
  }

  Future<Map<String, dynamic>> update({
    required int idSubcategoria,
    String? nombre,
    String? codigo, // puedes permitir actualizarlo
    int? idCategoria,
    bool? activo,
  }) async {
    final res = await _http.put(
      Endpoints.subcategoriaId(idSubcategoria),
      headers: _h,
      body: _toUpdateBody(
        nombre: nombre,
        codigo: codigo,
        idCategoria: idCategoria,
        activo: activo,
      ),
    );
    return _fromApi(Map<String, dynamic>.from(res));
  }

  Future<void> remove(int idSubcategoria) async {
    await _http.delete(Endpoints.subcategoriaId(idSubcategoria), headers: _h);
  }

  Future<void> activate(int idSubcategoria) async {
    await _http.post(
      Endpoints.subcategoriaActivar(idSubcategoria),
      headers: _h,
      body: const {},
    );
  }
}
