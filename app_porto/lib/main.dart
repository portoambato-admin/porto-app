import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'router.dart';
import 'state/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';
  if (kIsWeb) setUrlStrategy(PathUrlStrategy());
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
  late final AuthState _auth = AuthState();

  @override
  void initState() {
    super.initState();
    _auth.load(); // carga sesión si existe
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: PortoAmbatoApp.primary,
      primary: PortoAmbatoApp.primary,
      secondary: PortoAmbatoApp.secondary,
    );

    final app = MaterialApp(
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
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const _HomeFallback()),
    );

    return AuthScope(controller: _auth, child: app);
  }
}

class _HomeFallback extends StatelessWidget {
  const _HomeFallback();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Cargando inicio…')));
  }
}
