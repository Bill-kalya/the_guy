class Env {
  // API Configuration
  // NOTE: Do NOT append /api here — each Endpoints constant includes /api/ prefix
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.theguy.co.ke',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://api.theguy.co.ke',
  );



  // Google Maps
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: '',
  );

  // Google Sign-In (Web Client ID for OAuth)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
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