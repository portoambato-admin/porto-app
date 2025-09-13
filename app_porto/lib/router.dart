import 'package:flutter/material.dart';

// Home NO diferido
import 'screens/home_screen.dart';

// Diferidos (lazy)
import 'screens/store_screen.dart' deferred as store;
import 'screens/events_screen.dart' deferred as events;
import 'screens/categories_screen.dart' deferred as categories;
import 'screens/benefits_screen.dart' deferred as benefits;
import 'screens/about_screen.dart' deferred as about;

// Auth NO diferido
import 'screens/auth_screen.dart';

// Nuevos
import 'screens/profile_screen.dart';
import 'screens/panel_screen.dart';

// Sesión (para leer token)
import 'services/session.dart';

class AppRouter {
  // 🔒 Rutas protegidas (QUITÉ '/tienda')
  static final Set<String> _guardedPaths = {
    '/perfil',
    '/panel',
  };

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      // ✅ /tienda ahora es PÚBLICA
      case '/tienda':
        return _loadDeferred(
          s,
          loader: store.loadLibrary(),
          screenBuilder: () => store.StoreScreen(),
        );

      case '/eventos':
        return _loadDeferred(
          s,
          loader: events.loadLibrary(),
          screenBuilder: () => events.EventsScreen(),
        );

      case '/categorias':
        return _loadDeferred(
          s,
          loader: categories.loadLibrary(),
          screenBuilder: () => categories.CategoriesScreen(),
        );

      case '/beneficios':
        return _loadDeferred(
          s,
          loader: benefits.loadLibrary(),
          screenBuilder: () => benefits.BenefitsScreen(),
        );

      case '/conocenos':
        return _loadDeferred(
          s,
          loader: about.loadLibrary(),
          screenBuilder: () => about.AboutScreen(),
        );

      case '/perfil': // 🔒 protegida
        return _guardedPlain(
          s,
          builder: (_) => const ProfileScreen(),
        );

      case '/panel': // 🔒 protegida
        return _guardedPlain(
          s,
          builder: (_) => const PanelScreen(),
        );

      case '/auth':
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const AuthScreen(),
        );

      case '/':
      default:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const HomeScreen(),
        );
    }
  }

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

  /// Carga diferida con guard (requiere token)
  /// (La dejamos por si más adelante proteges alguna ruta lazy)
  static MaterialPageRoute _guardedDeferred(
    RouteSettings s, {
    required Future<void> loader,
    required Widget Function() screenBuilder,
  }) {
    final String redirectTo = s.name ?? '/';

    return MaterialPageRoute(
      settings: s,
      builder: (ctx) => FutureBuilder<String?>(
        future: Session.getToken(),
        builder: (ctx, tokenSnap) {
          if (tokenSnap.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }

          final token = tokenSnap.data;
          final isGuarded = _guardedPaths.contains(redirectTo);

          if (isGuarded && token == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(ctx, '/auth', arguments: {'redirectTo': redirectTo});
            });
            return const _LoadingPage();
          }

          return FutureBuilder<void>(
            future: loader,
            builder: (_, libSnap) {
              if (libSnap.connectionState != ConnectionState.done) {
                return const _LoadingPage();
              }
              return screenBuilder();
            },
          );
        },
      ),
    );
  }

  /// Ruta normal protegida (sin carga diferida)
  static MaterialPageRoute _guardedPlain(
    RouteSettings s, {
    required WidgetBuilder builder,
  }) {
    final String redirectTo = s.name ?? '/';

    return MaterialPageRoute(
      settings: s,
      builder: (ctx) => FutureBuilder<String?>(
        future: Session.getToken(),
        builder: (ctx, tokenSnap) {
          if (tokenSnap.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }
          final token = tokenSnap.data;
          final isGuarded = _guardedPaths.contains(redirectTo);

          if (isGuarded && token == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(ctx, '/auth', arguments: {'redirectTo': redirectTo});
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
