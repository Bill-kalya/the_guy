import '../config/env.dart';

class Endpoints {
  static final String baseUrl = Env.apiUrl;
  static final String wsUrl = Env.wsUrl;

  // ============ Admin ============
  static const String adminBase = '/api/v1/admin';
  static const String adminAuditLogs = '$adminBase/audit-logs';

  // These don't exist yet in backend
  // static const String adminDashboard = '$adminBase/dashboard';
  // static const String adminProviders = '$adminBase/providers';
  // static const String adminDisputes = '$adminBase/disputes';
  // static const String adminModerationCases = '$adminBase/moderation/cases';
  // static const String adminSettings = '$adminBase/settings';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendVerification = '/api/auth/resend-otp';

  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetOtp = '/api/auth/verify-reset-otp';
  static const String resetPassword = '/api/auth/reset-password';

  // Users
  static const String userProfile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile';
  static const String changePassword = '/api/users/change-password';
  static const String getUserById = '/api/users';

  // File Upload
  static const String fileUpload = '/api/files/upload';

  // Jobs
  static const String jobs = '/api/jobs';
  static const String requestJob = '/api/jobs/request';
  static const String nearbyJobs = '/api/jobs/nearby';
  static const String jobHistory = '/api/jobs/history';
  static const String customerStats = '/api/jobs/stats';

  // Payments
  static const String initiateMpesa = '/api/payments/mpesa/initiate';
  static const String checkPaymentStatus = '/api/payments/status';
  static const String paymentHistory = '/api/payments/history';

  // Location
  static const String updateLocation = '/api/location/update';
  static const String nearbyLocations = '/api/location/nearby';

  // Providers
  static const String nearbyProviders = '/api/providers/nearby';
  static const String providerDetails = '/api/providers';
  static const String providerEarnings = '/api/providers/earnings';
  static const String updateAvailability = '/api/providers/availability';

  // Search
  static const String searchProviders = '/api/search/providers';
  static const String searchSuggestions = '/api/search/suggestions';

  // Chat
  static const String chatHistory = '/api/chat/history';
  static const String sendMessage = '/api/chat/send';
  static const String markAsRead = '/api/chat/read';

  // Categories
  static const String categories = '/api/categories';
  static const String subCategories = '/api/categories/sub';
}

class EndpointBuilder {
  static String acceptJob(String jobId) =>
      '/api/jobs/$jobId/accept';

  static String declineJob(String jobId) =>
      '/api/jobs/$jobId/decline';

  static String completeJob(String jobId) =>
      '/api/jobs/$jobId/complete';

  static String updateJobStatus(String jobId) =>
      '/api/jobs/$jobId/status';

  static String providerLocation(String providerId) =>
      '/api/location/provider/$providerId';

  static String providerAvailability(bool online) =>
      '/api/providers/status?online=$online';
}