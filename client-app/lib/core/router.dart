import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/personal_info_screen.dart';
import '../features/auth/screens/permission_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/booking/screens/packages_screen.dart';
import '../features/booking/screens/location_picker_screen.dart';
import '../features/booking/screens/booking_review_screen.dart';
import '../features/booking/screens/payment_screen.dart';
import '../features/booking/screens/finding_partner_screen.dart';
import '../features/booking/screens/booking_status_screen.dart';
import '../features/booking/screens/booking_history_screen.dart';
import '../features/tracking/screens/live_tracking_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/permissions' ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute) return '/permissions';
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (ctx, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (ctx, state) => OtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (ctx, state) => const PersonalInfoScreen(),
      ),
      // Shell with bottom navigation
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
          GoRoute(path: '/history', builder: (ctx, state) => const BookingHistoryScreen()),
          GoRoute(path: '/notifications', builder: (ctx, state) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (ctx, state) => const ProfileScreen()),
        ],
      ),
      // Booking flow
      GoRoute(path: '/packages', builder: (ctx, state) => const PackagesScreen()),
      GoRoute(
        path: '/location',
        builder: (ctx, state) => LocationPickerScreen(packageId: (state.extra is String ? state.extra as String : (state.extra as Map?)?['packageId']?.toString()) ?? 'pkg_standard'),
      ),
      GoRoute(
        path: '/location-picker',
        builder: (ctx, state) => LocationPickerScreen(packageId: (state.extra is String ? state.extra as String : (state.extra as Map?)?['packageId']?.toString()) ?? 'pkg_standard'),
      ),
      GoRoute(
        path: '/review',
        builder: (ctx, state) => BookingReviewScreen(
          params: (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : {
                  'packageId': (state.extra is String ? state.extra as String : 'pkg_standard'),
                  'latitude': 28.6139,
                  'longitude': 77.2090,
                  'address': 'Connaught Place, New Delhi',
                },
        ),
      ),
      GoRoute(
        path: '/payment',
        builder: (ctx, state) => PaymentScreen(
          params: (state.extra is Map<String, dynamic>)
              ? state.extra as Map<String, dynamic>
              : {'bookingId': 'bk_${DateTime.now().millisecondsSinceEpoch}'},
        ),
      ),
      GoRoute(
        path: '/finding-partner',
        builder: (ctx, state) {
          final bId = (state.extra is String)
              ? state.extra as String
              : (state.extra is Map ? (state.extra as Map)['bookingId']?.toString() : null);
          return FindingPartnerScreen(bookingId: bId ?? 'bk_${DateTime.now().millisecondsSinceEpoch}');
        },
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (ctx, state) => BookingStatusScreen(bookingId: state.pathParameters['id'] ?? 'bk_default'),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (ctx, state) => LiveTrackingScreen(bookingId: state.pathParameters['id'] ?? 'bk_default'),
      ),
    ],
    errorBuilder: (ctx, state) => const LoginScreen(),
  );
});
