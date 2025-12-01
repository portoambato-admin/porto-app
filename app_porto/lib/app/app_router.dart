import 'package:flutter/material.dart';
import '../core/state/auth_state.dart'; 

// Roles
import '../features/admin/sections/roles_screen.dart' show RolesScreen;

// Rutas (constantes)
import '../core/constants/route_names.dart';

// Home (NO diferido)
import '../features/public/presentation/screen/home_screen.dart';

// PÚBLICAS diferidas (lazy)
import '../features/public/presentation/screen/store_screen.dart'
    deferred as store;
import '../features/public/presentation/screen/events_screen.dart'
    deferred as events;
import '../features/public/presentation/screen/categories_screen.dart'
    deferred as categories;
import '../features/public/presentation/screen/benefits_screen.dart'
    deferred as benefits;
import '../features/public/presentation/screen/about_screen.dart'
    deferred as about;

// Auth
import '../features/auth/presentation/screens/auth_screen.dart';

// 🔵 Recuperación de contraseña
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';

// Perfil / Panel (NO diferido)
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/admin/presentation/panel/panel_screen.dart';

// ===== Admin: Hubs =====
import '../features/admin/presentation/hubs/personas_hub_screen.dart';
import '../features/admin/presentation/hubs/academia_hub_screen.dart';
import '../features/admin/presentation/hubs/finanzas_hub_screen.dart';
import '../features/admin/presentation/hubs/sistema_hub_screen.dart';
import '../features/admin/presentation/hubs/reportes_hub_screen.dart';

// ===== Admin: secciones (NO lazy, protegidas) =====
import '../features/admin/sections/usuarios_screen.dart';
import '../features/admin/sections/asistencias_screen.dart';
import '../features/admin/sections/categorias_screen.dart'
    show AdminCategoriasScreen;
import '../features/admin/sections/config_screen.dart'
    show AdminConfigScreen;
import '../features/admin/sections/admin_pagos_screen.dart'
    show AdminPagosScreen;

import '../features/admin/presentation/profesores/profesores_screen.dart';
import '../features/admin/sections/estudiantes_screen.dart'
    show AdminEstudiantesScreen;
import '../features/admin/sections/estudiante_detail_screen.dart'
    show EstudianteDetailScreen;

// Subcategorías: listado y detalle
import '../features/admin/sections/detalle_subcategorias_screen.dart'
    show SubcategoriaEstudiantesScreen;
import '../features/admin/sections/admin_subcategorias_screen.dart'
    show AdminSubcategoriasScreen;

