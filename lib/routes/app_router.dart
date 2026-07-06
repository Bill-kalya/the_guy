import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Customer routes
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart' as verify_email;
import '../features/home/screens/home_screen.dart';
import '../features/jobs/screens/request_service_screen.dart';
import '../features/jobs/screens/matching_screen.dart';
import '../features/jobs/screens/active_job_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/payment/screens/payment_screen.dart';
import '../features/profile/screens/profile_screen.dart';

// Provider routes
import '../features/provider/presentation/screens/provider_home_screen.dart';
import '../features/provider/presentation/screens/incoming_job_screen.dart';
import '../features/provider/presentation/screens/active_jobs_screen.dart';
import '../features/provider/presentation/screens/earnings_screen.dart';

// Providers
import '../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/verify-email';
      final isHomeRoute = location == '/';

      // If authenticated and on an auth route (login/register/verify-email), redirect to home
      if (isAuthenticated && isAuthRoute) {
        final userRole = authState.user?.role ?? 'customer';
        if (userRole == 'provider') {
          return '/provider/home';
        }
        return '/';
      }

      // If on root path, always show home (public landing page)
      if (isHomeRoute) {
        return null;
      }

      // Auth-required routes - redirect to login if not authenticated
      final authRequiredRoutes = [
        '/request-service',
        '/matching',
        '/active-job',
        '/chat',
        '/payment',
        '/profile',
        '/provider',
      ];

      final isAuthRequired = authRequiredRoutes.any(
        (route) => location.startsWith(route),
      );

      if (!isAuthenticated && isAuthRequired) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Public landing page (root)
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // Auth routes
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'verify-email',
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String;
          return verify_email.EmailVerificationScreen(email: email);
        },
      ),

      // Customer routes (auth-required)
      GoRoute(
        name: 'request-service',
        path: '/request-service',
        builder: (context, state) => const RequestServiceScreen(),
      ),
      GoRoute(
        name: 'matching',
        path: '/matching/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return MatchingScreen(jobId: jobId);
        },
      ),
      GoRoute(
        name: 'active-job',
        path: '/active-job/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return ActiveJobScreen(jobId: jobId);
        },
      ),
      GoRoute(
        name: 'chat',
        path: '/chat/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          final extraData = state.extra as Map<String, dynamic>?;
          final providerName = extraData?['providerName'] ?? 'Provider';
          return ChatScreen(
            jobId: jobId,
            providerName: providerName,
          );
        },
      ),
      GoRoute(
        name: 'payment',
        path: '/payment/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return PaymentScreen(jobId: jobId);
        },
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Provider routes (auth-required)
      GoRoute(
        name: 'provider-home',
        path: '/provider/home',
        builder: (context, state) => const ProviderHomeScreen(),
      ),
      GoRoute(
        name: 'incoming-job',
        path: '/provider/incoming-job',
        builder: (context, state) => const IncomingJobScreen(),
      ),
      GoRoute(
        name: 'provider-active-job',
        path: '/provider/active-job',
        builder: (context, state) => const ActiveJobsScreen(),
      ),
      GoRoute(
        name: 'earnings',
        path: '/provider/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
    ],
  );
});