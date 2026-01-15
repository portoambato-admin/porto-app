// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/url_strategy.dart';
import 'app/app_scope.dart';
import 'app/app_router.dart';

import 'core/state/auth_state.dart';
import 'core/state/app_settings_state.dart';
import 'core/rbac/permissions_store.dart';
import 'core/rbac/permission_gate.dart';
import 'core/rbac/permissions_warmup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // =========================================
  // INICIALIZAR FIREBASE
  // =========================================
  try {
    if (kIsWeb) {
      // ✅ Para Web: configuración explícita
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCfmXWL00Z5PQFdIT0rNVnFwVdmSDnLNXo",
          authDomain: "autenticacion-porto.firebaseapp.com",
          projectId: "autenticacion-porto",
          storageBucket: "autenticacion-porto.appspot.com",
          messagingSenderId: "71788233162",
          appId: "1:71788233162:web:b2b30ca027aeb60d06cf33",
        ),
      );
    } else {
      // ✅ Para Android/iOS: usa google-services.json / GoogleService-Info.plist
      await Firebase.initializeApp();
    }
    
    
  }catch(e){
    throw e;
  }

  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';
  setAppUrlStrategy();

  runApp(const PortoAmbatoApp());
}

class PortoAmbatoApp extends StatefulWidget {
  const PortoAmbatoApp({super.key});
  static const primary = Color(0xFF0D47A1);
  static const secondary = Color(0xFFFFC107);

  @override
  State<PortoAmbatoApp> createState() => _PortoAmbatoAppState();
}

class _PortoAmbatoAppState extends State<PortoAmbatoApp> {
  final AppSettingsState _settings = AppSettingsState();

  @override
  void initState() {
    super.initState();
    // Carga asíncrona (no bloquea el arranque). Al completar, notifica y
    // el MaterialApp se reconstruye con la configuración real.
    _settings.load();
  }

  @override
  Widget build(BuildContext context) {
    // Montamos los providers de app, auth, permisos y settings.
    return AppScope(
      child: Builder(
        builder: (ctx) {
          // Reutilizamos el MISMO HttpClient y el MISMO TokenProvider singleton
          final http = AppScope.of(ctx).http; // creado con SessionTokenProvider.instance
          final auth = AuthState(http);

          return AppSettingsScope(
            controller: _settings,
            child: AuthScope(
              controller: auth,
              child: PermissionsHost(
                store: PermissionsStore(http),
                child: const PermissionsWarmup(
                  child: _AppRoot(), // <- aquí vive el MaterialApp real
                ),
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
    final settings = AppSettingsScope.of(context);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: PortoAmbatoApp.primary,
      primary: PortoAmbatoApp.primary,
      secondary: PortoAmbatoApp.secondary,
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: PortoAmbatoApp.primary,
      primary: PortoAmbatoApp.primary,
      secondary: PortoAmbatoApp.secondary,
      brightness: Brightness.dark,
    );

    final baseText = GoogleFonts.poppinsTextTheme();
    final darkBaseText = GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    final baseTheme = ThemeData(
      colorScheme: lightScheme,
      textTheme: baseText,
      useMaterial3: true,
      visualDensity: settings.compactDensity
          ? VisualDensity.compact
          : VisualDensity.standard,
    );

    final darkTheme = ThemeData(
      colorScheme: darkScheme,
      textTheme: darkBaseText,
      useMaterial3: true,
      visualDensity: settings.compactDensity
          ? VisualDensity.compact
          : VisualDensity.standard,
    );

    return MaterialApp(
      title: 'PortoAmbato | Academia Oficial de Fútbol',
      debugShowCheckedModeBanner: false,
      theme: baseTheme,
      darkTheme: darkTheme,
      themeMode: settings.themeMode,
      builder: (context, child) {
        // Config global: escalado de texto (accesibilidad)
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaleFactor: settings.textScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
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