// Sesión
import '../core/services/session.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    // -------------------------------------------------------------------------
    // CORRECCIÓN: Parseamos la URI para obtener solo el path (sin query params)
    // Esto permite que /reset-password?token=xyz coincida con /reset-password
    // -------------------------------------------------------------------------
    final uri = Uri.parse(s.name ?? RouteNames.root);
    final path = uri.path; 

    switch (path) {
      // ======= Públicas ======================================================
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

      // ======= Auth ==========================================================
      case RouteNames.auth:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const AuthScreen(),
        );

      // 🔵 Recuperar contraseña
      case RouteNames.forgotPassword:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case RouteNames.resetPassword:
        // Flutter Web maneja los query params internamente en Uri.base
        // No es necesario pasarlos como argumentos.
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const ResetPasswordScreen(),
        );

      // ======= Protegidas (no lazy) ==========================================
      case RouteNames.perfil:
        return _guardedPlain(s, builder: (_) => const ProfileScreen());

      // Panel centrado (alias /admin)
      case RouteNames.panel:
      case RouteNames.adminRoot:
        return _guardedPlain(s, builder: (_) => const PanelScreen());

      // ======= Hubs base =====================================================
      case RouteNames.adminPersonas:
        return _guardedPlain(s, builder: (_) => const PersonasHubScreen());

      case RouteNames.adminAcademia:
        return _guardedPlain(s, builder: (_) => const AcademiaHubScreen());

      case RouteNames.adminFinanzas:
        return _guardedPlain(s, builder: (_) => const FinanzasHubScreen());

      case RouteNames.adminSistema:
        return _guardedPlain(s, builder: (_) => const SistemaHubScreen());

      // Hub REPORTES
      case RouteNames.adminReportes:
        return _guardedPlain(s, builder: (_) => const ReportesHubScreen());

      // ======= Subrutas de Personas ==========================================
      case RouteNames.adminPersonasUsuarios:
        return _guardedPlain(
          s,
          builder: (_) => const PersonasHubScreen(child: UsuariosScreen()),
        );

      case RouteNames.adminPersonasProfesores:
        return _guardedPlain(
          s,
          builder: (_) => PersonasHubScreen(
            child: ProfesoresScreen(embedded: true),
          ),
        );

      case RouteNames.adminPersonasRoles:
        return _guardedPlain(
          s,
          builder: (_) => PersonasHubScreen(
            child: RolesScreen(embedded: true),
          ),
        );

      // ======= Subrutas de Academia ==========================================
      case RouteNames.adminAcademiaCategorias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminCategoriasScreen()),
        );

      case RouteNames.adminAcademiaSubcategorias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminSubcategoriasScreen()),
        );

      case RouteNames.adminAcademiaEstudiantes:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminEstudiantesScreen()),
        );

      case RouteNames.adminAcademiaAsistencias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminAsistenciasScreen()),
        );

      // Finanzas
      case RouteNames.adminFinanzasPagos:
        return _guardedPlain(
          s,
          builder: (_) =>
              const FinanzasHubScreen(child: AdminPagosScreen()),
        );

      // Sistema
      case RouteNames.adminSistemaConfig:
        return _guardedPlain(
          s,
          builder: (_) =>
              const SistemaHubScreen(child: AdminConfigScreen()),
        );

      // ======= Compatibilidad: rutas antiguas ================================
      case RouteNames.adminUsuarios:
        return _guardedPlain(
          s,
          builder: (_) => const PersonasHubScreen(child: UsuariosScreen()),
        );

      case RouteNames.adminProfesores:
        return _guardedPlain(
          s,
          builder: (_) => PersonasHubScreen(
            child: ProfesoresScreen(embedded: true),
          ),
        );

      case RouteNames.adminRoles:
        return _guardedPlain(
          s,
          builder: (_) => PersonasHubScreen(
            child: RolesScreen(embedded: true),
          ),
        );

      case RouteNames.adminCategorias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminCategoriasScreen()),
        );

      case RouteNames.adminSubcategorias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminSubcategoriasScreen()),
        );

      case RouteNames.adminAsistencias:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminAsistenciasScreen()),
        );

      case RouteNames.adminPagos:
        return _guardedPlain(
          s,
          builder: (_) =>
              const FinanzasHubScreen(child: AdminPagosScreen()),
        );

      case RouteNames.adminConfig:
        return _guardedPlain(
          s,
          builder: (_) =>
              const SistemaHubScreen(child: AdminConfigScreen()),
        );

      case RouteNames.adminEstudiantes:
        return _guardedPlain(
          s,
          builder: (_) =>
              const AcademiaHubScreen(child: AdminEstudiantesScreen()),
        );

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
          return AcademiaHubScreen(child: EstudianteDetailScreen(id: id));
        });

      // Subcategoría → Estudiantes
      case RouteNames.adminSubcatEstudiantes:
        return _guardedPlain(s, builder: (_) {
          final args = s.arguments is Map
              ? Map<String, dynamic>.from(s.arguments as Map)
              : <String, dynamic>{};
          final idSubcat = _arg<int>(args, 'idSubcategoria');
          final nombre = _arg<String>(args, 'nombreSubcategoria');
          final idCat = _arg<int>(args, 'idCategoria');
          if (idSubcat == null || nombre == null) {
            return const _ArgsErrorPage(
              'Faltan argumentos: idSubcategoria (int) y nombreSubcategoria (String)',
            );
          }
          return AcademiaHubScreen(
            child: SubcategoriaEstudiantesScreen(
              idSubcategoria: idSubcat,
              nombreSubcategoria: nombre,
              idCategoria: idCat,
            ),
          );
        });

      // ======= 404 ===========================================================
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
    final uri = Uri.parse(s.name ?? RouteNames.root);
    final redirectTo = uri.path;

    return MaterialPageRoute(
      settings: s,
      builder: (ctx) {
        // ✅ CORRECCIÓN: Usar AuthScope en lugar de Session
        final auth = AuthScope.of(ctx);
        
        debugPrint('[_guardedPlain] Verificando ruta: $redirectTo');
        debugPrint('[_guardedPlain] isLoggedIn: ${auth.isLoggedIn}');
        
        // Si la ruta requiere auth y NO está logueado
        if (RouteNames.guarded.contains(redirectTo) && !auth.isLoggedIn) {
          debugPrint('[_guardedPlain] ❌ No autenticado, redirigiendo a login');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ctx.mounted) {
              Navigator.of(ctx).pushNamedAndRemoveUntil(
                RouteNames.auth,
                (r) => false,
                arguments: {'redirectTo': redirectTo},
              );
            }
          });
          
          return const _LoadingPage();
        }
        
        debugPrint('[_guardedPlain] ✅ Acceso permitido a: $redirectTo');
        return builder(ctx);
      },
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