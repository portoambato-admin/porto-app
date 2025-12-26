abstract class RouteNames {
  // Públicas
  static const root = '/';
  static const auth = '/auth';
  static const perfil = '/perfil';
  static const panel = '/panel';
  static const forgotPassword = "/forgot-password";
  static const resetPassword = "/reset-password";

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
  static const adminSistema = '/admin/sistema';

  // ===== Admin: subrutas de Personas
  static const adminPersonasUsuarios = '/admin/personas/usuarios';
  static const adminPersonasProfesores = '/admin/personas/profesores';
  static const adminPersonasRoles = '/admin/personas/roles';

  // ===== Admin: subrutas de Academia
  static const adminAcademiaCategorias = '/admin/academia/categorias';
  static const adminAcademiaSubcategorias = '/admin/academia/subcategorias';
  static const adminAcademiaEstudiantes = '/admin/academia/estudiantes';
  static const adminAcademiaAsistencias = '/admin/academia/asistencias';

  // ===== Admin: subrutas de Finanzas
  static const adminFinanzasPagos = '/admin/finanzas/pagos';

  // ===== Admin: subrutas de Sistema
  static const adminSistemaConfig = '/admin/sistema/config';
  static const adminSistemaReportes = '/admin/sistema/reportes';

  // ===== Compat (rutas antiguas / atajos)
  static const adminUsuarios = '/admin/usuarios';
  static const adminProfesores = '/admin/profesores';
  static const adminRoles = '/admin/roles';
  static const adminCategorias = '/admin/categorias';
  static const adminSubcategorias = '/admin/subcategorias';
  static const adminAsistencias = '/admin/asistencias';
  static const adminPagos = '/admin/pagos';
  static const adminReportes = '/admin/reportes';
  static const adminConfig = '/admin/config';

  // Estudiantes (listado + detalle)
  static const adminEstudiantes = '/admin/estudiantes';
  static const adminEstudianteDetalle = '/admin/estudiantes/detalle';

  // Subcategoría → Estudiantes (detalle de subcat)
  static const adminSubcatEstudiantes = '/admin/subcategorias/estudiantes';

  // ===== PROFESOR (módulo propio) =====
  static const profesorRoot = '/profesor';

  // Hubs profesor
  static const profesorAcademia = '/profesor/academia';
  static const profesorReportes = '/profesor/reportes';
  static const profesorConfig = '/profesor/config';

  // Subrutas Academia profesor (mismo contenido que admin academia)
  static const profesorAcademiaCategorias = '/profesor/academia/categorias';
  static const profesorAcademiaSubcategorias = '/profesor/academia/subcategorias';
  static const profesorAcademiaEstudiantes = '/profesor/academia/estudiantes';
  static const profesorAcademiaAsistencias = '/profesor/academia/asistencias';

  static const profesorEstudianteDetalle = '/profesor/academia/estudiantes/detalle';
  static const profesorSubcatEstudiantes = '/profesor/academia/subcategorias/estudiantes';

  // Reportes limitados profesor
  static const profesorReporteAsistencias = '/profesor/reportes/asistencias';
  static const profesorReporteEstudiantes = '/profesor/reportes/estudiantes';

  // (Si mantienes estos antiguos, los dejamos)
  static const profesorEstudiantes = '/profesor/estudiantes';
  static const profesorAsistencias = '/profesor/asistencias';
  static const profesorEvaluaciones = '/profesor/evaluaciones';

  // ===== REPRESENTANTE =====
  static const representanteRoot = '/representante';
  static const representanteMensualidades = '/representante/mensualidades';
  static const representanteMensualidadDetalle = '/representante/mensualidades/detalle';

  // Guardadas (requieren token)
  static const guarded = <String>{
    perfil,
    panel,

    // Admin
    adminRoot,
    adminPersonas,
    adminAcademia,
    adminFinanzas,
    adminSistema,

    adminPersonasUsuarios,
    adminPersonasProfesores,
    adminPersonasRoles,

    adminAcademiaCategorias,
    adminAcademiaSubcategorias,
    adminAcademiaEstudiantes,
    adminAcademiaAsistencias,

    adminFinanzasPagos,

    adminSistemaConfig,
    adminSistemaReportes,

    adminUsuarios,
    adminProfesores,
    adminRoles,
    adminCategorias,
    adminSubcategorias,
    adminAsistencias,
    adminPagos,
    adminConfig,
    adminReportes,

    adminEstudiantes,
    adminEstudianteDetalle,
    adminSubcatEstudiantes,

    // Profesor
    profesorRoot,
    profesorAcademia,
    profesorReportes,
    profesorConfig,

    profesorAcademiaCategorias,
    profesorAcademiaSubcategorias,
    profesorAcademiaEstudiantes,
    profesorAcademiaAsistencias,
    profesorEstudianteDetalle,
    profesorSubcatEstudiantes,

    profesorReporteAsistencias,
    profesorReporteEstudiantes,

    // Profesor antiguos (si los usas)
    profesorEstudiantes,
    profesorAsistencias,
    profesorEvaluaciones,

    // Representante
    representanteRoot,
    representanteMensualidades,
    representanteMensualidadDetalle,
  };
}
