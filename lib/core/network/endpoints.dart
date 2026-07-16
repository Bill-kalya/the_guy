import '../config/env.dart';

class Endpoints {
  static final String baseUrl = Env.apiUrl;
  static final String wsUrl = Env.wsUrl;

  // ============ Admin / Trust & Safety ===========
  static const String adminDashboard = '/api/admin/dashboard';
  static const String trustSafetyRiskScores = '/api/admin/trust-safety/risk-scores';
  static const String trustSafetyUserActionBase = '/api/admin/trust-safety/user';

  static const String adminProviders = '/api/admin/providers';
  static const String adminDisputes = '/api/admin/disputes';
  static const String adminModerationCases = '/api/admin/moderation/cases';

  static const String adminAuditLogs = '/api/admin/audit-logs';
  static const String adminSettings = '/api/admin/settings';

  // ============ End Admin / Trust & Safety ===========

  // Auth Endpoints (OTP-based)
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // Email verification OTP flow
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendVerification = '/api/auth/resend-otp';

  // Password reset OTP flow
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetOtp = '/api/auth/verify-reset-otp';
  static const String resetPassword = '/api/auth/reset-password';

  // User Endpoints
  static const String userProfile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile';
  static const String getUserById = '/api/users';

  // Jobs Endpoints
  static const String jobs = '/api/jobs';
  static const String requestJob = '/api/jobs/request';
  static const String nearbyJobs = '/api/jobs/nearby';
  static const String jobHistory = '/api/jobs/history';
  static const String acceptJob = '/api/jobs/accept';
  static const String declineJob = '/api/jobs/decline';
  static const String updateJobStatus = '/api/jobs/status';
  static const String completeJob = '/api/jobs/complete';

  // Payment Endpoints
  static const String initiateMpesa = '/api/payments/mpesa/initiate';
  static const String checkPaymentStatus = '/api/payments/status';
  static const String paymentHistory = '/api/payments/history';

  // Location Endpoints
  static const String updateLocation = '/api/location/update';
  static const String providerLocation = '/api/location/provider';
  static const String nearbyLocations = '/api/location/nearby';

  // Providers Endpoints
  static const String nearbyProviders = '/api/providers/nearby';
  static const String providerDetails = '/api/providers';
  static const String providerEarnings = '/api/providers/earnings';
  static const String updateAvailability = '/api/providers/availability';

  // Chat Endpoints
  static const String chatHistory = '/api/chat/history';
  static const String sendMessage = '/api/chat/send';
  static const String markAsRead = '/api/chat/read';

  // Categories
  static const String categories = '/api/categories';
  static const String subCategories = '/api/categories/sub';
  
  // Search
  static const String searchProviders = '/api/search/providers';
  static const String searchSuggestions = '/api/search/suggestions';
}