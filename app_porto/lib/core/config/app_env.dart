class AppEnv {
  // Cambia con --dart-define
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:3000',
  );

  static const bool isProd = bool.fromEnvironment(
    'IS_PROD',
    defaultValue: false,
  );
}
