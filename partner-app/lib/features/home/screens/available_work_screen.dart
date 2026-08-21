import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../analytics/analytics_service.dart';
import '../../auth/providers/partner_auth_provider.dart';

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _availableJobs = [];
  Map<String, dynamic>? _activeJob;
  bool _isLoading = true;
  bool _isOnline = true;
  int _todayEarnings = 0;
  int _completedToday = 0;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_work_dashboard');
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _isOnline = !nextState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final partnerName = auth.name?.isNotEmpty == true ? auth.name! : 'Partner';
    final initials = partnerName.isNotEmpty
        ? partnerName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'OP';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: OrbitColors.primary,
          backgroundColor: OrbitColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.only(
              left: OrbitSpacing.space16,
              right: OrbitSpacing.space16,
              top: OrbitSpacing.space12,
              bottom: 100,
            ),
            children: [
              // ── Top Operational Header ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: OrbitColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: OrbitColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? OrbitColors.success : OrbitColors.textDisabled,
                                boxShadow: _isOnline
                                    ? [
                                        BoxShadow(
                                          color: OrbitColors.success.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'ONLINE' : 'OFFLINE',
                              style: OrbitTypography.labelSmall.copyWith(
                                color: _isOnline ? OrbitColors.success : OrbitColors.textMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: OrbitColors.textSecondary, size: 22),
                        onPressed: () => context.push('/notifications'),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OrbitColors.surfaceElevated,
                            border: Border.all(
                              color: _isOnline ? OrbitColors.success : OrbitColors.borderSubtle,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: OrbitTypography.labelMedium.copyWith(
                                color: _isOnline ? OrbitColors.success : OrbitColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── 1. Earnings Summary (High Psychological Value) ─────────────
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TODAY\'S EARNINGS',
                          style: OrbitTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            color: OrbitColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/earnings'),
                          child: Row(
                            children: [
                              Text(
                                'View Wallet',
                                style: OrbitTypography.labelSmall.copyWith(
                                  color: OrbitColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: OrbitColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitSpacing.space8),
                    Text(
                      '₹$_todayEarnings',
                      style: OrbitTypography.displayLarge.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: OrbitColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: OrbitSpacing.space12),
                    const Divider(color: OrbitColors.borderSubtle, height: 1),
                    const SizedBox(height: OrbitSpacing.space12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 16, color: OrbitColors.success),
                              const SizedBox(width: 6),
                              Text(
                                '$_completedToday shoots done',
                                style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: OrbitColors.info),
                              const SizedBox(width: 6),
                              Text(
                                _isOnline ? 'Online now' : 'Paused',
                                style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── 2. Online / Offline Hero Toggle Switch ─────────────────────
              GestureDetector(
                onTap: _toggleOnlineStatus,
                child: AnimatedContainer(
                  duration: OrbitMotion.button,
                  curve: OrbitMotion.standard,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isOnline ? OrbitColors.surfaceElevated : OrbitColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isOnline ? OrbitColors.success.withValues(alpha: 0.4) : OrbitColors.borderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isOnline ? OrbitColors.success : OrbitColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isOnline ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                          color: _isOnline ? Colors.black : OrbitColors.textMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isOnline ? 'ONLINE' : 'OFFLINE',
                              style: OrbitTypography.titleSmall.copyWith(
                                color: _isOnline ? OrbitColors.success : OrbitColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isOnline ? 'You are available for new bookings' : 'You are currently unavailable — Tap to go online',
                              style: OrbitTypography.bodySmall.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isOnline,
                        onChanged: (_) => _toggleOnlineStatus(),
                        activeThumbColor: OrbitColors.success,
                        activeTrackColor: OrbitColors.success.withValues(alpha: 0.3),
                        inactiveThumbColor: OrbitColors.textMuted,
                        inactiveTrackColor: OrbitColors.surfaceHighlight,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── 3. Active Job in Progress (Highest Operational Priority) ───
              if (_activeJob != null) ...[
                Text(
                  'CURRENT ACTIVE JOB',
                  style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: OrbitSpacing.space8),
                OrbitCard(
                  backgroundColor: OrbitColors.surfaceElevated,
                  border: Border.all(color: OrbitColors.primary.withValues(alpha: 0.5), width: 1.5),
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
                                  color: OrbitColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _activeJob!['clientName'] ?? _activeJob!['packageName'] ?? 'Client Shoot',
                                style: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          OrbitStatusPill.fromStatus(_activeJob!['status'] ?? 'ACCEPTED'),
                        ],
                      ),
                      const SizedBox(height: OrbitSpacing.space12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: OrbitColors.info),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _activeJob!['address'] ?? 'Client Location',
                              style: OrbitTypography.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OrbitSpacing.space8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Payout: ₹${_activeJob!['payout'] ?? _activeJob!['partnerSalary'] ?? 500}',
                            style: OrbitTypography.titleSmall.copyWith(color: OrbitColors.success, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '~${_activeJob!['distanceKm'] ?? '2.4'} km away',
                            style: OrbitTypography.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: OrbitSpacing.space16),
                      OrbitPrimaryButton(
                        label: 'VIEW ACTIVE JOB',
                        icon: Icons.navigation_rounded,
                        onPressed: () => context.push('/job/${_activeJob!['id']}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.space20),
              ],

              // ── 4. Radar Scanning or Available Job Requests ────────────────
              Text(
                'NEARBY REQUESTS',
                style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: OrbitSpacing.space8),

              if (_isLoading) ...[
                const OrbitLoadingCard(height: 90),
                const SizedBox(height: 8),
                const OrbitLoadingCard(height: 90),
              ] else if (!_isOnline) ...[
                OrbitCard(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 36, color: OrbitColors.textMuted),
                      const SizedBox(height: 12),
                      Text('You are currently offline', style: OrbitTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Switch to Online above to receive instant nearby shoot bookings.',
                        style: OrbitTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (_availableJobs.isEmpty) ...[
                // Subtle Operational Radar Animation
                OrbitCard(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      RotationTransition(
                        turns: _radarController,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OrbitColors.primary.withValues(alpha: 0.1),
                            border: Border.all(color: OrbitColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.radar_rounded, size: 28, color: OrbitColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('You\'re all set', style: OrbitTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Waiting for nearby shoot requests within 10 km...',
                        style: OrbitTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._availableJobs.map((job) => Padding(
                      padding: const EdgeInsets.only(bottom: OrbitSpacing.space12),
                      child: OrbitCard(
                        onTap: () => context.push('/incoming', extra: job),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    job['packageName'] ?? 'Shoot Request',
                                    style: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${job['earning'] ?? job['partnerSalary'] ?? 500}',
                                  style: OrbitTypography.titleLarge.copyWith(
                                    color: OrbitColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job['clientArea'] ?? job['address'] ?? 'Nearby Area',
                              style: OrbitTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: OrbitSpacing.space12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.directions_car_outlined, size: 14, color: OrbitColors.info),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${job['distanceKm'] ?? '2.4'} km • ETA ~15 min',
                                      style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const OrbitStatusPill(
                                  label: 'NEW REQUEST',
                                  color: OrbitColors.primary,
                                  icon: Icons.flash_on_rounded,
                                ),
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
