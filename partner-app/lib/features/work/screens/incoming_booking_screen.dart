import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../analytics/analytics_service.dart';

class IncomingBookingScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;
  const IncomingBookingScreen({super.key, required this.dispatch});

  @override
  State<IncomingBookingScreen> createState() => _IncomingBookingScreenState();
}

class _IncomingBookingScreenState extends State<IncomingBookingScreen> {
  final ValueNotifier<int> _countdown = ValueNotifier<int>(45);
  Timer? _timer;
  bool _isResponding = false;
  late final DateTime _receivedAt;

  @override
  void initState() {
    super.initState();
    _receivedAt = DateTime.now();
    OrbitMotion.successHaptic();

    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    partnerAnalytics.trackRequestReceived(
      bookingId: booking['id']?.toString() ?? 'unknown',
      earning: (booking['earning'] ?? booking['partnerSalary'] ?? 500) as int,
      distanceKm: ((booking['distanceKm'] ?? 2.5) as num).toDouble(),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown.value > 0) {
        _countdown.value--;
      } else {
        t.cancel();
        if (mounted) _respond(accept: false);
      }
    });
  }

  Future<void> _respond({required bool accept}) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    _timer?.cancel();

    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    final bookingId = booking['id']?.toString() ?? widget.dispatch['bookingId']?.toString();
    if (bookingId == null) {
      if (mounted) context.go('/work');
      return;
    }

    final responseTimeMs = DateTime.now().difference(_receivedAt).inMilliseconds;

    try {
      if (accept) {
        OrbitMotion.successHaptic();
        partnerAnalytics.trackRequestAccepted(bookingId: bookingId, responseTimeMs: responseTimeMs);
        await partnerApiClient.post('/bookings/$bookingId/accept');
        if (mounted) context.go('/job/$bookingId');
      } else {
        OrbitMotion.lightTap();
        partnerAnalytics.trackRequestRejected(bookingId: bookingId, reason: 'manual_decline');
        await partnerApiClient.post('/bookings/$bookingId/decline');
        if (mounted) context.go('/work');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Failed to respond. Job may no longer be available.'),
            backgroundColor: OrbitColors.danger,
          ),
        );
        context.go('/work');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    final pkg = booking['package'] as Map<String, dynamic>? ?? {};
    final packageName = pkg['name'] ?? booking['packageName'] ?? 'Professional Reel Shoot';
    final payout = booking['earning'] ?? booking['partnerSalary'] ?? 500;
    final distanceKm = booking['distanceKm'] ?? 2.5;
    final clientArea = booking['address'] ?? booking['clientArea'] ?? 'Nearby Area (Within 3 km)';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space16),
          child: Column(
            children: [
              const SizedBox(height: OrbitSpacing.space16),

              // ── Circular Isolated Countdown ─────────────────────────
              ValueListenableBuilder<int>(
                valueListenable: _countdown,
                builder: (context, count, _) {
                  final progress = count / 45.0;
                  final color = count > 15
                      ? OrbitColors.secondary
                      : count > 5
                          ? OrbitColors.warning
                          : OrbitColors.danger;

                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: OrbitColors.surfaceHighlight,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count',
                              style: OrbitTypography.displayLarge.copyWith(
                                color: color,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text('SECONDS', style: OrbitTypography.labelSmall.copyWith(fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: OrbitSpacing.space24),
              Text('NEW SHOOT REQUEST', style: OrbitTypography.headingLarge),
              const SizedBox(height: 4),
              Text('Client is ready for immediate shoot', style: OrbitTypography.bodyMedium),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Request Details Card ────────────────────────────────
              Expanded(
                child: ListView(
                  children: [
                    OrbitCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Guaranteed Payout', style: OrbitTypography.bodySmall),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: OrbitColors.success.withValues(alpha: 0.15),
                                  borderRadius: OrbitRadius.roundedFull,
                                ),
                                child: Text(
                                  'INSTANT PAY',
                                  style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.success),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: OrbitSpacing.space8),
                          Text('₹$payout', style: OrbitTypography.displayLarge.copyWith(color: OrbitColors.success)),
                          const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space24),

                          // Package info
                          Row(
                            children: [
                              const Icon(Icons.videocam_rounded, size: 20, color: OrbitColors.secondary),
                              const SizedBox(width: OrbitSpacing.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Package', style: OrbitTypography.labelSmall),
                                    Text(packageName, style: OrbitTypography.titleSmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: OrbitSpacing.space16),

                          // Location info
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 20, color: OrbitColors.primaryLight),
                              const SizedBox(width: OrbitSpacing.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Client Location', style: OrbitTypography.labelSmall),
                                    Text(clientArea, style: OrbitTypography.bodyMedium),
                                    const SizedBox(height: 2),
                                    Text('$distanceKm km away • ~15 min travel time', style: OrbitTypography.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Thumb Zone Actions (Von Restorff Single Dominant CTA) ─
              const SizedBox(height: OrbitSpacing.space16),
              OrbitPrimaryButton(
                label: 'ACCEPT JOB',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isResponding,
                onPressed: () => _respond(accept: true),
              ),
              const SizedBox(height: OrbitSpacing.space12),
              OrbitSecondaryButton(
                label: 'Decline',
                textColor: OrbitColors.textMuted,
                onPressed: _isResponding ? null : () => _respond(accept: false),
              ),
              const SizedBox(height: OrbitSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }
}
