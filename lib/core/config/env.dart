class Env {
  // API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://the-guy-backend-production.up.railway.app/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://the-guy-backend-production.up.railway.app',
  );



  // Google Maps
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: '',
  );

  // Environment type
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  static const bool isDevelopment = !isProduction;

  // Logging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
}