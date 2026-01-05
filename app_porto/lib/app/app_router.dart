import 'package:flutter/material.dart';

import '../core/state/auth_state.dart';

// Roles
import '../app/app_roles.dart';
import '../core/rbac/forbidden_screen.dart';

// Rutas (constantes)
import '../core/constants/route_names.dart';

// Home (NO diferido)
import '../features/public/presentation/screen/home_screen.dart';

// PÚBLICAS diferidas (lazy)
import '../features/public/presentation/screen/store_screen.dart' deferred as store;
import '../features/public/presentation/screen/events_screen.dart' deferred as events;
import '../features/public/presentation/screen/categories_screen.dart'
    deferred as categories;
import '../features/public/presentation/screen/benefits_screen.dart'
    deferred as benefits;
import '../features/public/presentation/screen/about_screen.dart' deferred as about;

// Auth
import '../features/auth/presentation/screens/auth_screen.dart';

// 🔵 Recuperación de contraseña
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';

// Perfil (NO diferido)
import '../features/profile/presentation/screens/profile_screen.dart';

// Dashboard admin (NO diferido)
import '../features/admin/presentation/hubs/dashboard_hub_screen.dart';

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
import '../features/admin/sections/config_screen.dart' show AdminConfigScreen;
import '../features/admin/sections/admin_pagos_screen.dart' show AdminPagosScreen;

import '../features/admin/presentation/profesores/profesores_screen.dart';
import '../features/admin/sections/estudiantes_screen.dart'
    show AdminEstudiantesScreen;
import '../features/admin/sections/estudiante_detail_screen.dart'
    show EstudianteDetailScreen;
import '../features/admin/sections/estudiante_representantes_screen.dart'
    show AdminEstudianteRepresentantesScreen;

// Subcategorías: listado y detalle
import '../features/admin/sections/detalle_subcategorias_screen.dart'
    show SubcategoriaEstudiantesScreen;
import '../features/admin/sections/admin_subcategorias_screen.dart'
    show AdminSubcategoriasScreen;

// Roles screen (admin)
import '../features/admin/sections/roles_screen.dart' show RolesScreen;

// ===== Profesor (hubs propios) =====
import '../features/profesor/presentation/hubs/profesor_academia_hub_screen.dart';
import '../features/profesor/presentation/hubs/profesor_reportes_hub_screen.dart';
import '../features/profesor/presentation/profesor_config_screen.dart';
import '../features/profesor/presentation/reportes/profesor_reporte_asistencias_screen.dart';
import '../features/profesor/presentation/reportes/profesor_reporte_estudiantes_screen.dart';

// ===== Representante =====
import '../features/representante/presentation/representante_shell_screen.dart';
import '../features/representante/presentation/representante_mensualidades_screen.dart';
import '../features/representante/presentation/representante_mensualidad_detalle_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    // Parseamos la URI para obtener solo el path (sin query params)
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
        return MaterialPageRoute(settings: s, builder: (_) => const AuthScreen());

      case RouteNames.forgotPassword:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case RouteNames.resetPassword:
        return MaterialPageRoute(
          settings: s,
          builder: (_) => const ResetPasswordScreen(),
        );

      // ======= Protegidas (cualquier logueado) ===============================
      case RouteNames.perfil:
        return _guardedPlain(s, builder: (_) => const ProfileScreen());

      // ======= ADMIN (solo ADMIN) ============================================
      case RouteNames.panel: // compat: alias antiguo
      case RouteNames.adminRoot:
      case RouteNames.adminDashboard:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const DashboardHubScreen(),
        );

      case RouteNames.adminPersonas:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const PersonasHubScreen(),
        );

      case RouteNames.adminAcademia:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const AcademiaHubScreen(),
        );

      case RouteNames.adminFinanzas:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const FinanzasHubScreen(),
        );

      case RouteNames.adminSistema:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const SistemaHubScreen(),
        );

      // Reportes (ADMIN): soporta /admin/reportes y /admin/sistema/reportes
      case RouteNames.adminReportes:
      case RouteNames.adminSistemaReportes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const ReportesHubScreen(),
        );

      // ======= Subrutas de Personas (ADMIN) ==================================
      case RouteNames.adminPersonasUsuarios:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const PersonasHubScreen(child: UsuariosScreen()),
        );

      case RouteNames.adminPersonasProfesores:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => PersonasHubScreen(child: ProfesoresScreen()),
        );

      case RouteNames.adminPersonasRoles:
      case RouteNames.adminRoles:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => PersonasHubScreen(child: RolesScreen(embedded: true)),
        );

      // ======= Subrutas de Academia (ADMIN) ==================================
      case RouteNames.adminAcademiaCategorias:
      case RouteNames.adminCategorias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const AcademiaHubScreen(child: AdminCategoriasScreen()),
        );

      case RouteNames.adminAcademiaSubcategorias:
      case RouteNames.adminSubcategorias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) =>
              const AcademiaHubScreen(child: AdminSubcategoriasScreen()),
        );

      case RouteNames.adminAcademiaEstudiantes:
      case RouteNames.adminEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const AcademiaHubScreen(child: AdminEstudiantesScreen()),
        );

      case RouteNames.adminAcademiaAsistencias:
      case RouteNames.adminAsistencias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const AcademiaHubScreen(child: AdminAsistenciasScreen()),
        );

      // Finanzas (ADMIN)
      case RouteNames.adminFinanzasPagos:
      case RouteNames.adminPagos:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const FinanzasHubScreen(child: AdminPagosScreen()),
        );

      // Sistema (ADMIN)
      case RouteNames.adminSistemaConfig:
      case RouteNames.adminConfig:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) => const SistemaHubScreen(child: AdminConfigScreen()),
        );

      // Estudiante detalle (ADMIN)
      case RouteNames.adminEstudianteDetalle:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) {
            final args = s.arguments;
            int? id;
            if (args is Map && args['id'] != null) {
              final v = args['id'];
              if (v is int) id = v;
              else if (v is num) id = v.toInt();
              else if (v is String) id = int.tryParse(v);
            }
            if (id == null) return const _ArgsErrorPage('Falta argumento: id (int)');
            return AcademiaHubScreen(child: EstudianteDetailScreen(id: id));
          },
        );

      

      // Estudiante → Representantes (ADMIN)
      case RouteNames.adminEstudianteRepresentantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) {
            final args = s.arguments;
            int? id;
            if (args is Map && args['id'] != null) {
              final v = args['id'];
              if (v is int) id = v;
              else if (v is num) id = v.toInt();
              else if (v is String) id = int.tryParse(v);
            }
            if (id == null) return const _ArgsErrorPage('Falta argumento: id (int)');
            return AcademiaHubScreen(child: AdminEstudianteRepresentantesScreen(idEstudiante: id, nombreEstudiante: '',));
          },
        );
