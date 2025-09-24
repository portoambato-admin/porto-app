abstract class Endpoints {
  // Auth & Me
  static const authLogin   = '/auth/login';
  static const authLogout  = '/auth/logout';
  static const me          = '/me';
  static const meAvatar    = '/me/avatar';
  static const mePassword  = '/me/password';

  // Usuarios
  static const usuarios                 = '/usuarios';
  static const usuariosActivos          = '/usuarios/activos';
  static const usuariosInactivos        = '/usuarios/inactivos';
  static const usuariosBuscar           = '/usuarios/buscar';
  static String usuarioId(int id)       => '/usuarios/$id';
  static String usuarioActivar(int id)  => '/usuarios/$id/activar';

  // Profesores (ejemplo; el resto similar)
  static const profesores                   = '/profesores';
  static const profesoresActivos            = '/profesores/activos';
  static const profesoresInactivos          = '/profesores/inactivos';
  static String profesorId(int id)          => '/profesores/$id';
  static String profesorActivar(int id)     => '/profesores/$id/activar';
}
