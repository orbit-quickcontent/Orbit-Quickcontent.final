import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
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

  static const List<String> _stages = [
    'ACCEPTED',
    'EN_ROUTE',
    'ARRIVED',
    'SHOOTING',
    'UPLOADING',
    'COMPLETED',
  ];

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
          final currentStatus = (_booking?['status'] as String? ?? '').toUpperCase();
          if (currentStatus == 'SHOOTING' && _shootTimer == null) {
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
      if (action == 'en-route' || action == 'en_route') {
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

  int _getStageIndex(String status) {
    final s = status.toUpperCase();
    if (s == 'DISPATCHING' || s == 'PARTNER_ASSIGNED') return 0;
    if (s == 'EN_ROUTE' || s == 'EN-ROUTE') return 1;
    if (s == 'ARRIVED') return 2;
    if (s == 'SHOOTING') return 3;
    if (s == 'UPLOADING' || s == 'DELIVERED') return 4;
    if (s == 'COMPLETED' || s == 'PAYOUT_COMPLETED') return 5;
    return _stages.indexOf(s).clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: OrbitColors.background,
        body: Center(child: OrbitLoadingCard(height: 140)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/work'))),
        body: OrbitErrorState(onRetry: _loadJob),
      );
    }

    final rawStatus = (_booking!['status'] as String? ?? 'ACCEPTED').toUpperCase();
    final currentStageIndex = _getStageIndex(rawStatus);
    final pkg = _booking!['package'] as Map<String, dynamic>? ?? {};
    final packageName = pkg['name'] ?? _booking!['packageName'] ?? 'Shoot Package';
    final clientName = _booking!['user']?['name'] ?? _booking!['clientName'] ?? 'Orbit Client';
    final address = _booking!['address'] ?? 'Client Location';
    final payout = _booking!['partnerSalary'] ?? _booking!['earning'] ?? 500;

    // Completed State
    if (currentStageIndex >= 5) {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(OrbitSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: OrbitColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: OrbitColors.success.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: OrbitColors.success, size: 44),
                ),
                const SizedBox(height: OrbitSpacing.space24),
                Text('Shoot Completed!', style: OrbitTypography.headingLarge),
                const SizedBox(height: OrbitSpacing.space8),
                Text(
                  '₹$payout earned & credited to your Orbit wallet.',
                  style: OrbitTypography.bodyMedium.copyWith(color: OrbitColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OrbitSpacing.space32),
                OrbitPrimaryButton(
                  label: 'BACK TO WORK DASHBOARD',
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
        backgroundColor: OrbitColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: Text(
          'ACTIVE SHOOT DISPATCH',
          style: OrbitTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OrbitSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Operational Step Timeline Tracker ─────────────────────────
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS PROGRESSION',
                      style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.0),
                    ),
                    const SizedBox(height: OrbitSpacing.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_stages.length, (index) {
                        final isPast = index < currentStageIndex;
                        final isCurrent = index == currentStageIndex;
                        final color = isCurrent
                            ? OrbitColors.primary
                            : isPast
                                ? OrbitColors.success
                                : OrbitColors.textDisabled;

                        return Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  if (index > 0)
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: isPast || isCurrent ? OrbitColors.success : OrbitColors.borderSubtle,
                                      ),
                                    ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrent
                                          ? OrbitColors.primary
                                          : isPast
                                              ? OrbitColors.success
                                              : OrbitColors.surfaceHighlight,
                                      border: Border.all(color: color, width: 1.5),
                                    ),
                                    child: Center(
                                      child: isPast
                                          ? const Icon(Icons.check, size: 12, color: Colors.black)
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent ? Colors.white : OrbitColors.textDisabled,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (index < _stages.length - 1)
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: isPast ? OrbitColors.success : OrbitColors.borderSubtle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _stages[index].replaceAll('_', ' '),
                                style: OrbitTypography.labelSmall.copyWith(
                                  fontSize: 8,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                  color: isCurrent
                                      ? OrbitColors.textPrimary
                                      : isPast
                                          ? OrbitColors.textSecondary
                                          : OrbitColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── 2. Live Shoot Stopwatch (If in SHOOTING stage) ─────────────
              if (currentStageIndex == 3) ...[
                OrbitCard(
                  backgroundColor: OrbitColors.surfaceElevated,
                  border: Border.all(color: OrbitColors.primary),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, color: OrbitColors.danger, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'SHOOT IN PROGRESS: ',
                        style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        _formatTimer(_shootSeconds),
                        style: OrbitTypography.titleLarge.copyWith(
                          color: OrbitColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.space16),
              ],

              // ── 3. Client & Location Operational Details ───────────────────
              OrbitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clientName, style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(packageName, style: OrbitTypography.bodySmall),
                          ],
                        ),
                        Text(
                          '₹$payout',
                          style: OrbitTypography.titleLarge.copyWith(
                            color: OrbitColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitSpacing.space16),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: OrbitColors.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: OrbitTypography.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── 4. Sticky Bottom Thumb CTA ─────────────────────────────────
              if (currentStageIndex == 0) ...[
                OrbitPrimaryButton(
                  label: 'START NAVIGATION / EN ROUTE',
                  icon: Icons.directions_car_rounded,
                  isLoading: _isActionRunning,
                  onPressed: _isActionRunning ? null : () => _updateStatus('en-route'),
                ),
              ] else if (currentStageIndex == 1) ...[
                OrbitPrimaryButton(
                  label: 'I HAVE ARRIVED AT LOCATION',
                  icon: Icons.location_on_rounded,
                  backgroundColor: OrbitColors.info,
                  isLoading: _isActionRunning,
                  onPressed: _isActionRunning ? null : () => _updateStatus('arrived'),
                ),
              ] else if (currentStageIndex == 2) ...[
                OrbitPrimaryButton(
                  label: 'START CREATOR SHOOT',
                  icon: Icons.videocam_rounded,
                  backgroundColor: OrbitColors.primary,
                  isLoading: _isActionRunning,
                  onPressed: _isActionRunning ? null : () => _updateStatus('start-shoot'),
                ),
              ] else if (currentStageIndex == 3) ...[
                OrbitPrimaryButton(
                  label: 'COMPLETE & UPLOAD FOOTAGE',
                  icon: Icons.cloud_upload_rounded,
                  backgroundColor: OrbitColors.success,
                  textColor: Colors.black,
                  isLoading: _isActionRunning,
                  onPressed: _isActionRunning ? null : () => _updateStatus('complete-shoot'),
                ),
              ] else ...[
                OrbitPrimaryButton(
                  label: 'MARK SHOOT AS COMPLETED',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: OrbitColors.success,
                  textColor: Colors.black,
                  isLoading: _isActionRunning,
                  onPressed: _isActionRunning ? null : () => _updateStatus('complete-shoot'),
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
