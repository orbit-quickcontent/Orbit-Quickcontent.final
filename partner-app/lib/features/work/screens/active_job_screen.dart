import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';
import '../../../analytics/analytics_service.dart';

class ActiveJobScreen extends StatefulWidget {
  final String bookingId;
  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isActionRunning = false;
  Timer? _shootTimer;
  int _shootSeconds = 0;

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_active_job');
    _loadJob();
  }

  @override
  void dispose() {
    _shootTimer?.cancel();
    super.dispose();
  }

  void _startShootTimer() {
    _shootTimer?.cancel();
    _shootTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _shootSeconds++);
    });
  }

  Future<void> _loadJob() async {
    try {
      final res = await partnerApiClient.get('/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data;
          _isLoading = false;
          if (_booking?['status'] == 'SHOOTING' && _shootTimer == null) {
            _startShootTimer();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String action, {Map<String, dynamic>? payload}) async {
    setState(() => _isActionRunning = true);
    OrbitMotion.lightTap();

    try {
      if (action == 'en-route') {
        partnerAnalytics.trackNavigationStarted(bookingId: widget.bookingId);
      } else if (action == 'arrived') {
        partnerAnalytics.trackArrival(bookingId: widget.bookingId);
      } else if (action == 'start-shoot') {
        partnerAnalytics.trackShootStarted(bookingId: widget.bookingId);
        _startShootTimer();
      } else if (action == 'complete-shoot') {
        _shootTimer?.cancel();
        partnerAnalytics.trackShootCompleted(bookingId: widget.bookingId, durationMinutes: (_shootSeconds / 60).ceil());
      }

      await partnerApiClient.post('/bookings/${widget.bookingId}/$action', data: payload);
      await _loadJob();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update job status. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: OrbitColors.background,
        body: Center(child: OrbitLoadingSkeleton(width: 200, height: 200)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/work'))),
        body: OrbitErrorState(onRetry: _loadJob),
      );
    }

    final status = _booking!['status'] as String? ?? 'PENDING';
    final pkg = _booking!['package'] as Map<String, dynamic>? ?? {};
    final address = _booking!['address'] ?? 'Client Location';
    final payout = _booking!['partnerSalary'] ?? 500;

    // Peak-End Screen (Completed State)
    if (['DELIVERED', 'COMPLETED', 'PAYOUT_COMPLETED'].contains(status)) {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(OrbitSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: OrbitColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: OrbitColors.success.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 48, color: OrbitColors.success),
                ),
                const SizedBox(height: OrbitSpacing.space24),
                Text('Job Completed!', style: OrbitTypography.displayLarge.copyWith(fontSize: 32)),
                const SizedBox(height: OrbitSpacing.space8),
                Text('You earned ₹$payout for this shoot.', style: OrbitTypography.bodyLarge),
                const SizedBox(height: OrbitSpacing.space32),
                OrbitMetricCard(
                  title: 'Wallet Credit',
                  value: '₹$payout',
                  subtitle: 'Added to your available balance',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: OrbitColors.success,
                ),
                const Spacer(),
                OrbitPrimaryButton(
                  label: 'VIEW EARNINGS',
                  icon: Icons.account_balance_wallet_outlined,
                  onPressed: () => context.go('/earnings'),
                ),
                const SizedBox(height: OrbitSpacing.space12),
                OrbitSecondaryButton(
                  label: 'Back to Work',
                  onPressed: () => context.go('/work'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.go('/work')),
        title: Text('Job Execution', style: OrbitTypography.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: OrbitSpacing.space16),
            child: OrbitStatusPill.fromStatus(status),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card ──────────────────────────────────────────
              OrbitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pkg['name'] ?? 'Reel Shoot', style: OrbitTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(address, style: OrbitTypography.bodySmall),
                    const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Earnings for Shoot', style: OrbitTypography.bodySmall),
                        Text('₹$payout', style: OrbitTypography.titleLarge.copyWith(color: OrbitColors.success)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Stage Specific Content ───────────────────────────────
              Expanded(
                child: Center(
                  child: status == 'SHOOTING'
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: OrbitColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: OrbitSpacing.space16),
                            Text('SHOOTING IN PROGRESS', style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.danger, letterSpacing: 2)),
                            const SizedBox(height: OrbitSpacing.space12),
                            Text(
                              _formatTimer(_shootSeconds),
                              style: OrbitTypography.displayLarge.copyWith(fontSize: 56, letterSpacing: 2),
                            ),
                            const SizedBox(height: OrbitSpacing.space8),
                            Text('Capture standard 9:16 reels for creator', style: OrbitTypography.bodySmall),
                          ],
                        )
                      : status == 'UPLOADING'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(color: OrbitColors.secondary),
                                const SizedBox(height: OrbitSpacing.space20),
                                Text('Uploading Raw Footage', style: OrbitTypography.titleMedium),
                                const SizedBox(height: 6),
                                Text('Syncing files to editor queue...', style: OrbitTypography.bodySmall),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: OrbitColors.surfaceHighlight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.navigation_rounded, size: 36, color: OrbitColors.secondary),
                                ),
                                const SizedBox(height: OrbitSpacing.space16),
                                Text(
                                  status == 'PARTNER_ASSIGNED'
                                      ? 'Ready to head to client'
                                      : status == 'EN_ROUTE'
                                          ? 'Navigating to destination'
                                          : 'You have arrived at shoot location',
                                  style: OrbitTypography.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  address,
                                  style: OrbitTypography.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                ),
              ),

              // ── Progressive Disclosure Primary CTA (Thumb Zone) ───────
              if (status == 'PARTNER_ASSIGNED') ...[
                OrbitPrimaryButton(
                  label: 'START NAVIGATION',
                  icon: Icons.navigation_rounded,
                  isLoading: _isActionRunning,
                  onPressed: () => _updateStatus('en-route'),
                ),
              ] else if (status == 'EN_ROUTE') ...[
                OrbitPrimaryButton(
                  label: 'I\'M HERE (ARRIVED)',
                  icon: Icons.pin_drop_rounded,
                  isLoading: _isActionRunning,
                  onPressed: () => _updateStatus('arrived'),
                ),
              ] else if (status == 'ARRIVED') ...[
                OrbitPrimaryButton(
                  label: 'START SHOOT',
                  icon: Icons.fiber_manual_record_rounded,
                  gradient: const LinearGradient(colors: [OrbitColors.primary, OrbitColors.danger]),
                  isLoading: _isActionRunning,
                  onPressed: () => _updateStatus('start-shoot'),
                ),
              ] else if (status == 'SHOOTING') ...[
                OrbitPrimaryButton(
                  label: 'FINISH SHOOT',
                  icon: Icons.stop_circle_rounded,
                  gradient: const LinearGradient(colors: [OrbitColors.danger, Color(0xFF991B1B)]),
                  isLoading: _isActionRunning,
                  onPressed: () => _updateStatus('complete-shoot'),
                ),
              ] else if (status == 'UPLOADING') ...[
                OrbitPrimaryButton(
                  label: 'COMPLETE JOB',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isActionRunning,
                  onPressed: () => _updateStatus('complete-shoot'),
                ),
              ],
              const SizedBox(height: OrbitSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }
}
