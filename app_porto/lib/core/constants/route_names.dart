// lib/core/constants/route_names.dart
class RouteNames {
  // Públicas
  static const root        = '/';
  static const tienda      = '/tienda';
  static const eventos     = '/eventos';
  static const categorias  = '/categorias';
  static const beneficios  = '/beneficios';
  static const conocenos   = '/conocenos';

  // Auth
  static const auth        = '/auth';
  static const perfil      = '/perfil';

  // Panel / Admin
  static const panel               = '/panel';
  static const adminUsuarios       = '/admin/usuarios';
  static const adminProfesores     = '/admin/profesores';
  static const adminCategorias     = '/admin/categorias';
  static const adminSubcategorias  = '/admin/subcategorias';
  static const adminAsistencias    = '/admin/asistencias';
  static const adminEvaluaciones   = '/admin/evaluaciones';
  static const adminPagos          = '/admin/pagos';
  static const adminConfig         = '/admin/config';

  static const guarded = <String>{
    perfil, panel, adminUsuarios, adminProfesores, adminCategorias,
    adminSubcategorias, adminAsistencias, adminEvaluaciones,
    adminPagos, adminConfig,
  };
}
