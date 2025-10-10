// lib/app/app_router.dart
import 'package:app_porto/features/admin/sections/evaluaciones_screen.dart';
import 'package:flutter/material.dart';

// Rutas
import '../core/constants/route_names.dart';

// Home (NO diferido)
import '../features/public/presentation/screen/home_screen.dart';

// PÚBLICAS diferidas (lazy) — ¡ojo con los alias, evita 'new'!
import '../features/public/presentation/screen/store_screen.dart' deferred as store;
import '../features/public/presentation/screen/events_screen.dart' deferred as events;
import '../features/public/presentation/screen/categories_screen.dart' deferred as categories;
import '../features/public/presentation/screen/benefits_screen.dart' deferred as benefits;
import '../features/public/presentation/screen/about_screen.dart' deferred as about;

// Auth
import '../features/auth/presentation/screens/auth_screen.dart';

// Perfil / Panel (NO diferido)
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/admin/presentation/panel/panel_screen.dart';

// Admin: secciones (NO lazy, protegidas)
import '../features/admin/sections/usuarios_screen.dart';
import '../features/admin/sections/asistencias_screen.dart';
import '../features/admin/sections/categorias_screen.dart';
import '../features/admin/sections/config_screen.dart';
import '../features/admin/sections/admin_pagos_screen.dart' show AdminPagosScreen;

import '../features/admin/presentation/profesores/profesores_screen.dart';
import '../features/admin/sections/estudiantes_screen.dart';
import '../features/admin/sections/estudiante_detail_screen.dart';

// Subcategorías: listado y detalle

import '../features/admin/sections/subcategorias_screen.dart'
  show SubcategoriaEstudiantesScreen;

import '../features/admin/sections/admin_subcategorias_screen.dart' show AdminSubcategoriasScreen;
// Sesión
import '../core/services/session.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final name = s.name ?? RouteNames.root;

    switch (name) {
      // ======= Públicas 
      case RouteNames.root:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteNames.tienda:
        return _loadDeferred(
          s,
          loader: store.loadLibrary(),
          screenBuilder: () => store.StoreScreen(),
        );

      case RouteNames.eventos:
        return _loadDeferred(
          s,
          loader: events.loadLibrary(),
          screenBuilder: () => events.EventsScreen(),
        );

      case RouteNames.categorias:
        return _loadDeferred(
          s,
          loader: categories.loadLibrary(),
          screenBuilder: () => categories.CategoriesScreen(),
        );

      case RouteNames.beneficios:
        return _loadDeferred(
          s,
          loader: benefits.loadLibrary(),
          screenBuilder: () => benefits.BenefitsScreen(),
        );

      case RouteNames.conocenos:
        return _loadDeferred(
          s,
          loader: about.loadLibrary(),
          screenBuilder: () => about.AboutScreen(),
        );

      // ======= Auth 
      case RouteNames.auth:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const AuthScreen(),
        );

      // ======= Protegidas (no lazy) =======
      case RouteNames.perfil:
        return _guardedPlain(s, builder: (_) => const ProfileScreen());

      case RouteNames.panel:
        return _guardedPlain(s, builder: (_) => const PanelScreen());

      case RouteNames.adminUsuarios:
        return _guardedPlain(s, builder: (_) => const UsuariosScreen());

      case RouteNames.adminProfesores:
        return _guardedPlain(s, builder: (_) => const ProfesoresScreen());

      case RouteNames.adminCategorias:
        return _guardedPlain(s, builder: (_) => const AdminCategoriasScreen());

      case RouteNames.adminSubcategorias:
  return _guardedPlain(s, builder: (_) => const AdminSubcategoriasScreen());

      case RouteNames.adminAsistencias:
        return _guardedPlain(s, builder: (_) => const AdminAsistenciasScreen());

      case RouteNames.adminEvaluaciones:
        return _guardedPlain(s, builder: (_) => const AdminEvaluacionesScreen());

      case RouteNames.adminPagos:
        return _guardedPlain(s, builder: (_) => const AdminPagosScreen());

      case RouteNames.adminConfig:
        return _guardedPlain(s, builder: (_) => const AdminConfigScreen());

      case RouteNames.adminEstudiantes:
        return _guardedPlain(s, builder: (_) => const AdminEstudiantesScreen());

      case RouteNames.adminEstudianteDetalle:
        return _guardedPlain(s, builder: (_) {
          final args = s.arguments;
          int? id;
          if (args is Map && args['id'] != null) {
            final v = args['id'];
            if (v is int) id = v;
            else if (v is num) id = v.toInt();
            else if (v is String) id = int.tryParse(v);
          }
          if (id == null) {
            return const _ArgsErrorPage('Falta argumento: id (int)');
          }
          return EstudianteDetailScreen(id: id);
        });

      // ======= Subcategoría → Estudiantes (detalle) =======
      case RouteNames.adminSubcatEstudiantes:
        return _guardedPlain(s, builder: (_) {
          final args = s.arguments is Map ? Map<String, dynamic>.from(s.arguments as Map) : <String, dynamic>{};
          final idSubcat = _arg<int>(args, 'idSubcategoria');
          final nombre   = _arg<String>(args, 'nombreSubcategoria');
          final idCat    = _arg<int>(args, 'idCategoria'); // opcional
          if (idSubcat == null || nombre == null) {
            return const _ArgsErrorPage('Faltan argumentos: idSubcategoria (int) y nombreSubcategoria (String)');
          }
          return SubcategoriaEstudiantesScreen(
            idSubcategoria: idSubcat,
            nombreSubcategoria: nombre,
            idCategoria: idCat,
          );
        });

      // ======= 404 =======
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('404 — Ruta no encontrada')),
          ),
        );
    }
  }

  // ===== Helpers =====
  static Route<dynamic> _loadDeferred(
    RouteSettings s, {
    required Future<void> loader,
    required Widget Function() screenBuilder,
  }) {
    return MaterialPageRoute(
      settings: s,
      builder: (_) => FutureBuilder<void>(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.done) {
            return screenBuilder();
          }
          return const _LoadingPage();
        },
      ),
    );
  }

  static Route<dynamic> _guardedPlain(
    RouteSettings s, {
    required WidgetBuilder builder,
  }) {
    final String redirectTo = s.name ?? RouteNames.root;

    return MaterialPageRoute(
      settings: s,
      builder: (ctx) => FutureBuilder<String?>(
        future: Session.getToken(),
        builder: (ctx, tokenSnap) {
          if (tokenSnap.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }
          final token = tokenSnap.data;

          if (RouteNames.guarded.contains(redirectTo) && token == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(ctx).pushNamedAndRemoveUntil(
                RouteNames.auth,
                (r) => false,
                arguments: {'redirectTo': redirectTo},
              );
            });
            return const _LoadingPage();
          }

          return builder(ctx);
        },
      ),
    );
  }

  static T? _arg<T>(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    if (T == int && v is num) return v.toInt() as T;
    if (v is T) return v;
    if (T == int && v is String) return int.tryParse(v) as T?;
    if (T == String) return v.toString() as T;
    return null;
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ArgsErrorPage extends StatelessWidget {
  final String message;
  const _ArgsErrorPage(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error de argumentos')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
