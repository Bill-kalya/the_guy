import '../config/env.dart';

class Endpoints {
  static final String baseUrl = Env.apiUrl;
  static final String wsUrl = Env.wsUrl;

  // ============ Admin ============
  static const String adminBase = '/api/v1/admin';
  static const String adminAuditLogs = '$adminBase/audit-logs';
  static const String adminImpersonate = '$adminBase/impersonate';

  // Admin Users
  static const String adminUsersSummary = '$adminBase/users/summary';
  static const String adminUsersRiskOverview = '$adminBase/users/risk-overview';
  static const String adminUsers = '$adminBase/users';
  static String adminUserDetail(String userId) => '$adminBase/users/$userId';

  // Admin Providers
  static const String adminProvidersSummary = '$adminBase/providers/summary';
  static const String adminProviders = '$adminBase/providers';
  static String adminProviderDetail(String providerId) => '$adminBase/providers/$providerId';
  static const String adminProvidersImport = '$adminBase/providers/import';
  static String adminProviderClaimCode(String providerId) => '$adminBase/providers/$providerId/claim-code';

  // Admin Finance
  static const String adminFinanceSummary = '$adminBase/finance/summary';
  static const String adminFinanceRevenueTrend = '$adminBase/finance/revenue-trend';
  static const String adminFinancePendingPayouts = '$adminBase/finance/payouts/pending';
  static const String adminFinanceLedger = '$adminBase/finance/ledger';

  // Admin Jobs
  static const String adminJobsSummary = '$adminBase/jobs/summary';
  static const String adminJobs = '$adminBase/jobs';

  // Admin Trust & Safety
  static const String adminSafetySummary = '$adminBase/trust-safety/summary';
  static const String adminSafetyAlerts = '$adminBase/trust-safety/alerts';
  static const String adminSafetyHeatmap = '$adminBase/trust-safety/heatmap';
  static const String adminSafetyModerationQueue = '$adminBase/trust-safety/moderation-queue';
  static const String adminSafetyRiskScores = '$adminBase/trust-safety/risk-scores';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleAuth = '/api/auth/google';
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
  static const String initiateMpesa = '/api/payments/initiate';
  static String paymentStatus(String paymentId) => '/api/payments/$paymentId/status';
  static const String paymentHistory = '/api/payments/history';

  // Location
  static const String updateLocation = '/api/location/update';
  static const String nearbyLocations = '/api/location/nearby';

  // Providers
  static const String nearbyProviders = '/api/providers/nearby';
  static const String providerRegister = '/api/providers/register';
  static const String providerMe = '/api/providers/me';
  static const String providerMeCompletion = '/api/providers/me/completion';
  static const String providerMePerformance = '/api/providers/me/performance';
  static const String providerMeGoals = '/api/providers/me/goals';
  static const String providerMeReputation = '/api/providers/me/reputation';
  static const String providerMeInsights = '/api/providers/me/insights';
  static const String providerMeWallet = '/api/providers/me/wallet';
  static const String providerMeDashboard = '/api/providers/me/dashboard';
  static const String providerEarnings = '/api/providers/earnings';

  // Wallet & Payouts
  static const String wallet = '/api/wallet';
  static const String walletTransactions = '/api/wallet/transactions';
  static const String requestPayout = '/api/payouts/request';
  static const String payoutHistory = '/api/payouts/history';

  // Disputes
  static const String disputes = '/api/disputes';
  static const String openDisputes = '/api/disputes/open';

  // Search
  static const String searchProviders = '/api/search/providers';
  static const String searchSuggestions = '/api/search/suggestions';

  // Reviews
  static const String reviews = '/api/reviews';
  static String reviewSummary(String providerId) => '/api/reviews/provider/$providerId/summary';

  // Chat
  static const String chatHistory = '/api/chat/history';
  static const String sendMessage = '/api/chat/send';
  static const String markAsRead = '/api/chat/read';

  // Categories
  static const String categories = '/api/categories';
  static const String subCategories = '/api/categories/sub';

  // Platform (public)
  static const String platformStats = '/api/platform/stats';

  // Pricing
  static const String providerPricing = '/api/provider/pricing';

  // Quotes
  static const String quotes = '/api/quotes';
  static String quoteById(String quoteId) => '/api/quotes/$quoteId';
  static String acceptQuote(String quoteId) => '/api/quotes/$quoteId/accept';
  static String rejectQuote(String quoteId) => '/api/quotes/$quoteId/reject';
  static String counterQuote(String quoteId) => '/api/quotes/$quoteId/counter';
  static String acceptCounterQuote(String quoteId) => '/api/quotes/$quoteId/accept-counter';
  static String quotesByJob(String jobId) => '/api/quotes/job/$jobId';
  static const String providerQuotes = '/api/quotes/provider';
  static const String customerQuotes = '/api/quotes/customer';
}

class EndpointBuilder {
  static String acceptJob(String jobId) =>
      '/api/jobs/$jobId/accept';

  static String declineJob(String jobId) =>
      '/api/jobs/$jobId/decline';

  static String completeJob(String jobId) =>
      '/api/jobs/$jobId/complete';

  static String confirmCompletion(String jobId) =>
      '/api/jobs/$jobId/confirm-completion';

  static String rejectCompletion(String jobId) =>
      '/api/jobs/$jobId/reject-completion';

  static String updateJobStatus(String jobId) =>
      '/api/jobs/$jobId/status';

  static String providerLocation(String providerId) =>
      '/api/location/provider/$providerId';

  static String providerAvailability(bool online) =>
      '/api/providers/status?online=$online';

  static String adminSuspendProvider(String providerId) =>
      '${Endpoints.adminBase}/trust-safety/providers/$providerId/suspend';

  static String adminBanProvider(String providerId) =>
      '${Endpoints.adminBase}/trust-safety/providers/$providerId/ban';

  static String adminReinstateProvider(String providerId) =>
      '${Endpoints.adminBase}/trust-safety/providers/$providerId/reinstate';

  static String trackingEta(String jobId) =>
      '/api/tracking/$jobId/eta';

  static String trackingPolyline(String jobId) =>
      '/api/tracking/$jobId/polyline';
}