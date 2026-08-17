import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/partner_auth_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  Map<String, dynamic>? _earningsData;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final res = await partnerApiClient.get('/partner/earnings');
      setState(() {
        _earningsData = res.data;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final partnerName = auth.name?.isNotEmpty == true ? auth.name! : 'utkarsh';
    final initials = partnerName.isNotEmpty
        ? partnerName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'U';

    final totalEarned = _earningsData?['totalEarned'] ?? 0;
    final monthEarned = _earningsData?['monthEarned'] ?? 0;
    final weekEarned = _earningsData?['weekEarned'] ?? 0;
    final doneCount = _earningsData?['completedCount'] ?? 0;
    final rating = _earningsData?['rating']?.toString() ?? '-';
    final avgPayout = doneCount > 0 ? (totalEarned / doneCount).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top App Bar ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: const Color(0xFF0E0E0E),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1C1B1B),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0E0E0E), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Good evening',
                                    style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A1A3A),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'PARTNER',
                                      style: TextStyle(
                                        color: Color(0xFFA855F7),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hi, $partnerName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C1B1B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search, color: Color(0xFFA3A3A3), size: 18),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isOnline = !_isOnline),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1B1B),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF27272A)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFFA3A3A3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C1B1B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, color: Color(0xFFA3A3A3), size: 18),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C1B1B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA3A3A3), size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: const [
                      Icon(Icons.wallet, color: Color(0xFF22C55E), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ready for your next gig',
                        style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Content Area ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadEarnings,
                color: const Color(0xFF22C55E),
                backgroundColor: const Color(0xFF1C1B1B),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Link Bank Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1B1B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF27272A).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFF131313),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance, color: Color(0xFFA3A3A3), size: 26),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Link Bank Account to Withdraw',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add your bank details to start withdrawing earnings',
                              style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.settings, color: Color(0xFF0EA5E9), size: 16),
                                    SizedBox(width: 6),
                                    Text('Go to Settings', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Earnings Summary Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1B1B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF27272A).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet, color: Color(0xFF22C55E), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Earnings', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                    Text('Income summary', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            const Text('TOTAL EARNED', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text('₹', style: TextStyle(color: Color(0xFF22C55E), fontSize: 24, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('$totalEarned', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Month & Week Stat Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1120),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.calendar_month, color: Color(0xFFA3A3A3), size: 14),
                                            SizedBox(width: 4),
                                            Text('MONTH', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            const Text('₹', style: TextStyle(color: Color(0xFFA855F7), fontSize: 14, fontWeight: FontWeight.w700)),
                                            const SizedBox(width: 2),
                                            Text('$monthEarned', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.schedule, color: Color(0xFFA3A3A3), size: 14),
                                            SizedBox(width: 4),
                                            Text('WEEK', style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            const Text('₹', style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 14, fontWeight: FontWeight.w700)),
                                            const SizedBox(width: 2),
                                            Text('$weekEarned', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2x2 Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _statTile(
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF22C55E),
                            label: 'DONE',
                            value: '$doneCount',
                            valueColor: const Color(0xFF22C55E),
                          ),
                          _statTile(
                            icon: Icons.star_border,
                            iconColor: const Color(0xFFEAB308),
                            label: 'RATING',
                            value: rating,
                            valueColor: const Color(0xFFEAB308),
                          ),
                          _statTile(
                            icon: Icons.schedule,
                            iconColor: const Color(0xFF0EA5E9),
                            label: 'WEEK',
                            value: '₹$weekEarned',
                            valueColor: const Color(0xFF0EA5E9),
                          ),
                          _statTile(
                            icon: Icons.bar_chart,
                            iconColor: const Color(0xFFD946EF),
                            label: 'AVG',
                            value: '₹$avgPayout',
                            valueColor: const Color(0xFFD946EF),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Breakdown Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1B1B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF27272A).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BREAKDOWN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                            const SizedBox(height: 16),
                            _breakdownRow('Lifetime', '₹$totalEarned', const Color(0xFF22C55E)),
                            const SizedBox(height: 14),
                            _breakdownRow('This Month', '₹$monthEarned', const Color(0xFFA855F7)),
                            const SizedBox(height: 14),
                            _breakdownRow('This Week', '₹$weekEarned', const Color(0xFF0EA5E9)),
                            const SizedBox(height: 14),
                            _breakdownRow('Avg/Project', '₹$avgPayout', const Color(0xFFEAB308)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation Bar ──────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF131313),
                border: Border(top: BorderSide(color: Color(0xFF27272A))),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.grid_view,
                    label: 'Home',
                    isActive: false,
                    onTap: () => context.go('/available-work'),
                  ),
                  _navItem(
                    icon: Icons.work_outline,
                    label: 'Work',
                    isActive: false,
                    onTap: () => context.go('/work-history'),
                  ),
                  _navItem(
                    icon: Icons.account_balance_wallet,
                    label: 'Earnings',
                    isActive: true,
                    activeColor: const Color(0xFF22C55E),
                    hasDot: true,
                    onTap: () {},
                  ),
                  _navItem(
                    icon: Icons.account_circle_outlined,
                    label: 'Profile',
                    isActive: false,
                    onTap: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          Text(value, style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFF22C55E),
    bool hasDot = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon, color: isActive ? activeColor : const Color(0xFFA3A3A3), size: 22),
              if (hasDot)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : const Color(0xFFA3A3A3),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
