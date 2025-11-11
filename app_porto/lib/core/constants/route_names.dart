// lib/core/constants/route_names.dart
abstract class RouteNames {
  // Públicas
  static const root = '/';
  static const auth = '/auth';
  static const perfil = '/perfil';
  static const panel = '/panel';

  static const tienda = '/tienda';
  static const eventos = '/eventos';
  static const categorias = '/categorias';
  static const beneficios = '/beneficios';
  static const conocenos = '/conocenos';

  // ===== Admin: hubs raíz
  static const adminRoot = '/admin';
  static const adminPersonas = '/admin/personas';
  static const adminAcademia = '/admin/academia';
  static const adminFinanzas = '/admin/finanzas';
  static const adminSistema  = '/admin/sistema';

  // ===== Admin: subrutas de Personas
  static const adminPersonasUsuarios   = '/admin/personas/usuarios';
  static const adminPersonasProfesores = '/admin/personas/profesores';
  static const adminPersonasRoles      = '/admin/personas/roles'; // NEW

  // ===== Admin: subrutas de Academia
  static const adminAcademiaCategorias     = '/admin/academia/categorias';
  static const adminAcademiaSubcategorias  = '/admin/academia/subcategorias';
  static const adminAcademiaEstudiantes    = '/admin/academia/estudiantes';
  static const adminAcademiaAsistencias    = '/admin/academia/asistencias';

  // ===== Admin: subrutas de Finanzas
  static const adminFinanzasPagos = '/admin/finanzas/pagos';

  // ===== Admin: subrutas de Sistema
  static const adminSistemaConfig = '/admin/sistema/config';

  // ===== Compat (rutas antiguas)
  static const adminUsuarios       = '/admin/usuarios';
  static const adminProfesores     = '/admin/profesores';
  static const adminRoles          = '/admin/roles';        // NEW
  static const adminCategorias     = '/admin/categorias';
  static const adminSubcategorias  = '/admin/subcategorias';
  static const adminAsistencias    = '/admin/asistencias';
  static const adminPagos          = '/admin/pagos';
  static const adminConfig         = '/admin/config';

  // Estudiantes (listado + detalle)
  static const adminEstudiantes        = '/admin/estudiantes';
  static const adminEstudianteDetalle  = '/admin/estudiantes/detalle';

  // Subcategoría → Estudiantes (detalle de subcat)
  static const adminSubcatEstudiantes = '/admin/subcategorias/estudiantes';

  // Guardadas (requieren token)
  static const guarded = <String>{
    perfil, panel,
    adminRoot,
    adminPersonas, adminAcademia, adminFinanzas, adminSistema,
    adminPersonasUsuarios, adminPersonasProfesores, adminPersonasRoles,
    adminAcademiaCategorias, adminAcademiaSubcategorias,
    adminAcademiaEstudiantes, adminAcademiaAsistencias, 
    adminFinanzasPagos, adminSistemaConfig,
    adminUsuarios, adminProfesores, adminRoles, adminCategorias, adminSubcategorias,
    adminAsistencias, adminPagos, adminConfig,
    adminEstudiantes, adminEstudianteDetalle, adminSubcatEstudiantes,
  };
}
