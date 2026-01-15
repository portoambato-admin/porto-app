import 'package:app_porto/core/config/app_env.dart';
import 'package:flutter/widgets.dart';
import '../core/network/http_client.dart';

// Auth
import '../features/auth/data/auth_repository.dart';

// Repos
import '../features/admin/data/usuarios_repository.dart';
import '../features/admin/data/categorias_repository.dart';
import '../features/admin/data/subcategorias_repository.dart';
import '../features/admin/data/estudiantes_repository.dart';
import '../features/admin/data/matriculas_repository.dart';
import '../features/admin/data/mensualidades_repository.dart';
import '../features/admin/data/pagos_repository.dart';
import '../features/admin/data/reportes_repository.dart';
import '../features/admin/data/estado_mensualidad_repository.dart';
import '../features/admin/data/subcat_est_repository.dart';
import '../features/admin/data/representantes_estudiante_repository.dart';


import '../features/representante/data/representante_repository.dart';


import '../features/admin/data/asistencias_repository.dart';

import '../features/admin/data/dashboard_repository.dart';

import '../features/notificaciones/data/notificaciones_repository.dart';

class AppScope extends InheritedWidget {
  final HttpClient http;
  final AuthRepository auth;

  final UsuariosRepository usuarios;
  final CategoriasRepository categorias;
  final SubcategoriasRepository subcategorias;
  final EstudiantesRepository estudiantes;
  final MatriculasRepository matriculas;
  final MensualidadesRepository mensualidades;
  final PagosRepository pagos;
  final ReportesRepository reportes;
  final EstadoMensualidadRepository estadoMensualidad;
  final SubcatEstRepository subcatEst;
  final RepresentantesEstudianteRepository representantesEstudiante;

  // Representante
  final RepresentanteRepository representante;

  // ✅ NUEVO
  final AsistenciasRepository asistencias;

  final DashboardRepository dashboard;

  final NotificacionesRepository notificaciones;

  AppScope._({
    required this.http,
    required this.auth,
    required this.usuarios,
    required this.categorias,
    required this.subcategorias,
    required this.estudiantes,
    required this.matriculas,
    required this.mensualidades,
    required this.pagos,
    required this.reportes,
    required this.estadoMensualidad,
    required this.subcatEst,
    required this.representantesEstudiante,
    required this.representante,
    required this.asistencias, // ✅
    required this.dashboard,
    required this.notificaciones,
    required super.child,
  });

  factory AppScope({required Widget child}) {
    
    final http = HttpClient(
      baseUrl: AppEnv.apiBase,
    );

    // 3. Inyectamos http en el repositorio
    final auth = AuthRepository(http);

    final usuarios          = UsuariosRepository(http);
    final categorias        = CategoriasRepository(http);
    final subcategorias     = SubcategoriasRepository(http);
    final estudiantes       = EstudiantesRepository(http);
    final matriculas        = MatriculasRepository(http);
    final mensualidades     = MensualidadesRepository(http);
    final pagos             = PagosRepository(http);
    final reportes          = ReportesRepository(http);
    final estadoMensualidad = EstadoMensualidadRepository(http);
    final subcatEst         = SubcatEstRepository(http);
    final representantesEstudiante = RepresentantesEstudianteRepository(http);

    final dashboard         = DashboardRepository(http);    

    final notificaciones    = NotificacionesRepository(http);

    // Representante
    final representante     = RepresentanteRepository(http);

    // ✅ NUEVO
    final asistencias       = AsistenciasRepository(http);

    return AppScope._(
      http: http,
      auth: auth,
      usuarios: usuarios,
      categorias: categorias,
      subcategorias: subcategorias,
      estudiantes: estudiantes,
      matriculas: matriculas,
      mensualidades: mensualidades,
      pagos: pagos,
      reportes: reportes,
      estadoMensualidad: estadoMensualidad,
      subcatEst: subcatEst,
      representantesEstudiante: representantesEstudiante,
      dashboard: dashboard,
      representante: representante,
      asistencias: asistencias,
      notificaciones: notificaciones,
      
      child: child,
    );
  }

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
