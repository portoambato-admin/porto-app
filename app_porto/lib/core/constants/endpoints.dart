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
  static String subcatEstPorEstudiante(int idEst) => '/subcategoria-estudiante/estudiante/$idEst';
  static String subcatEstEliminar(int idEst, int idSubcat) => '/subcategoria-estudiante/$idEst/$idSubcat';

  // ===== Matrículas
  static const matriculas = '/matriculas';
  static String matriculaId(int id) => '/matriculas/$id';
  static String matriculaActivar(int id) => '/matriculas/$id/activar';
  static const matriculasActivas = '/matriculas/activas';
  static const matriculasInactivas = '/matriculas/inactivas';
  static const matriculasTodas = '/matriculas/todas';

  // ===== Estudiantes
  static const estudiantes = '/estudiantes';
  static String estudianteId(int id) => '/estudiantes/$id';
  // ⚠️ Tu back: PATCH /estudiantes/activar/:id
  // (con nuestro HttpClient usaremos POST al mismo path)
  static String estudianteActivar(int id) => '/estudiantes/activar/$id';

   // ===== Mensualidades (asumimos estos endpoints; si tu back usa otros, cambia aquí)
  static const mensualidades = '/mensualidades';
  static String mensualidadId(int id) => '/mensualidades/$id';

  // ===== Pagos
  static const pagos = '/pagos';
  static String pagoId(int id) => '/pagos/$id';
}
