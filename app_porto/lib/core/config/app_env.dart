class AppEnv {
  // Cambia con --dart-define
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://backend-production-cb2d.up.railway.app',
  );

  static const bool isProd = bool.fromEnvironment(
    'IS_PROD',
    defaultValue: false,
  );
}
