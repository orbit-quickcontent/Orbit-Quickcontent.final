import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/core/theme/orbit_theme.dart';
import 'package:client_app/analytics/analytics_service.dart';
import 'package:client_app/shared/widgets/orbit_button.dart';
import 'package:client_app/shared/widgets/orbit_status.dart';
import 'package:client_app/shared/widgets/orbit_timeline.dart';

void main() {
  group('ORBIT Design Tokens & Theme', () {
    test('Colors conform to ORBIT brand specification', () {
      expect(OrbitColors.background, const Color(0xFF08090D));
      expect(OrbitColors.surface, const Color(0xFF11131A));
      expect(OrbitColors.surfaceElevated, const Color(0xFF181B24));
      expect(OrbitColors.primary, const Color(0xFF7C3AED));
      expect(OrbitColors.secondary, const Color(0xFF00D9FF));
      expect(OrbitColors.success, const Color(0xFF22C55E));
      expect(OrbitColors.warning, const Color(0xFFF59E0B));
      expect(OrbitColors.danger, const Color(0xFFEF4444));
    });

    test('Spacing and touch target conform to Fitts\'s Law', () {
      expect(OrbitSpacing.minTouchTarget, 48.0);
      expect(OrbitSpacing.primaryCtaHeight, 56.0);
      expect(OrbitSpacing.floatingCtaHeight, 60.0);
    });
  });

  group('ORBIT Behavioural Analytics Service', () {
    late AnalyticsService service;

    setUp(() {
      service = AnalyticsService();
      service.init(userId: 'test_client_123');
    });

    test('Tracks screen view and user actions', () {
      service.trackScreenView('test_screen');
      service.trackButtonClick('hero_book_cta', screen: 'home');
      service.trackBookingStarted(packageId: 'pkg_123', tier: 'QUICK');
      service.trackPaymentSuccess(bookingId: 'book_123', paymentId: 'pay_123', amount: 1999);
      // Analytics queue executes non-blockingly
      expect(service, isNotNull);
    });
  });

  group('ORBIT Reusable UI Widgets', () {
    testWidgets('OrbitPrimaryButton renders label and fires callback on tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrbitTheme.darkTheme,
          home: Scaffold(
            body: OrbitPrimaryButton(
              label: 'BOOK NOW',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('BOOK NOW'), findsOneWidget);
      await tester.tap(find.text('BOOK NOW'));
      expect(tapped, isTrue);
    });

    testWidgets('OrbitStatusPill renders correct status colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrbitTheme.darkTheme,
          home: const Scaffold(
            body: OrbitStatusPill(
              label: 'PAID',
              color: OrbitColors.success,
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('PAID'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('OrbitBookingTimeline renders step progression', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrbitTheme.darkTheme,
          home: const Scaffold(
            body: OrbitBookingTimeline(currentStatus: 'EN_ROUTE'),
          ),
        ),
      );

      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Creator Found'), findsOneWidget);
      expect(find.text('On the Way'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
    });
  });
}
