import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Customer routes
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart' as otp;
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
import '../core/storage/secure_storage.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final userRoleFuture = ref.read(secureStorageProvider).getUserRole();
  final userRole = userRoleFuture == 'provider';

  return GoRouter(
    initialLocation: '/',
redirect: (context, state) async {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        // Redirect based on user role
        if (userRole == 'provider') {
          return '/provider/home';
        } else {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'otp',
        path: '/otp',
        builder: (context, state) {
          final phoneNumber = state.extra as String;
          return otp.OTPScreen(phoneNumber: phoneNumber);
        },

      ),

      // Customer routes
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
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

      // Provider routes
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
