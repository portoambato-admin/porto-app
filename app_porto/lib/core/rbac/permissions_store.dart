import 'package:flutter/foundation.dart';
import '../network/http_client.dart';
import '../network/api_error.dart';
import '../services/session_token_provider.dart';
import 'rbac_endpoints.dart';

class PermissionsStore extends ChangeNotifier {
  final HttpClient http;
  PermissionsStore(this.http);

  String? _role;
  final Set<String> _perms = {};

  String? get role => _role;
  List<String> get permissions => _perms.toList(growable: false);

  bool hasRole(String r) => _role?.toLowerCase() == r.toLowerCase();
  bool hasAnyRole(Iterable<String> roles) => roles.any((r) => hasRole(r));

  bool hasPerm(String p) => _perms.contains(p);
  bool hasAll(Iterable<String> ps) => ps.every(_perms.contains);
  bool hasAny(Iterable<String> ps) => ps.any(_perms.contains);

  bool can({
    List<String> roles = const [],
    List<String> all = const [],
    List<String> any = const []
  }) {
    if (roles.isNotEmpty && !hasAnyRole(roles)) return false;
    if (all.isNotEmpty && !hasAll(all)) return false;
    if (any.isNotEmpty && !hasAny(any)) return false;
    return true;
  }

  /// GET /rbac/me/permisos → { rol, permisos[] }
  Future<void> refresh() async {
    try {
      // Verificar que haya token ANTES de hacer la petición
      final token = await SessionTokenProvider.instance.readToken();
      debugPrint('[PermissionsStore] 🔄 Refrescando permisos...');
      debugPrint('[PermissionsStore] 🔑 Token disponible: ${token?.substring(0, 20) ?? "null"}...');
      
      if (token == null || token.isEmpty) {
        debugPrint('[PermissionsStore] ⚠️ No hay token, limpiando permisos');
        _role = null;
        _perms.clear();
        notifyListeners();
        return;
      }

      final data = await http.get(RbacEndpoints.mePermisos);
      debugPrint('[PermissionsStore] 📦 Respuesta recibida: $data');

      final m = Map<String, dynamic>.from(data as Map);
      _role = (m['rol'] as String?)?.toLowerCase();
      _perms
        ..clear()
        ..addAll(((m['permisos'] as List?) ?? const []).map((e) => e.toString()));

      debugPrint('[PermissionsStore] ✅ Rol: $_role');
      debugPrint('[PermissionsStore] ✅ Permisos: ${_perms.length} permisos cargados');

    } on UnauthorizedException catch (e) {
      debugPrint('[PermissionsStore] 🔥 Sesión expirada: $e');
      _role = null;
      _perms.clear();

    } on ApiError catch (e) {
      if (e.status == 401) {
        debugPrint('[PermissionsStore] 🔥 API 401: ${e.message}');
        _role = null;
        _perms.clear();
      } else {
        debugPrint('[PermissionsStore] ❌ Error API ${e.status}: ${e.message}');
        // Para otros errores, podríamos mantener los permisos existentes
        // o limpiarlos dependiendo de la lógica de negocio
      }

    } catch (e) {
      debugPrint('[PermissionsStore] ❌ Error inesperado: $e');
      debugPrint('[PermissionsStore] Stack trace: ${StackTrace.current}');
      // No limpiamos los permisos en caso de error de red
    } finally {
      notifyListeners();
    }
  }

  void clear() {
    debugPrint('[PermissionsStore] 🧹 Limpiando permisos');
    _role = null;
    _perms.clear();
    notifyListeners();
  }
}