// lib/core/rbac/permissions_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/http_client.dart';
import 'rbac_endpoints.dart';

class PermissionsStore extends ChangeNotifier {
  final HttpClient http;
  PermissionsStore(this.http);

  String? _role;                  // ej: 'admin', 'staff', 'profesor'
  final Set<String> _perms = {};  // ej: 'roles.read', 'usuarios.create'

  String? get role => _role;
  List<String> get permissions => _perms.toList(growable: false);

  bool hasRole(String r) => _role?.toLowerCase() == r.toLowerCase();
  bool hasAnyRole(Iterable<String> roles) =>
      roles.any((r) => hasRole(r));

  bool hasPerm(String p) => _perms.contains(p);
  bool hasAll(Iterable<String> ps) => ps.every(_perms.contains);
  bool hasAny(Iterable<String> ps) => ps.any(_perms.contains);

  /// Regla compuesta:
  /// - `roles`: si no está vacío, debe cumplir al menos un rol.
  /// - `all`: si no está vacío, debe cumplir todos esos permisos.
  /// - `any`: si no está vacío, debe cumplir al menos uno de esos permisos.
  bool can({List<String> roles = const [], List<String> all = const [], List<String> any = const []}) {
    if (roles.isNotEmpty && !hasAnyRole(roles)) return false;
    if (all.isNotEmpty && !hasAll(all)) return false;
    if (any.isNotEmpty && !hasAny(any)) return false;
    return true;
  }

  /// Llama GET /rbac/me/permisos → { rol, permisos[] }
  Future<void> refresh() async {
    final data = await http.get(RbacEndpoints.mePermisos, headers: const {});
    final m = Map<String, dynamic>.from(data as Map);
    _role = (m['rol'] as String?)?.toLowerCase();
    _perms
      ..clear()
      ..addAll(((m['permisos'] as List?) ?? const []).map((e) => e.toString()));
    notifyListeners();
  }

  void clear() {
    _role = null;
    _perms.clear();
    notifyListeners();
  }
}
