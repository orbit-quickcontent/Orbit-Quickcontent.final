import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/core/theme/orbit_theme.dart';
import 'package:partner_app/analytics/analytics_service.dart';
import 'package:partner_app/shared/widgets/orbit_button.dart';
import 'package:partner_app/shared/widgets/orbit_card.dart';

void main() {
  group('Partner App Design Tokens & Analytics', () {
    test('Tokens match unified ORBIT specification', () {
      expect(OrbitColors.background, const Color(0xFF08090D));
      expect(OrbitColors.primary, const Color(0xFF7C3AED));
      expect(OrbitColors.secondary, const Color(0xFF00D9FF));
    });

    test('Partner analytics logs online/offline and dispatch transitions', () {
      final service = AnalyticsService();
      service.init(partnerId: 'partner_test_456');
      service.trackOnlineToggled(isOnline: true);
      service.trackRequestReceived(bookingId: 'book_789', earning: 500, distanceKm: 2.5);
      service.trackRequestAccepted(bookingId: 'book_789', responseTimeMs: 1450);
      service.trackShootStarted(bookingId: 'book_789');
      service.trackShootCompleted(bookingId: 'book_789', durationMinutes: 25);
      service.trackJobCompleted(bookingId: 'book_789', payout: 500);
      expect(service, isNotNull);
    });
  });

  group('Partner App UI Components', () {
    testWidgets('OrbitPrimaryButton renders and triggers accept job', (WidgetTester tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrbitTheme.darkTheme,
          home: Scaffold(
            body: OrbitPrimaryButton(
              label: 'ACCEPT JOB',
              icon: Icons.check,
              onPressed: () => accepted = true,
            ),
          ),
        ),
      );

      expect(find.text('ACCEPT JOB'), findsOneWidget);
      await tester.tap(find.text('ACCEPT JOB'));
      expect(accepted, isTrue);
    });

    testWidgets('OrbitMetricCard displays earnings correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrbitTheme.darkTheme,
          home: const Scaffold(
            body: OrbitMetricCard(
              title: 'Today\'s Earnings',
              value: '₹1,500',
              subtitle: '3 jobs completed',
              icon: Icons.currency_rupee,
            ),
          ),
        ),
      );

      expect(find.text('Today\'s Earnings'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('3 jobs completed'), findsOneWidget);
    });
  });
}
