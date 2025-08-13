import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'screens/home_screen.dart';
import 'screens/store_screen.dart';
import 'screens/events_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/benefits_screen.dart';
import 'screens/about_screen.dart';

Future<void> main() async {                // <- Asegúrate que exista esta función
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  Intl.defaultLocale = 'es';
  runApp(const PortoAmbatoApp());
}

class PortoAmbatoApp extends StatelessWidget {
  const PortoAmbatoApp({super.key});

  static const primary = Color(0xFF0D47A1);
  static const secondary = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary);
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
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/tienda': (_) => const StoreScreen(),
        '/eventos': (_) => const EventsScreen(),
        '/categorias': (_) => const CategoriesScreen(),
        '/beneficios':(_) => const BenefitsScreen(),
        '/conocenos': (_) => const AboutScreen(), // NUEVA

      },
    );
  }
}
