class AppRoles {
  static const String admin = 'ADMIN';
  static const String profesor = 'PROFESOR';
  static const String representante = 'REPRESENTANTE';

  /// Mapea tu id_rol (BD) a nombres de rol (string) para guards
  static String? fromRoleId(int? id) {
    switch (id) {
      case 1:
        return admin;
      case 2:
        return profesor;
      case 3:
        return representante;
      default:
        return null;
    }
  }
}