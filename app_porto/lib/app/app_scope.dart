// lib/app/app_scope.dart
import 'package:flutter/widgets.dart';

import '../core/network/http_client.dart';
import '../core/services/session_token_provider.dart';

import '../features/auth/data/auth_repository.dart';

// Repos de Admin
import '../features/admin/data/usuarios_repository.dart';
import '../features/admin/data/categorias_repository.dart';

class AppScope extends InheritedWidget {
  final HttpClient http;
  final AuthRepository auth;

  // Exponemos repos de dominio
  final UsuariosRepository usuarios;
  final CategoriasRepository categorias; // ⬅️ NUEVO

  AppScope._({
    required this.http,
    required this.auth,
    required this.usuarios,
    required this.categorias, // ⬅️ NUEVO
    required super.child,
  });

  factory AppScope({required Widget child}) {
    final http = HttpClient(tokenProvider: SessionTokenProvider());
    final auth = AuthRepository(http);

    final usuarios   = UsuariosRepository(http);
    final categorias = CategoriasRepository(http); // ⬅️ NUEVO

    return AppScope._(
      http: http,
      auth: auth,
      usuarios: usuarios,
      categorias: categorias, // ⬅️ NUEVO
      child: child,
    );
  }

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
