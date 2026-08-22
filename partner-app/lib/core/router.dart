import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/partner_landing_screen.dart';
import '../features/auth/screens/partner_login_screen.dart';
import '../features/auth/screens/partner_otp_screen.dart';
import '../features/auth/screens/partner_onboarding_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/permission_screen.dart';
import '../features/home/screens/available_work_screen.dart';
import '../features/work/screens/work_history_screen.dart';
import '../features/work/screens/active_job_screen.dart';
import '../features/work/screens/incoming_booking_screen.dart';
import '../features/earnings/screens/earnings_screen.dart';
import '../features/profile/screens/partner_profile_screen.dart';
import '../features/auth/providers/partner_auth_provider.dart';

final partnerRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(partnerAuthProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final needsOnboarding = auth.needsOnboarding;
      final isAuthRoute = state.matchedLocation.startsWith('/login') || 
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/landing' ||
          state.matchedLocation == '/permissions';

      if (!isLoggedIn && !isAuthRoute) return '/landing';
      if (isLoggedIn && needsOnboarding && state.matchedLocation != '/onboarding' && state.matchedLocation != '/splash' && state.matchedLocation != '/permissions' && state.matchedLocation != '/landing') return '/onboarding';
      if (isLoggedIn && !needsOnboarding && isAuthRoute && state.matchedLocation != '/splash' && state.matchedLocation != '/permissions' && state.matchedLocation != '/landing') return '/available-work';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/landing', builder: (_, __) => const PartnerLandingScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionScreen()),
      GoRoute(path: '/login', builder: (_, __) => const PartnerLoginScreen()),
      GoRoute(path: '/otp', builder: (ctx, state) => PartnerOtpScreen(email: state.extra as String)),
      GoRoute(path: '/onboarding', builder: (_, __) => const PartnerOnboardingScreen()),
      GoRoute(path: '/work', builder: (_, __) => const AvailableWorkScreen()),
      GoRoute(path: '/available-work', builder: (_, __) => const AvailableWorkScreen()),
      GoRoute(path: '/work-history', builder: (_, __) => const WorkHistoryScreen()),
      GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const PartnerProfileScreen()),
      GoRoute(path: '/job/:id', builder: (ctx, state) => ActiveJobScreen(bookingId: state.pathParameters['id']!)),
      GoRoute(
        path: '/incoming',
        builder: (ctx, state) => IncomingBookingScreen(
          dispatch: state.extra as Map<String, dynamic>,
        ),
      ),
    ],
  );
});
