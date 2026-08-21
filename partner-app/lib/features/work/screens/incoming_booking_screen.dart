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
  final ValueNotifier<int> _countdown = ValueNotifier<int>(20);
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
    final bookingId = booking['id']?.toString() ?? widget.dispatch['bookingId']?.toString() ?? widget.dispatch['id']?.toString();
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
            content: Text(e.response?.data['message'] ?? 'Job no longer available or assigned to another creator.'),
            backgroundColor: OrbitColors.danger,
          ),
        );
        context.go('/work');
      }
    } catch (_) {
      if (mounted) context.go('/work');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    final pkg = booking['package'] as Map<String, dynamic>? ?? {};
    final packageName = pkg['name'] ?? booking['packageName'] ?? 'Content Creator Shoot';
    final payout = booking['earning'] ?? booking['partnerSalary'] ?? 499;
    final distanceKm = booking['distanceKm'] ?? '2.4';
    final clientArea = booking['address'] ?? booking['clientArea'] ?? 'Sector 62, Noida';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header & Countdown ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: OrbitColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OrbitColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'NEW BOOKING REQUEST',
                      style: OrbitTypography.labelSmall.copyWith(
                        color: OrbitColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _countdown,
                    builder: (context, count, _) {
                      final isUrgent = count <= 5;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isUrgent ? OrbitColors.danger.withValues(alpha: 0.15) : OrbitColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isUrgent ? OrbitColors.danger : OrbitColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: isUrgent ? OrbitColors.danger : OrbitColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${count}s',
                              style: OrbitTypography.labelSmall.copyWith(
                                color: isUrgent ? OrbitColors.danger : OrbitColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Big High-Scannability Payout Amount ────────────────────────
              OrbitCard(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                backgroundColor: OrbitColors.surfaceElevated,
                border: Border.all(color: OrbitColors.borderMedium),
                child: Column(
                  children: [
                    Text(
                      'GUARANTEED PAYOUT',
                      style: OrbitTypography.labelSmall.copyWith(
                        letterSpacing: 1.2,
                        color: OrbitColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹$payout',
                      style: OrbitTypography.displayLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: OrbitColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      packageName,
                      style: OrbitTypography.titleSmall.copyWith(color: OrbitColors.textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── Distance & Operational Route Details ───────────────────────
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: OrbitColors.info.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 20, color: OrbitColors.info),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLIENT LOCATION',
                                style: OrbitTypography.labelSmall.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clientArea,
                                style: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitSpacing.space12),
                    const Divider(color: OrbitColors.borderSubtle, height: 1),
                    const SizedBox(height: OrbitSpacing.space12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('DISTANCE', style: OrbitTypography.labelSmall.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('$distanceKm km', style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: OrbitColors.borderSubtle),
                        Column(
                          children: [
                            Text('ESTIMATED TIME', style: OrbitTypography.labelSmall.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('15-20 min', style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Thumb-Zone Action Buttons (Dominant Accept + Secondary Decline) ──
              OrbitAcceptButton(
                label: 'ACCEPT BOOKING',
                isLoading: _isResponding,
                onPressed: _isResponding ? null : () => _respond(accept: true),
              ),
              const SizedBox(height: OrbitSpacing.space12),
              OrbitDangerButton(
                label: 'DECLINE',
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
