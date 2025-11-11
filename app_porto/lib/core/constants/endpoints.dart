abstract class Endpoints {
  // ===== Auth & Me
  static const authLogin = '/auth/login';
  static const authLogout = '/auth/logout';
  static const me = '/me';
  static const meAvatar = '/me/avatar';
  static const mePassword = '/me/password';

  // ===== Usuarios
  static const usuarios = '/usuarios';
  static const usuariosActivos = '/usuarios/activos';
  static const usuariosInactivos = '/usuarios/inactivos';
  static const usuariosBuscar = '/usuarios/buscar';
  static String usuarioId(int id) => '/usuarios/$id';
  static String usuarioActivar(int id) => '/usuarios/$id/activar';

  // ===== Profesores
  static const profesores = '/profesores';
  static const profesoresActivos = '/profesores/activos';
  static const profesoresInactivos = '/profesores/inactivos';
  static String profesorId(int id) => '/profesores/$id';
  static String profesorActivar(int id) => '/profesores/$id/activar';

  // ===== Categorías
  static const categorias = '/categorias';
  static String categoriaId(int id) => '/categorias/$id';
  static String categoriaActivar(int id) => '/categorias/$id/activar';
  static String categoriaDesactivar(int id) => '/categorias/$id/desactivar';

  // ===== Subcategorías
  static const subcategorias = '/subcategorias';
  static String subcategoriaId(int id) => '/subcategorias/$id';
  static String subcategoriaActivar(int id) => '/subcategorias/$id/activar';

  // ===== Subcategoría-Estudiante
  static const subcatEst = '/subcategoria-estudiante';
  static String subcatEstPorEstudiante(int idEst) =>
      '/subcategoria-estudiante/estudiante/$idEst';
  static String subcatEstEliminar(int idEst, int idSubcat) =>
      '/subcategoria-estudiante/$idEst/$idSubcat';

  // ✅ NUEVO: listado de alumnos por subcategoría (usado por AsistenciasRepository)
  static String subcatEstPorSubcategoria(int idSubcat) =>
      '/subcategoria-estudiante/subcategoria/$idSubcat/estudiantes';

  // ===== Matrículas
  static const matriculas = '/matriculas';
  static String matriculaId(int id) => '/matriculas/$id';
  static String matriculaActivar(int id) => '/matriculas/$id/activar';
  static const matriculasActivas = '/matriculas/activas';
  static const matriculasInactivas = '/matriculas/inactivas';
  static const matriculasTodas = '/matriculas/todas';
  static String matriculasPorEstudiante(int id) => '/matriculas/estudiante/$id';

  // Crear con estudiante
  static String get matriculasCrearConEstudiante => '/matriculas/crear-con-estudiante';

  // 🔴 NUEVO (ya lo tenías documentado)
  static const String estudiantesCrearConMatricula = '/estudiantes/crear-con-matricula';

  // ===== Estudiantes
  static const estudiantes = '/estudiantes';
  static String estudianteId(int id) => '/estudiantes/$id';
  static String estudianteActivar(int id) => '/estudiantes/activar/$id';
  static const estudiantesNoAsignados = '/estudiantes/no-asignados';

  // ===== Mensualidades
  static const mensualidades = '/mensualidades';
  static String mensualidadesPorEstudiante(int id) =>
      '/mensualidades/estudiante/$id';
  static const mensualidadesResumen = '/mensualidades/resumen';

  // ===== Pagos
  static const pagos = '/pagos';
  static String pagoId(int id) => '/pagos/$id';
  static String get adminEstadoMensualidad => '/estado-mensualidad';

  // ===== ✅ Asistencias (base + sesiones)
  static const asistencias = '/asistencias';
  // Sesiones: POST /asistencias/sesiones, GET /asistencias/sesiones?...
  static String get asistenciasSesiones => '/asistencias/sesiones';
  static String asistenciasSesionId(int idSesion) => '/asistencias/sesiones/$idSesion';
  static String asistenciasSesionMarcar(int idSesion) =>
      '/asistencias/sesiones/$idSesion/marcar';
}
