// lib/app/app_router.dart
import 'package:flutter/material.dart';

// Constantes de rutas
import '../core/constants/route_names.dart';

// Home (NO diferido)
import '../features/public/presentation/screen/home_screen.dart';

// PÚBLICAS diferidas (lazy)
import '../features/public/presentation/screen/store_screen.dart' deferred as store;
import '../features/public/presentation/screen/events_screen.dart' deferred as events;
import '../features/public/presentation/screen/categories_screen.dart' deferred as categories;
import '../features/public/presentation/screen/benefits_screen.dart' deferred as benefits;
import '../features/public/presentation/screen/about_screen.dart' deferred as about;

// Auth (NO diferido)
import '../features/auth/presentation/screens/auth_screen.dart';

// Perfil / Panel (NO diferido)
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/admin/presentation/panel/panel_screen.dart';

// Admin: secciones (NO lazy, protegidas)
import '../features/admin/sections/usuarios_screen.dart';
import '../features/admin/presentation/profesores/profesores_screen.dart';
import '../features/admin/sections/categorias_screen.dart';
import '../features/admin/sections/subcategorias_screen.dart';
import '../features/admin/sections/asistencias_screen.dart';
import '../features/admin/sections/evaluaciones_screen.dart';
import '../features/admin/sections/pagos_screen.dart';
import '../features/admin/sections/config_screen.dart';

// Sesión (para leer token)
import '../core/services/session.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    final name = s.name ?? RouteNames.root;

    switch (name) {
      // ======= Públicas (lazy) =======
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

      // ======= Auth =======
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

      // /admin/usuarios → UsuariosScreen
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

      // ======= Home por defecto =======
      case RouteNames.root:
      default:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const HomeScreen(),
        );
    }
  }

  // ---------- Helpers ----------

  /// Carga diferida normal (pública)
  static MaterialPageRoute _loadDeferred(
    RouteSettings s, {
    required Future<void> loader,
    required Widget Function() screenBuilder,
  }) {
    return MaterialPageRoute(
      settings: s,
      builder: (_) => FutureBuilder<void>(
        future: loader,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }
          return screenBuilder();
        },
      ),
    );
  }

  /// Ruta normal protegida (sin carga diferida)
  static MaterialPageRoute _guardedPlain(
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
              Navigator.pushNamed(ctx, RouteNames.auth, arguments: {'redirectTo': redirectTo});
            });
            return const _LoadingPage();
          }
          return builder(ctx);
        },
      ),
    );
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
