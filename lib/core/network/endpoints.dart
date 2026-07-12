import '../config/env.dart';

class Endpoints {
  static final String baseUrl = Env.apiUrl;
  static final String wsUrl = Env.wsUrl;

  // ============ Admin / Trust & Safety ===========
  static const String adminDashboard = '/admin/dashboard';
  static const String trustSafetyRiskScores = '/admin/trust-safety/risk-scores';
  static const String trustSafetyUserActionBase = '/admin/trust-safety/user';

  static const String adminProviders = '/admin/providers';
  static const String adminDisputes = '/admin/disputes';
  static const String adminModerationCases = '/admin/moderation/cases';

  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminSettings = '/admin/settings';

  // ============ End Admin / Trust & Safety ===========


  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String verifyEmail = '/auth/verify';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

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

  // Location Endpoints
  static const String updateLocation = '/location/update';
  static const String providerLocation = '/location/provider';
  static const String nearbyLocations = '/location/nearby';

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