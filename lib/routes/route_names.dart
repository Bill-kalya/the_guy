class RouteNames {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';

  // Customer Routes
  static const String home = '/home';
  static const String requestService = '/request-service';
  static const String matching = '/matching';
  static const String activeJob = '/active-job';
  static const String jobHistory = '/job-history';
  static const String jobDetails = '/job-details';

  // Chat Routes
  static const String chat = '/chat';
  static const String chatDetails = '/chat/:jobId';

  // Payment Routes
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/addresses';
  static const String addAddress = '/addresses/add';
  static const String editAddress = '/addresses/edit';
  static const String paymentMethods = '/payment-methods';
  static const String notifications = '/notifications';
  static const String security = '/security';
  static const String about = '/about';
  static const String help = '/help';

  // Provider Routes
  static const String providerHome = '/provider/home';
  static const String providerIncomingJob = '/provider/incoming-job';
  static const String providerActiveJob = '/provider/active-job';
  static const String providerEarnings = '/provider/earnings';
  static const String providerProfile = '/provider/profile';
  static const String providerHistory = '/provider/history';

  // Common
  static const String settings = '/settings';
  static const String search = '/search';
  static const String notificationsList = '/notifications-list';

  // Helper method to build dynamic routes
  static String chatWithId(String jobId) => '/chat/$jobId';
  static String jobDetailsWithId(String jobId) => '/job-details/$jobId';
  static String matchingWithId(String jobId) => '/matching/$jobId';
  static String activeJobWithId(String jobId) => '/active-job/$jobId';
}
