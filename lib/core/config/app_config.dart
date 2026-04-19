class AppConfig {
  static const String appName = 'The Guy';
  static const String version = '1.0.0';
  
  // Feature flags
  static const bool enableChat = true;
  static const bool enablePayments = true;
  static const bool enableMaps = true;
  static const bool enableNotifications = true;
  
  // Timeouts (in seconds)
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Location
  static const double maxDistanceKm = 50.0;
  static const int locationUpdateIntervalMs = 5000; // 5 seconds
  static const int locationAccuracyMeters = 100;
  
  // Cache
  static const int cacheExpirationDays = 7;
  static const int maxCacheSizeMB = 50;
  
  // Job matching
  static const int matchingTimeoutSeconds = 60;
  static const int providerResponseTimeoutSeconds = 30;
  
  // Payment
  static const int paymentVerificationTimeoutSeconds = 120;
  
  // Image upload
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // OTP
  static const int otpLength = 6;
  static const int otpResendCooldownSeconds = 60;
  static const int otpExpirySeconds = 300; // 5 minutes
}