import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';

Map<String, dynamic> _catFromBackend(Map<String, dynamic> r) {
  return {
    'id': r['id_categoria'],
    'nombre': r['nombre_categoria'],
    'edadMin': r['edad_minima'],
    'edadMax': r['edad_maxima'],
    'activo': r['activo'],
    'creadoEn': r['creado_en'],
  };
}

Map<String, dynamic> _toBackendPatch({
  String? nombre,
  int? edadMin,
  int? edadMax,
  bool? activa,
}) {
  final map = <String, dynamic>{};
  if (nombre != null) map['nombre_categoria'] = nombre;
  if (edadMin != null) map['edad_minima'] = edadMin;
  if (edadMax != null) map['edad_maxima'] = edadMax;
  if (activa != null) map['activo'] = activa;
  return map;
}

class CategoriasRepository {
  final HttpClient _http;
  CategoriasRepository(this._http);

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Lista completa (sin paginar) mapeada
  Future<List<Map<String, dynamic>>> todos() async {
    try {
      final res = await _http.get(
        Endpoints.categorias,
        headers: _headers,
      );
      final List data = (res is List) ? res : (res['data'] ?? []) as List;
      return data.cast<Map<String, dynamic>>().map(_catFromBackend).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// ⚠️ NUEVO: Solo categorías activas (mapeadas completas).
  Future<List<Map<String, dynamic>>> activas() async {
    final all = await todos();
    return all.where((e) => e['activo'] == true).toList();
  }

  /// Lista simple para combos: [{id, nombre}] solo activas.
  Future<List<Map<String, dynamic>>> simpleList() async {
    final all = await todos();
    return all
        .where((e) => e['activo'] == true)
        .map((e) => {'id': e['id'], 'nombre': e['nombre']})
        .toList();
  }

    /// Alias para compatibilidad con pantallas que esperan este nombre.
  /// Devuelve [{id, nombre}] SOLO de categorías activas.
  Future<List<Map<String, dynamic>>> listarActivas() async {
    return await simpleList();
  }



  /// Paginado tolerante a diferentes formatos
  Future<Map<String, dynamic>> paged({
    int page = 1,
    int pageSize = 20,
    String? q,
    String sort = 'nombre_categoria',
    String order = 'asc',
    bool? onlyActive,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
        'sort': sort,
        'order': order,
      };
      if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
      if (onlyActive != null) params['onlyActive'] = onlyActive ? 'true' : 'false';

      final resp = await _http.getWithHeaders(
        Endpoints.categorias,
        headers: _headers,
        query: params,
      );

      final headers = (resp['headers'] ?? const <String, String>{}) as Map;
      final data = resp['data'];

      List<Map<String, dynamic>> items = const <Map<String, dynamic>>[];
      int? totalFromHeader;
      final th = headers['x-total-count'] ??
          headers['X-Total-Count'] ??
          headers['X-total-count'] ??
          headers['x-Total-Count'];
      if (th != null) totalFromHeader = int.tryParse(th.toString());

      if (data is List) {
        items = data.cast<Map<String, dynamic>>().map(_catFromBackend).toList();
        return {
          'items': items,
          'total': totalFromHeader ?? items.length,
          'page': page,
          'pageSize': pageSize,
        };
      } else if (data is Map<String, dynamic>) {
        final rawItems = (data['items'] ?? const []) as List;
        items = rawItems.cast<Map<String, dynamic>>().map(_catFromBackend).toList();
        final total = (data['total'] is int)
            ? data['total'] as int
            : int.tryParse('${data['total']}') ?? items.length;
        return {
          'items': items,
          'total': totalFromHeader ?? total,
          'page': data['page'] ?? page,
          'pageSize': data['pageSize'] ?? pageSize,
        };
      } else if (data is String) {
        final _ = jsonDecode(data); // valida
        return await paged(
          page: page,
          pageSize: pageSize,
          q: q,
          sort: sort,
          order: order,
          onlyActive: onlyActive,
        );
      }

      return {
        'items': items,
        'total': totalFromHeader ?? 0,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> crear({
    required String nombre,
    int? edadMin,
    int? edadMax,
    bool? activa,
  }) async {
    final payload = _toBackendPatch(
      nombre: nombre,
      edadMin: edadMin,
      edadMax: edadMax,
      activa: activa,
    );

    try {
      final res = await _http.post(
        Endpoints.categorias,
        headers: _headers,
        body: payload,
      );
      final Map<String, dynamic> data =
          (res is Map<String, dynamic>) ? res : (res['data'] as Map<String, dynamic>);
      return _catFromBackend(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update({
    required int idCategoria,
    String? nombre,
    int? edadMin,
    int? edadMax,
    bool? activa,
  }) async {
    final payload = _toBackendPatch(
      nombre: nombre,
      edadMin: edadMin,
      edadMax: edadMax,
      activa: activa,
    );

    try {
      final res = await _http.put(
        Endpoints.categoriaId(idCategoria),
        headers: _headers,
        body: payload,
      );
      final Map<String, dynamic> data =
          (res is Map<String, dynamic>) ? res : (res['data'] as Map<String, dynamic>);
      return _catFromBackend(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> remove(int idCategoria) async {
    try {
      await _http.delete(
        Endpoints.categoriaId(idCategoria),
        headers: _headers,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> activate(int idCategoria) async {
    try {
      await _http.post(
        Endpoints.categoriaActivar(idCategoria),
        headers: _headers,
      );
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> deactivate(int idCategoria) async {
    try {
      await _http.delete(
        Endpoints.categoriaId(idCategoria),
        headers: _headers,
      );
    } catch (e) {
      
      rethrow;
    }
  }
}
