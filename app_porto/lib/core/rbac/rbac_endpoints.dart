// lib/core/rbac/rbac_endpoints.dart
abstract class RbacEndpoints {
  static const mePermisos = '/rbac/me/permisos';
  static const roles = '/rbac/roles';
  static String rolPermisos(int idRol) => '/rbac/roles/$idRol/permisos';
  static const permisos = '/rbac/permisos';
}
