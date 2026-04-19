class AppConstants {
  // Shared Preferences Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';
  static const String keyIsFirstLaunch = 'is_first_launch';
  
  // API Related
  static const String apiDateFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Location
  static const double defaultLatitude = -1.286389;
  static const double defaultLongitude = 36.817223;
  static const double defaultZoomLevel = 14.0;
  
  // Job Statuses
  static const String jobStatusMatching = 'matching';
  static const String jobStatusMatched = 'matched';
  static const String jobStatusAccepted = 'accepted';
  static const String jobStatusEnRoute = 'en_route';
  static const String jobStatusInProgress = 'in_progress';
  static const String jobStatusCompleted = 'completed';
  static const String jobStatusCancelled = 'cancelled';
  
  // Payment Statuses
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusProcessing = 'processing';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleProvider = 'provider';
  static const String roleAdmin = 'admin';
}