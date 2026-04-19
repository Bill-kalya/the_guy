class Endpoints {
  static const String baseUrl = Env.apiUrl;
  static const String wsUrl = Env.wsUrl;
  
  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  // User Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String getUserById = '/users';
  
  // Jobs Endpoints
  static const String jobs = '/jobs';
  static const String requestJob = '/jobs/request';
  static const String nearbyJobs = '/jobs/nearby';
  static const String jobHistory = '/jobs/history';
  static const String acceptJob = '/jobs/accept';
  static const String declineJob = '/jobs/decline';
  static const String updateJobStatus = '/jobs/status';
  static const String completeJob = '/jobs/complete';
  
  // Payment Endpoints
  static const String initiateMpesa = '/payments/mpesa/initiate';
  static const String checkPaymentStatus = '/payments/status';
  static const String paymentHistory = '/payments/history';
  
  // Providers Endpoints
  static const String nearbyProviders = '/providers/nearby';
  static const String providerDetails = '/providers';
  static const String providerEarnings = '/providers/earnings';
  static const String updateAvailability = '/providers/availability';
  
  // Chat Endpoints
  static const String chatHistory = '/chat/history';
  static const String sendMessage = '/chat/send';
  static const String markAsRead = '/chat/read';
  
  // Categories
  static const String categories = '/categories';
  static const String subCategories = '/categories/sub';
}