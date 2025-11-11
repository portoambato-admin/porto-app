// lib/core/rbac/permission_gate.dart
import 'package:flutter/widgets.dart';
import 'permissions_store.dart';

class _PermissionsInherited extends InheritedWidget {
  final PermissionsStore store;
  const _PermissionsInherited({required this.store, required super.child});

  static _PermissionsInherited of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<_PermissionsInherited>();
    assert(w != null, 'PermissionsHost no está en el árbol widget.');
    return w!;
  }

  @override
  bool updateShouldNotify(_PermissionsInherited oldWidget) => store != oldWidget.store;
}

class PermissionsHost extends StatelessWidget {
  final PermissionsStore store;
  final Widget child;
  const PermissionsHost({super.key, required this.store, required this.child});

  @override
  Widget build(BuildContext context) {
    return _PermissionsInherited(store: store,   child: child);
  }
}

/// Helper público para acceder al store desde cualquier widget
class Permissions {
  static PermissionsStore of(BuildContext context) =>
      _PermissionsInherited.of(context).store;
}

/// Compuerta declarativa para roles/permisos
class PermissionGate extends StatelessWidget {
  final List<String> roles; // alguno
  final List<String> all;   // todos
  final List<String> any;   // alguno
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    this.roles = const [],
    this.all = const [],
    this.any = const [],
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final store = Permissions.of(context);
    final ok = store.can(roles: roles, all: all, any: any);
    return ok ? child : (fallback ?? const SizedBox.shrink());
  }
}
