import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 👇 Esta es la importación correcta en tu caso
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';

  // Solo en web para evitar conflictos en móvil
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
    // Si quieres usar hash (sin configurar Render), sería:
    // setUrlStrategy(const HashUrlStrategy());
  }

  runApp(const PortoAmbatoApp());
}

class PortoAmbatoApp extends StatelessWidget {
  const PortoAmbatoApp({super.key});

  static const primary = Color(0xFF0D47A1);
  static const secondary = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
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
      initialRoute: '/',
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