// Subcategoría → Estudiantes (ADMIN)
      case RouteNames.adminSubcatEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.admin},
          builder: (_) {
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
          },
        );

      // ======= PROFESOR (PROFESOR o ADMIN) ===================================
      case RouteNames.profesorRoot:
      case RouteNames.profesorAcademia:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) => const ProfesorAcademiaHubScreen(),
        );

      case RouteNames.profesorAcademiaCategorias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminCategoriasScreen()),
        );

      case RouteNames.profesorAcademiaSubcategorias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminSubcategoriasScreen()),
        );

      case RouteNames.profesorAcademiaEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminEstudiantesScreen()),
        );

      case RouteNames.profesorAcademiaAsistencias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminAsistenciasScreen()),
        );

      // Detalle estudiante (Profesor)
      case RouteNames.profesorEstudianteDetalle:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) {
            final args = s.arguments;
            int? id;
            if (args is Map && args['id'] != null) {
              final v = args['id'];
              if (v is int) id = v;
              else if (v is num) id = v.toInt();
              else if (v is String) id = int.tryParse(v);
            }
            if (id == null) return const _ArgsErrorPage('Falta argumento: id (int)');
            return ProfesorAcademiaHubScreen(child: EstudianteDetailScreen(id: id));
          },
        );

      // Subcategoría → Estudiantes (Profesor)
      case RouteNames.profesorSubcatEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) {
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
            return ProfesorAcademiaHubScreen(
              child: SubcategoriaEstudiantesScreen(
                idSubcategoria: idSubcat,
                nombreSubcategoria: nombre,
                idCategoria: idCat,
              ),
            );
          },
        );

      // Reportes profesor (limitados)
      case RouteNames.profesorReportes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) => const ProfesorReportesHubScreen(),
        );

      case RouteNames.profesorReporteAsistencias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) => const ProfesorReporteAsistenciasScreen(),
        );

      case RouteNames.profesorReporteEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) => const ProfesorReporteEstudiantesScreen(),
        );

      case RouteNames.profesorConfig:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) => const ProfesorConfigScreen(),
        );

      // Compat profesor antiguos
      case RouteNames.profesorEstudiantes:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminEstudiantesScreen()),
        );

      case RouteNames.profesorAsistencias:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.profesor, AppRoles.admin},
          builder: (_) =>
              const ProfesorAcademiaHubScreen(child: AdminAsistenciasScreen()),
        );

      // ======= REPRESENTANTE (REPRESENTANTE o ADMIN) =========================
      case RouteNames.representanteRoot:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.representante, AppRoles.admin},
          builder: (_) => const RepresentanteShellScreen(),
        );

      case RouteNames.representanteMensualidades:
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.representante, AppRoles.admin},
          builder: (_) => const RepresentanteMensualidadesScreen(),
        );

      case RouteNames.representanteMensualidadDetalle:
        final args = (s.arguments as Map?) ?? const {};
        final id = (args['idMensualidad'] as num?)?.toInt() ?? 0;
        return _guardedRole(
          s,
          allowedRoles: {AppRoles.representante, AppRoles.admin},
          builder: (_) => RepresentanteMensualidadDetalleScreen(idMensualidad: id),
        );

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
        final auth = AuthScope.of(ctx);

        if (RouteNames.guarded.contains(redirectTo) && !auth.isLoggedIn) {
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

        return builder(ctx);
      },
    );
  }

  static Route<dynamic> _guardedRole(
    RouteSettings s, {
    required Set<String> allowedRoles,
    required WidgetBuilder builder,
  }) {
    final uri = Uri.parse(s.name ?? RouteNames.root);
    final redirectTo = uri.path;

    return MaterialPageRoute(
      settings: s,
      builder: (ctx) {
        final auth = AuthScope.of(ctx);

        if (RouteNames.guarded.contains(redirectTo) && !auth.isLoggedIn) {
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

        final role = auth.role;
        if (role == null) {
          return const ForbiddenScreen(message: 'Tu sesión no tiene rol asignado.');
        }

        if (!allowedRoles.contains(role)) {
          return ForbiddenScreen(message: 'Rol actual: $role');
        }

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
