import 'package:flutter/foundation.dart';
import '../network/http_client.dart';
import '../network/api_error.dart';
import 'rbac_endpoints.dart';

class PermissionsStore extends ChangeNotifier {
  final HttpClient http;
  PermissionsStore(this.http);

  String? _role;                  // 'admin', 'staff', 'profesor'
  final Set<String> _perms = {};  // 'roles.read', 'usuarios.create', etc.

  String? get role => _role;
  List<String> get permissions => _perms.toList(growable: false);

  bool hasRole(String r) => _role?.toLowerCase() == r.toLowerCase();
  bool hasAnyRole(Iterable<String> roles) => roles.any((r) => hasRole(r));

  bool hasPerm(String p) => _perms.contains(p);
  bool hasAll(Iterable<String> ps) => ps.every(_perms.contains);
  bool hasAny(Iterable<String> ps) => ps.any(_perms.contains);

  bool can({List<String> roles = const [], List<String> all = const [], List<String> any = const []}) {
    if (roles.isNotEmpty && !hasAnyRole(roles)) return false;
    if (all.isNotEmpty && !hasAll(all)) return false;
    if (any.isNotEmpty && !hasAny(any)) return false;
    return true;
  }

  /// GET /rbac/me/permisos → { rol, permisos[] }
  /// Tolerante a 401 para no tumbar la app cuando no hay sesión.
  Future<void> refresh() async {
    try {
      final data = await http.get(RbacEndpoints.mePermisos, headers: const {});
      final m = Map<String, dynamic>.from(data as Map);
      _role = (m['rol'] as String?)?.toLowerCase();
      _perms
        ..clear()
        ..addAll(((m['permisos'] as List?) ?? const []).map((e) => e.toString()));
    } on ApiError catch (e) {
      if (e.status == 401) {
        // Sin token o inválido: deja el store vacío y sigue
        _role = null;
        _perms.clear();
      } else {
        debugPrint('[PermissionsStore] refresh error: $e');
      }
    } catch (e) {
      debugPrint('[PermissionsStore] unexpected: $e');
      _role = null;
      _perms.clear();
    } finally {
      notifyListeners();
    }
  }

  void clear() {
    _role = null;
    _perms.clear();
    notifyListeners();
  }
}
