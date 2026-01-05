
import '../../../core/constants/endpoints.dart';
import '../../../core/network/http_client.dart';
import '../../../core/network/api_error.dart';
import '../models/usuario_model.dart';

class UsuariosRepository {
  final HttpClient _http;
  const UsuariosRepository(this._http);

  // ============================================================
  // MÉTODOS PAGINADOS (Optimizados)
  // ============================================================

  /// Método privado unificado para todas las llamadas paginadas
  Future<PagedResult<Usuario>> _fetchPaged({
    required int page,
    required int pageSize,
    String? q,
    required String sort,
    required String order,
    String path = '',
  }) async {
    try {
      // Validación de entrada
      if (page < 1) throw ArgumentError('page debe ser >= 1');
      if (pageSize < 1 || pageSize > 100) {
        throw ArgumentError('pageSize debe estar entre 1 y 100');
      }

      final qp = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
        'sort': sort,
        'order': order,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      };

      final res = await _http.getWithHeaders(
        '${Endpoints.usuarios}$path',
        query: qp,
      );

      final data = res['data'];
      final headers = (res['headers'] as Map).cast<String, String>();

      // Parsing robusto de items
      final List<Usuario> items = (data is List)
          ? data
              .map((e) {
                try {
                  return Usuario.fromJson(Map<String, dynamic>.from(e));
                } catch (e) {
                  return null;
                }
              })
              .whereType<Usuario>() // Filtra nulos
              .toList()
          : [];

      // Obtener total del header
      final totalStr = headers['x-total-count'];
      final total = int.tryParse(totalStr ?? '') ?? items.length;

      return PagedResult(items: items, total: total);
    } on ApiError {
      rethrow; // Propagamos errores de API
    } catch (e) {
      throw ApiError('Error obteniendo usuarios: ${e.toString()}');
    }
  }

  /// Obtener todos los usuarios (paginado)
  Future<PagedResult<Usuario>> pagedTodos({
    int page = 1,
    int pageSize = 10,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      _fetchPaged(
        page: page,
        pageSize: pageSize,
        q: q,
        sort: sort,
        order: order,
        path: '',
      );

  /// Obtener usuarios activos (paginado)
  Future<PagedResult<Usuario>> pagedActivos({
    int page = 1,
    int pageSize = 10,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      _fetchPaged(
        page: page,
        pageSize: pageSize,
        q: q,
        sort: sort,
        order: order,
        path: '/activos',
      );

  /// Obtener usuarios inactivos (paginado)
  Future<PagedResult<Usuario>> pagedInactivos({
    int page = 1,
    int pageSize = 10,
    String? q,
    String sort = 'creado_en',
    String order = 'desc',
  }) =>
      _fetchPaged(
        page: page,
        pageSize: pageSize,
        q: q,
        sort: sort,
        order: order,
        path: '/inactivos',
      );

  // ============================================================
  // CRUD (Optimizado con validaciones)
  // ============================================================

  /// Crear nuevo usuario
  Future<Usuario> create({
    required String nombre,
    required String correo,
    required int idRol,
    required String password,
    String? cedula,
  }) async {
    try {
      // Validación de entrada
      if (nombre.trim().length < 3) {
        throw ArgumentError('El nombre debe tener al menos 3 caracteres');
      }
      if (!_isValidEmail(correo)) {
        throw ArgumentError('El correo no es válido');
      }
      if (password.length < 6) {
        throw ArgumentError('La contraseña debe tener al menos 6 caracteres');
      }

      final body = {
        'nombre': nombre.trim(),
        'correo': correo.trim().toLowerCase(),
        'id_rol': idRol,
        'password': password,
        'activo': true,
        if (cedula != null && cedula.isNotEmpty) 'cedula': cedula.trim(),
      };

      final res = await _http.post(Endpoints.usuarios, body: body);

      // El backend puede devolver el usuario creado
      if (res is Map) {
        return Usuario.fromJson(Map<String, dynamic>.from(res));
      }

      // Si no devuelve el usuario, retornamos uno básico
      return Usuario(
        id: 0,
        nombre: nombre.trim(),
        correo: correo.trim().toLowerCase(),
        rol: UserRole.fromId(idRol),
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error creando usuario: ${e.toString()}');
    }
  }

  /// Actualizar usuario existente
  Future<Usuario> update({
    required int idUsuario,
    String? nombre,
    String? correo,
    int? idRol,
    String? cedula,
    bool? activo,
  }) async {
    try {
      // Validación de entrada
      if (nombre != null && nombre.trim().length < 3) {
        throw ArgumentError('El nombre debe tener al menos 3 caracteres');
      }
      if (correo != null && !_isValidEmail(correo)) {
        throw ArgumentError('El correo no es válido');
      }

      final body = <String, dynamic>{
        if (nombre != null) 'nombre': nombre.trim(),
        if (correo != null) 'correo': correo.trim().toLowerCase(),
        if (idRol != null) 'id_rol': idRol,
        if (cedula != null) 'cedula': cedula.trim(),
        if (activo != null) 'activo': activo,
      };

      // Solo hacer la petición si hay cambios
      if (body.isEmpty) {
        throw ArgumentError('No hay cambios para actualizar');
      }

      final res = await _http.put(Endpoints.usuarioId(idUsuario), body: body);

      // Intentar devolver el usuario actualizado
      if (res is Map) {
        return Usuario.fromJson(Map<String, dynamic>.from(res));
      }

      // Fallback: devolver usuario básico
      return Usuario(
        id: idUsuario,
        nombre: nombre ?? '',
        correo: correo ?? '',
        rol: UserRole.fromId(idRol),
      );
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error actualizando usuario: ${e.toString()}');
    }
  }

  /// Desactivar usuario (soft delete)
  Future<void> remove(int idUsuario) async {
    try {
      await _http.delete(Endpoints.usuarioId(idUsuario));
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error desactivando usuario: ${e.toString()}');
    }
  }

  /// Activar usuario
  Future<void> activate(int idUsuario) async {
    try {
      await _http.post(Endpoints.usuarioActivar(idUsuario), body: const {});
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error activando usuario: ${e.toString()}');
    }
  }

  // ============================================================
  // MÉTODOS AUXILIARES (Sin paginación - para dropdowns, etc)
  // ============================================================

  /// Buscar usuarios (para autocomplete/selects)
  Future<List<Usuario>> search({
    required String query,
    int limit = 10,
    bool activosOnly = true,
  }) async {
    try {
      final qp = <String, String>{
        'q': query.trim(),
        'limit': '$limit',
        if (activosOnly) 'activosOnly': 'true',
      };

      final data = await _http.get(
        '${Endpoints.usuarios}/buscar',
        query: qp,
      );

      return (data as List)
          .map((e) => Usuario.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error buscando usuarios: ${e.toString()}');
    }
  }

  /// Obtener un usuario por ID
  Future<Usuario> getById(int idUsuario) async {
    try {
      final data = await _http.get(Endpoints.usuarioId(idUsuario));
      return Usuario.fromJson(Map<String, dynamic>.from(data));
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError('Error obteniendo usuario: ${e.toString()}');
    }
  }

  // ============================================================
  // VALIDACIONES PRIVADAS
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }
}

