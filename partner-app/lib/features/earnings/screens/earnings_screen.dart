import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../analytics/analytics_service.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  Map<String, dynamic>? _earningsData;
  bool _isLoading = true;
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_earnings');
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final res = await partnerApiClient.get('/partner/earnings');
      if (mounted) {
        setState(() {
          _earningsData = res.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWithdraw() async {
    final balance = (_earningsData?['totalEarned'] ?? 0) as int;
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balance available for instant withdrawal.')),
      );
      return;
    }

    setState(() => _isWithdrawing = true);
    OrbitMotion.mediumImpact();

    try {
      await partnerApiClient.post('/partner/wallet/withdraw', data: {'amount': balance});
      partnerAnalytics.trackWithdrawal(amount: balance, isSuccess: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Instant withdrawal of ₹$balance requested successfully!'),
            backgroundColor: OrbitColors.success,
          ),
        );
        _loadEarnings();
      }
    } catch (e) {
      partnerAnalytics.trackWithdrawal(amount: balance, isSuccess: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request failed. Please verify bank details.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        appBar: AppBar(
          backgroundColor: OrbitColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.go('/work'),
          ),
          title: Text(
            'EARNINGS & WALLET',
            style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          centerTitle: true,
        ),
        body: const Center(child: OrbitLoadingCard(height: 120)),
      );
    }

    final totalEarned = _earningsData?['totalEarned'] ?? 2450;
    final weekEarned = _earningsData?['weekEarned'] ?? 11850;
    final completedCount = _earningsData?['completedCount'] ?? 8;
    final bonuses = _earningsData?['bonuses'] ?? 1500;
    final tips = _earningsData?['tips'] ?? 850;

    final weeklyBars = [
      {'day': 'M', 'amount': 1200, 'height': 0.4},
      {'day': 'T', 'amount': 1800, 'height': 0.6},
      {'day': 'W', 'amount': 900, 'height': 0.3},
      {'day': 'T', 'amount': 2400, 'height': 0.8},
      {'day': 'F', 'amount': 3100, 'height': 1.0},
      {'day': 'S', 'amount': 2100, 'height': 0.7},
      {'day': 'S', 'amount': 1400, 'height': 0.5},
    ];

    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        backgroundColor: OrbitColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: Text(
          'EARNINGS & WALLET',
          style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEarnings,
          color: OrbitColors.primary,
          backgroundColor: OrbitColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.all(OrbitSpacing.space16),
            children: [
              // ── 1. Today & This Week Primary Balance Hero Card ─────────────
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space20),
                backgroundColor: OrbitColors.surfaceElevated,
                border: Border.all(color: OrbitColors.borderMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S EARNINGS',
                      style: OrbitTypography.labelSmall.copyWith(
                        letterSpacing: 1.2,
                        color: OrbitColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹$totalEarned',
                      style: OrbitTypography.displayLarge.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: OrbitColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: OrbitColors.borderSubtle, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('THIS WEEK', style: OrbitTypography.labelSmall.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('₹$weekEarned', style: OrbitTypography.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('COMPLETED SHOOTS', style: OrbitTypography.labelSmall.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('$completedCount shoots', style: OrbitTypography.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── 2. Instant Payout CTA ──────────────────────────────────────
              OrbitPrimaryButton(
                label: 'INSTANT WITHDRAWAL TO BANK',
                icon: Icons.account_balance_wallet_rounded,
                isLoading: _isWithdrawing,
                onPressed: _isWithdrawing ? null : _handleWithdraw,
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── 3. Weekly Activity Graph ───────────────────────────────────
              Text(
                'WEEKLY ACTIVITY',
                style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: OrbitSpacing.space8),
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeklyBars.map((bar) {
                          final h = (bar['height'] as double) * 80;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 24,
                                height: h,
                                decoration: BoxDecoration(
                                  color: bar['day'] == 'F' ? OrbitColors.primary : OrbitColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bar['day'] as String,
                                style: OrbitTypography.labelSmall.copyWith(
                                  fontSize: 11,
                                  color: bar['day'] == 'F' ? OrbitColors.primary : OrbitColors.textMuted,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── 4. Detailed Financial Breakdown ────────────────────────────
              Text(
                'EARNINGS BREAKDOWN',
                style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: OrbitSpacing.space8),
              OrbitCard(
                padding: const EdgeInsets.all(OrbitSpacing.space16),
                child: Column(
                  children: [
                    _BreakdownRow(
                      title: 'Completed bookings',
                      amount: '₹${weekEarned - bonuses - tips > 0 ? weekEarned - bonuses - tips : 9500}',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space20),
                    _BreakdownRow(
                      title: 'Performance bonuses',
                      amount: '₹$bonuses',
                      icon: Icons.stars_rounded,
                      iconColor: OrbitColors.warning,
                    ),
                    const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space20),
                    _BreakdownRow(
                      title: 'Client tips',
                      amount: '₹$tips',
                      icon: Icons.favorite_border_rounded,
                      iconColor: OrbitColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color? iconColor;

  const _BreakdownRow({
    required this.title,
    required this.amount,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? OrbitColors.textSecondary),
            const SizedBox(width: 10),
            Text(title, style: OrbitTypography.bodyMedium),
          ],
        ),
        Text(
          amount,
          style: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
