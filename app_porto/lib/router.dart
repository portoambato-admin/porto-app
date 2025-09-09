// lib/router.dart
import 'package:flutter/material.dart';

// Home NO diferido
import 'screens/home_screen.dart';

// Diferidos (lazy)
import 'screens/store_screen.dart' deferred as store;
import 'screens/events_screen.dart' deferred as events;
import 'screens/categories_screen.dart' deferred as categories;
import 'screens/benefits_screen.dart' deferred as benefits;
import 'screens/about_screen.dart' deferred as about;

// Auth NO diferido (ligero y se usa muy seguido)
import 'screens/auth_screen.dart';

// Sesión (para leer token)
import 'services/session.dart';

class AppRouter {
  // 🔒 Rutas protegidas (agrega/quita aquí)
  static final Set<String> _guardedPaths = {
    '/tienda',
    // '/categorias', '/eventos', etc. si quieres
  };

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case '/tienda':
        // ⚠️ protegida
        return _guardedDeferred(
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

  /// Carga diferida normal (sin guard)
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

  /// Carga diferida con guard de autenticación
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
          // 1) Espera el token
          if (tokenSnap.connectionState != ConnectionState.done) {
            return const _LoadingPage();
          }

          final token = tokenSnap.data;
          final isGuarded = _guardedPaths.contains(redirectTo);

          // 2) Si es ruta protegida y NO hay token → redirige a /auth con redirectTo
          if (isGuarded && token == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(
                ctx,
                '/auth',
                arguments: {'redirectTo': redirectTo},
              );
            });
            return const _LoadingPage();
          }

          // 3) Hay token o no es protegida → carga diferida del screen
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
