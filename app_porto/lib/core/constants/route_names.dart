// lib/core/constants/route_names.dart
abstract class RouteNames {
  static const root = '/';
  static const auth = '/auth';
  static const perfil = '/perfil';
  static const panel = '/panel';

  static const tienda = '/tienda';
  static const eventos = '/eventos';
  static const categorias = '/categorias';
  static const beneficios = '/beneficios';
  static const conocenos = '/conocenos';

  static const adminUsuarios = '/admin/usuarios';
  static const adminProfesores = '/admin/profesores';
  static const adminCategorias = '/admin/categorias';
  static const adminSubcategorias = '/admin/subcategorias'; // listado
  static const adminAsistencias = '/admin/asistencias';
  static const adminEvaluaciones = '/admin/evaluaciones';
  static const adminPagos = '/admin/pagos';
  static const adminConfig = '/admin/config';

  // Estudiantes (listado + detalle)
  static const adminEstudiantes = '/admin/estudiantes';
  static const adminEstudianteDetalle = '/admin/estudiantes/detalle';

  // Subcategoría → Estudiantes (detalle de subcat)
  static const adminSubcatEstudiantes = '/admin/subcategorias/estudiantes';

  // Si usas guardias:
  static const guarded = <String>{
    perfil, panel,
    adminUsuarios, adminProfesores, adminCategorias, adminSubcategorias,
    adminAsistencias, adminEvaluaciones, adminPagos, adminConfig,
    adminEstudiantes, adminEstudianteDetalle, adminSubcatEstudiantes,
  };
}
