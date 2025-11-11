// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/url_strategy.dart';
import 'app/app_scope.dart';
import 'app/app_router.dart';


import 'core/state/auth_state.dart';
import 'core/rbac/permissions_store.dart';
import 'core/rbac/permission_gate.dart';
import 'core/rbac/permissions_warmup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';

  setAppUrlStrategy();

  runApp(const PortoAmbatoApp());
}

class PortoAmbatoApp extends StatelessWidget {
  const PortoAmbatoApp({super.key});
  static const primary = Color(0xFF0D47A1);
  static const secondary = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    // Montamos los providers de app, auth y permisos
    return AppScope(
      child: Builder(
        builder: (ctx) {
          // Reutilizamos el MISMO HttpClient y el MISMO TokenProvider singleton
          final http = AppScope.of(ctx).http; // creado con SessionTokenProvider.instance
          final auth = AuthState(http)..load();

          return AuthScope(
            controller: auth,
            child: PermissionsHost(
              store: PermissionsStore(http),
              child: const PermissionsWarmup(
                child: _AppRoot(), // <- aquí vive el MaterialApp real
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PortoAmbatoApp.primary,
      primary: PortoAmbatoApp.primary,
      secondary: PortoAmbatoApp.secondary,
    );

    return MaterialApp(
      title: 'PortoAmbato | Academia Oficial de Fútbol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en')],
      initialRoute: '/', // Home pública
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const _HomeFallback()),
    );
  }
}

class _HomeFallback extends StatelessWidget {
  const _HomeFallback();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Cargando inicio…')),
    );
  }
}
