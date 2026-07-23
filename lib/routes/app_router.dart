import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Customer routes
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart' as verify_email;
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/verify_reset_otp_screen.dart' as verify_reset;
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/change_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/jobs/screens/request_service_screen.dart';
import '../features/jobs/screens/matching_screen.dart';
import '../features/jobs/screens/active_job_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/payment/screens/payment_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';

// Admin routes
import '../features/admin/presentation/pages/admin_home_page.dart';
import '../features/admin/presentation/pages/admin_profile_page.dart';
import '../features/admin/presentation/pages/admin_providers_page.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/admin/presentation/pages/admin_finance_page.dart';
import '../features/admin/presentation/pages/admin_analytics_page.dart';
import '../features/admin/presentation/pages/admin_jobs_page.dart';
import '../features/admin/presentation/pages/admin_settings_page.dart';
import '../features/admin/presentation/pages/trust_safety_center_page.dart';

// Provider routes
import '../features/provider/presentation/screens/provider_home_screen.dart';
import '../features/provider/presentation/screens/incoming_job_screen.dart';
import '../features/provider/presentation/screens/active_jobs_screen.dart';
import '../features/provider/presentation/screens/earnings_screen.dart';
import '../features/provider/presentation/screens/provider_profile_screen.dart';
import '../features/provider/presentation/screens/provider_registration_screen.dart';
import '../features/provider/presentation/screens/wallet_screen.dart';
import '../features/provider/presentation/widgets/provider_shell_screen.dart';

// Providers
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/models/auth_state.dart';

/// Bridges Riverpod auth state changes into a [Listenable] so GoRouter's
/// [refreshListenable] can re-evaluate [redirect] without recreating the router.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Only notify if the auth status actually changed (login/logout),
      // not on every internal state update (loading, error, etc.)
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.user?.role != next.user?.role) {
        notifyListeners();
      }
    });
  }
}

final _goRouterRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_goRouterRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/verify-email' ||
          location == '/forgot-password' ||
          location == '/verify-reset-otp' ||
          location == '/reset-password';
      final isHomeRoute = location == '/';

      // Unverified user with pending email — send to OTP screen
      if (!isAuthenticated &&
          authState.pendingEmail != null &&
          location != '/verify-email') {
        return '/verify-email';
      }

      // Authenticated and on an auth route — redirect to role-appropriate home
      if (isAuthenticated && isAuthRoute) {
        final userRole = authState.user?.role ?? 'customer';
        if (userRole == 'provider') {
          return '/provider/home';
        }
        if (userRole == 'admin') {
          return '/admin';
        }
        return '/';
      }

      // Root path — redirect non-customer roles to their homes
      if (isHomeRoute) {
        if (isAuthenticated) {
          final userRole = authState.user?.role ?? 'customer';
          if (userRole == 'admin') {
            return '/admin';
          }
          if (userRole == 'provider') {
            return '/provider/home';
          }
        }
        return null;
      }

      // Redirect /profile to role-appropriate profile screen
      if (isAuthenticated && location == '/profile') {
        final userRole = authState.user?.role ?? 'customer';
        if (userRole == 'provider') {
          return '/provider/profile';
        }
        if (userRole == 'admin') {
          return '/admin';
        }
      }

      // Auth-required routes — redirect to login if not authenticated
      final authRequiredRoutes = [
        '/request-service',
        '/matching',
        '/active-job',
        '/chat',
        '/payment',
        '/profile',
        '/provider',
        '/wallet',
        '/admin',
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
      // Admin routes (auth-required)
      GoRoute(
        name: 'admin-home',
        path: '/admin',
        builder: (context, state) => const AdminHomePage(),
      ),
      GoRoute(
        name: 'admin-providers',
        path: '/admin/providers',
        builder: (context, state) => const AdminProvidersPage(),
      ),
      GoRoute(
        name: 'admin-users',
        path: '/admin/users',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        name: 'admin-jobs',
        path: '/admin/jobs',
        builder: (context, state) => const AdminJobsPage(),
      ),
      GoRoute(
        name: 'admin-finance',
        path: '/admin/finance',
        builder: (context, state) => const AdminFinancePage(),
      ),
      GoRoute(
        name: 'admin-analytics',
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsPage(),
      ),
      GoRoute(
        name: 'admin-trust-safety',
        path: '/admin/trust-safety',
        builder: (context, state) => const TrustSafetyCenterPage(),
      ),
      GoRoute(
        name: 'admin-profile',
        path: '/admin/profile',
        builder: (context, state) => const AdminProfilePage(),
      ),
      GoRoute(
        name: 'admin-settings',
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsPage(),
      ),

      // Public landing page (root)
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'search',
        path: '/search',
        builder: (context, state) => const SearchScreen(),
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
          final authState = ref.read(authProvider);
          final email = authState.pendingEmail ?? (state.extra as String?);
          return verify_email.EmailVerificationScreen(email: email ?? '');
        },
      ),
      GoRoute(
        name: 'forgot-password',
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: 'verify-reset-otp',
        path: '/verify-reset-otp',
        builder: (context, state) {
          final email = state.extra as String;
          return verify_reset.VerifyResetOtpScreen(email: email);
        },
      ),
      GoRoute(
        name: 'reset-password',
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String;
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        name: 'change-password',
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
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
      GoRoute(
        name: 'edit-profile',
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Provider shell (bottom nav for mobile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ProviderShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              name: 'provider-home',
              path: '/provider/home',
              builder: (context, state) => const ProviderHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: 'provider-active-job',
              path: '/provider/active-job',
              builder: (context, state) => const ActiveJobsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: 'earnings',
              path: '/provider/earnings',
              builder: (context, state) => const EarningsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: 'provider-profile',
              path: '/provider/profile',
              builder: (context, state) => const ProviderProfileScreen(),
            ),
          ]),
        ],
      ),

      // Provider standalone routes (outside shell)
      GoRoute(
        name: 'provider-register',
        path: '/provider/register',
        builder: (context, state) => const ProviderRegistrationScreen(),
      ),
      GoRoute(
        name: 'incoming-job',
        path: '/provider/incoming-job',
        builder: (context, state) => const IncomingJobScreen(),
      ),
      GoRoute(
        name: 'wallet',
        path: '/provider/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
    ],
  );
});
