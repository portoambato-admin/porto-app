class AppEnv {
  // Cambia con --dart-define
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
   //defaultValue: 'https://backend-production-cb2d.up.railway.app',
   defaultValue: 'http://localhost:3000',
  );

  static const bool isProd = bool.fromEnvironment(
    'IS_PROD',
    defaultValue: false,
  );
}
