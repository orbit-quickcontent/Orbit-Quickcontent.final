import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';
import '../../../analytics/analytics_service.dart';
import '../../auth/providers/partner_auth_provider.dart';

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen> {
  List<Map<String, dynamic>> _availableJobs = [];
  Map<String, dynamic>? _activeJob;
  bool _isLoading = true;
  bool _isOnline = true;
  int _todayEarnings = 0;
  int _completedToday = 0;

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_work_dashboard');
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        partnerApiClient.get('/partner/available-jobs'),
        partnerApiClient.get('/partner/earnings/summary'),
      ]);

      final jobsRes = results[0];
      final earningsRes = results[1];

      final jobs = List<Map<String, dynamic>>.from(jobsRes.data['jobs'] ?? []);
      final active = jobsRes.data['activeJob'] as Map<String, dynamic>?;
      final earningsData = earningsRes.data ?? {};

      if (mounted) {
        setState(() {
          _availableJobs = jobs;
          _activeJob = active;
          _todayEarnings = (earningsData['todayEarnings'] ?? 0) as int;
          _completedToday = (earningsData['completedToday'] ?? 0) as int;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final nextState = !_isOnline;
    OrbitMotion.mediumImpact();
    setState(() => _isOnline = nextState);
    partnerAnalytics.trackOnlineToggled(isOnline: nextState);

    try {
      await partnerApiClient.patch('/partner/status', data: {'isOnline': nextState});
    } catch (_) {
      // Revert if failed
      if (mounted) setState(() => _isOnline = !nextState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final partnerName = auth.name?.isNotEmpty == true ? auth.name! : 'Creator Partner';
    final initials = partnerName.isNotEmpty
        ? partnerName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'OP';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: OrbitColors.secondary,
          backgroundColor: OrbitColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.only(
              left: OrbitSpacing.space20,
              right: OrbitSpacing.space20,
              top: OrbitSpacing.space16,
              bottom: 100,
            ),
            children: [
              // ── Header (Partner Profile & Status) ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: OrbitColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isOnline ? OrbitColors.success : OrbitColors.textDisabled,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: OrbitTypography.titleSmall.copyWith(
                              color: _isOnline ? OrbitColors.success : OrbitColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: OrbitSpacing.space12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partnerName, style: OrbitTypography.titleMedium),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isOnline ? OrbitColors.success : OrbitColors.textDisabled,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOnline ? 'Online & Available' : 'Offline',
                                style: OrbitTypography.bodySmall.copyWith(
                                  color: _isOnline ? OrbitColors.success : OrbitColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: OrbitColors.textPrimary, size: 24),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Online / Offline Hero Switch Control ──────────────────
              GestureDetector(
                onTap: _toggleOnlineStatus,
                child: AnimatedContainer(
                  duration: OrbitMotion.button,
                  curve: OrbitMotion.standard,
                  padding: const EdgeInsets.all(OrbitSpacing.space20),
                  decoration: BoxDecoration(
                    color: _isOnline ? OrbitColors.surfaceElevated : OrbitColors.surface,
                    borderRadius: OrbitRadius.rounded24,
                    border: Border.all(
                      color: _isOnline ? OrbitColors.success.withValues(alpha: 0.4) : OrbitColors.borderMedium,
                      width: 1.5,
                    ),
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: OrbitColors.success.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _isOnline ? OrbitColors.success : OrbitColors.surfaceHighlight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isOnline ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                          color: _isOnline ? Colors.black : OrbitColors.textMuted,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: OrbitSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                              style: OrbitTypography.titleSmall.copyWith(
                                color: _isOnline ? OrbitColors.textPrimary : OrbitColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isOnline ? 'Accepting nearby shoot requests' : 'Tap to go online and receive jobs',
                              style: OrbitTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isOnline ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: _isOnline ? OrbitColors.success : OrbitColors.textDisabled,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Active Job Card (If in progress) ──────────────────────
              if (_activeJob != null) ...[
                OrbitCard(
                  backgroundColor: OrbitColors.secondary.withValues(alpha: 0.1),
                  border: Border.all(color: OrbitColors.secondary.withValues(alpha: 0.4)),
                  onTap: () => context.push('/active-job', extra: _activeJob!['id']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: OrbitColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Active Job in Progress', style: OrbitTypography.titleSmall),
                            ],
                          ),
                          OrbitStatusPill.fromStatus(_activeJob!['status'] ?? 'ACCEPTED'),
                        ],
                      ),
                      const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space24),
                      Text(_activeJob!['address'] ?? 'Client Location', style: OrbitTypography.bodyMedium),
                      const SizedBox(height: OrbitSpacing.space12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payout: ₹${_activeJob!['payout'] ?? 500}', style: OrbitTypography.titleSmall.copyWith(color: OrbitColors.success)),
                          const Icon(Icons.arrow_forward_rounded, color: OrbitColors.secondary, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.space24),
              ],

              // ── Partner Stats / Metrics ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OrbitMetricCard(
                      title: 'Today\'s Earnings',
                      value: '₹$_todayEarnings',
                      subtitle: '$_completedToday jobs completed',
                      icon: Icons.currency_rupee_rounded,
                      iconColor: OrbitColors.success,
                    ),
                  ),
                  const SizedBox(width: OrbitSpacing.space12),
                  Expanded(
                    child: OrbitMetricCard(
                      title: 'Acceptance Rate',
                      value: '98%',
                      subtitle: 'Top Tier Partner',
                      icon: Icons.speed_rounded,
                      iconColor: OrbitColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space32),

              // ── Nearby Job Requests / Empty State ─────────────────────
              Text('Nearby Requests', style: OrbitTypography.headingMedium),
              const SizedBox(height: OrbitSpacing.space12),

              if (_isLoading) ...[
                const OrbitLoadingCard(height: 100),
                const OrbitLoadingCard(height: 100),
              ] else if (!_isOnline) ...[
                OrbitEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'You are currently offline',
                  description: 'Switch your status to Online above to start receiving instant booking dispatches within 10 km.',
                  ctaLabel: 'Go Online',
                  onCtaPressed: _toggleOnlineStatus,
                ),
              ] else if (_availableJobs.isEmpty) ...[
                OrbitEmptyState(
                  icon: Icons.radar_rounded,
                  title: 'Scanning for nearby shoots',
                  description: 'You\'re online! New requests will pop up automatically as clients in your area place bookings.',
                ),
              ] else ...[
                ..._availableJobs.map((job) => Padding(
                      padding: const EdgeInsets.only(bottom: OrbitSpacing.space12),
                      child: OrbitCard(
                        onTap: () => context.push('/incoming-booking', extra: job),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(job['packageName'] ?? 'Shoot Request', style: OrbitTypography.titleSmall),
                                Text(
                                  '₹${job['earning'] ?? 500}',
                                  style: OrbitTypography.titleMedium.copyWith(color: OrbitColors.success),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(job['clientArea'] ?? 'Nearby Client', style: OrbitTypography.bodySmall),
                            const SizedBox(height: OrbitSpacing.space12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${job['distanceKm'] ?? '2.5'} km away • ETA ~15 min', style: OrbitTypography.labelSmall),
                                OrbitStatusPill.fromStatus('PENDING'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
