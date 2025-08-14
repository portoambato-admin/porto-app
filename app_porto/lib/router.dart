// lib/router.dart
import 'package:flutter/material.dart';

// Home se carga normal (no diferido)
import 'screens/home_screen.dart';

// El resto se carga diferido (lazy)
import 'screens/store_screen.dart' deferred as store;
import 'screens/events_screen.dart' deferred as events;
import 'screens/categories_screen.dart' deferred as categories;
import 'screens/benefits_screen.dart' deferred as benefits;
import 'screens/about_screen.dart' deferred as about;

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case '/tienda':
        return _loadDeferred(store.loadLibrary(), store.StoreScreen());
      case '/eventos':
        return _loadDeferred(events.loadLibrary(), events.EventsScreen());
      case '/categorias':
        return _loadDeferred(categories.loadLibrary(), categories.CategoriesScreen());
      case '/beneficios':
        return _loadDeferred(benefits.loadLibrary(), benefits.BenefitsScreen());
      case '/conocenos':
        return _loadDeferred(about.loadLibrary(), about.AboutScreen());
      case '/':
      default:
        // Home no es diferida, aquí sí puedes usar const si tu constructor lo permite
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  static MaterialPageRoute _loadDeferred(Future<void> loader, Widget screen) {
    return MaterialPageRoute(
      builder: (_) => FutureBuilder(
        future: loader,
        builder: (_, snap) =>
            snap.connectionState == ConnectionState.done
                ? screen
                : const _LoadingPage(),
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
