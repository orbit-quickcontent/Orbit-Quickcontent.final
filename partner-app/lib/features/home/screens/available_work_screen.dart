import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_map_workspace.dart';
import '../../../analytics/analytics_service.dart';

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _activeJob;
  bool _isOnline = false;
  int _todayEarnings = 2450;
  int _completedToday = 3;
  final int _targetToday = 5;
  final int _bonusAmount = 300;

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_home_map');
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

      final active = jobsRes.data['activeJob'] as Map<String, dynamic>?;
      final earningsData = earningsRes.data ?? {};

      if (mounted) {
        setState(() {
          _activeJob = active;
          final earned = earningsData['todayEarnings'];
          if (earned != null && earned is int && earned > 0) {
            _todayEarnings = earned;
          }
          final completed = earningsData['completedToday'];
          if (completed != null && completed is int && completed > 0) {
            _completedToday = completed;
          }
        });
      }
    } catch (_) {}
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

  void _showSafetyModal() {
    OrbitMotion.lightTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
                SizedBox(width: 10),
                Text('Safety & Creator Toolkit', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.emergency_outlined, color: Colors.redAccent),
              title: Text('Emergency SOS Assistance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Instantly alert ORBIT dispatch safety team', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.support_agent_outlined, color: Color(0xFF38BDF8)),
              title: Text('24/7 Creator Partner Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('Get instant help with client on-set or gear', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNearbyClientsModal() {
    OrbitMotion.lightTap();
    final nearbyClients = [
      {
        'name': 'The Loft Cafe',
        'category': 'Cafe & Dining',
        'address': 'Baner High Street (0.4 km)',
        'pkg': 'Personalized Reel',
        'payout': '₹1,999',
        'urgency': 'Immediate (15 min)',
        'icon': Icons.local_cafe_outlined,
      },
      {
        'name': 'Aura Luxury Salon & Spa',
        'category': 'Beauty & Lifestyle',
        'address': 'Koregaon Park (0.7 km)',
        'pkg': 'Product & Styling Video',
        'payout': '₹4,999',
        'urgency': 'Scheduled: 2:00 PM',
        'icon': Icons.spa_outlined,
      },
      {
        'name': 'CrossFit Iron Arena',
        'category': 'Fitness & Sports',
        'address': 'Aundh Main Road (1.1 km)',
        'pkg': 'Quick Impact Reel',
        'payout': '₹999',
        'urgency': 'Immediate (30 min)',
        'icon': Icons.fitness_center_outlined,
      },
      {
        'name': 'Urban Craft Brewery',
        'category': 'Nightlife & Events',
        'address': 'Viman Nagar (1.5 km)',
        'pkg': 'Event Highlights Reel',
        'payout': '₹2,999',
        'urgency': 'Today 6:00 PM',
        'icon': Icons.nightlife_outlined,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_rounded, color: Color(0xFF38BDF8), size: 22),
                    SizedBox(width: 8),
                    Text('Nearby Clients & Shoots', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('4 Active Leads', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Clients near your current location seeking on-demand videography.', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 16),

            ...nearbyClients.map((cl) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2027),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF252B33)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF15181D), borderRadius: BorderRadius.circular(10)),
                            child: Icon(cl['icon'] as IconData, color: const Color(0xFF38BDF8), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cl['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(cl['category'] as String, style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      Text(cl['payout'] as String, style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Text(cl['address'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF15181D), borderRadius: BorderRadius.circular(4)),
                        child: Text(cl['urgency'] as String, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15181D),
                        side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showIncomingJobPreview();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Request Dispatch / View Job', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showIncomingJobPreview() {
    context.push('/incoming', extra: {
      'id': 'booking_demo_882',
      'earning': 500,
      'distanceKm': 1.8,
      'shootDurationMin': 25,
      'locationName': 'The Loft Cafe',
      'address': 'Baner High Street, Pune',
      'reelsCount': 1,
      'shootType': '1 Reel (30s vertical) • Color Grade',
      'clientName': 'Arjun & Maya',
      'pricingBreakdown': {
        'shoot': 400,
        'distance': 50,
        'surge': 50,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: Stack(
        children: [
          // ── 1. Fullscreen Dark Map Workspace ──────────────────────────────
          OrbitMapWorkspace(
            isOnline: _isOnline,
            onMenuPressed: () => context.push('/profile'),
            onSafetyPressed: _showSafetyModal,
            onNearbyClientsPressed: _showNearbyClientsModal,
            onRecenterPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GPS Centered at your live coordinates'), duration: Duration(seconds: 1)),
              );
            },
          ),

          // ── 2. Top Floating Operational Header ───────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Menu / Profile Button with Badge
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181D),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.menu_rounded, color: Colors.white, size: 22)),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('5', style: TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center: Floating Today's Earnings Pill ($100.77 / ₹2,450)
                  GestureDetector(
                    onTap: () => context.push('/earnings'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_todayEarnings',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Search / Filter Icon
                  GestureDetector(
                    onTap: _showIncomingJobPreview,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181D),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                        ],
                      ),
                      child: const Center(child: Icon(Icons.search_rounded, color: Colors.white, size: 22)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Central GO / ONLINE Pulse Action Button ───────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 230,
            child: Center(
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isOnline ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isOnline ? 'ON' : 'GO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Bottom Operational Sheet & Incentive Challenges ────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF15181D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF252B33), width: 1.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Strip & Tune Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                      Row(
                        children: [
                          if (_isOnline) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'This area is busy • High demand',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ] else ...[
                            const Text(
                              "You're offline",
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      const Icon(Icons.format_list_bulleted_rounded, color: Colors.white70, size: 20),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Active Shoot Card (If any) or Incentive Card
                  if (_activeJob != null) ...[
                    GestureDetector(
                      onTap: () => context.push('/job/${_activeJob!['id']}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ACTIVE SHOOT IN PROGRESS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(_activeJob!['package']?['name'] ?? 'Reel Shoot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Resume ➔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Today's Incentive Challenge
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2027),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF252B33)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "TODAY'S CHALLENGE",
                                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                                  ),
                                ],
                              ),
                              Text(
                                '$_completedToday / $_targetToday shoots',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_completedToday / _targetToday).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFF252B33),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Earn ₹$_bonusAmount bonus on completing $_targetToday shoots',
                                style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11.5),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── 5. Streamlined Bottom Navigation Bar ───────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0D10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF252B33)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map', isSelected: true, onTap: () {}),
                        _NavItem(icon: Icons.movie_creation_outlined, activeIcon: Icons.movie_creation_rounded, label: 'Jobs', isSelected: false, onTap: () => context.push('/work-history')),
                        _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Earnings', isSelected: false, onTap: () => context.push('/earnings')),
                        _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', isSelected: false, onTap: () => context.push('/profile')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF15181D) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF38BDF8) : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
