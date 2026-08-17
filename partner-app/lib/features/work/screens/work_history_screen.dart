import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/partner_auth_provider.dart';

class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  List<Map<String, dynamic>> _completedJobs = [];
  bool _isLoading = true;
  bool _isOnline = true;
  int _totalEarned = 0;
  int _monthEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await partnerApiClient.get('/partner/history');
      final jobs = List<Map<String, dynamic>>.from(res.data['jobs'] ?? []);
      int total = 0;
      for (var j in jobs) {
        total += (j['partnerSalary'] as num? ?? 0).toInt();
      }
      setState(() {
        _completedJobs = jobs;
        _totalEarned = total;
        _monthEarned = total;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final partnerName = auth.name?.isNotEmpty == true ? auth.name! : 'utkarsh';
    final initials = partnerName.isNotEmpty
        ? partnerName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF131313),
              ),
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF3D4A3D)),
                                  color: const Color(0xFF1C1B1B),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Color(0xFF4BE277),
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
                                    color: const Color(0xFF4BE277),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF131313), width: 1.5),
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
                                    'Good afternoon',
                                    style: TextStyle(color: Color(0xFFBCCBB9), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6F00BE).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: const Color(0xFF6F00BE).withValues(alpha: 0.5)),
                                    ),
                                    child: const Text(
                                      'PARTNER',
                                      style: TextStyle(
                                        color: Color(0xFFDDB7FF),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hi, $partnerName',
                                style: const TextStyle(
                                  color: Color(0xFFE5E2E1),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFF201F1F),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3D4A3D)),
                            ),
                            child: const Icon(Icons.search, color: Color(0xFFBCCBB9), size: 18),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isOnline = !_isOnline),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF201F1F),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF3D4A3D)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _isOnline ? const Color(0xFF4BE277) : const Color(0xFF6B7280),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: _isOnline ? const Color(0xFF4BE277) : const Color(0xFFBCCBB9),
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
                            decoration: BoxDecoration(
                              color: const Color(0xFF201F1F),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3D4A3D)),
                            ),
                            child: const Icon(Icons.notifications_none, color: Color(0xFFBCCBB9), size: 18),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF201F1F),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3D4A3D)),
                            ),
                            child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFBCCBB9), size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: const [
                      Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF4BE277), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ready for your next gig',
                        style: TextStyle(color: Color(0xFF4BE277), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Content ───────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHistory,
                color: const Color(0xFF4BE277),
                backgroundColor: const Color(0xFF1C1B1B),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      // Section Header
                      Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFF3D4A3D))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF3D4A3D)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.work, color: Color(0xFF4BE277), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Work History', style: TextStyle(color: Color(0xFFE5E2E1), fontSize: 18, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 2),
                                    Text('Completed jobs', style: TextStyle(color: Color(0xFFBCCBB9), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${_completedJobs.length} done',
                                style: const TextStyle(color: Color(0xFF4BE277), fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stats Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131313),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3D4A3D)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                        border: Border.all(color: const Color(0xFF4BE277).withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(Icons.check_circle, color: Color(0xFF4BE277), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${_completedJobs.length} Completed', style: const TextStyle(color: Color(0xFFE5E2E1), fontSize: 16, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        const Text('Lifetime work', style: TextStyle(color: Color(0xFFBCCBB9), fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹$_totalEarned', style: const TextStyle(color: Color(0xFF4BE277), fontSize: 20, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    const Text('TOTAL EARNED', style: TextStyle(color: Color(0xFFBCCBB9), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // This Month Sub-card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF3D4A3D).withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.bar_chart, color: Color(0xFFDDB7FF), size: 16),
                                      SizedBox(width: 6),
                                      Text('This Month', style: TextStyle(color: Color(0xFFE5E2E1), fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Text('₹$_monthEarned', style: const TextStyle(color: Color(0xFFDDB7FF), fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Empty State or List
                      if (_completedJobs.isEmpty && !_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131313),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF3D4A3D)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF6F00BE).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFFDDB7FF).withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6F00BE).withValues(alpha: 0.15),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.inbox_outlined, color: Color(0xFFDDB7FF), size: 28),
                              ),
                              const SizedBox(height: 16),
                              const Text('No Completed Work Yet', style: TextStyle(color: Color(0xFFE5E2E1), fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text('Completed bookings will appear here.', style: TextStyle(color: Color(0xFFBCCBB9), fontSize: 12)),
                            ],
                          ),
                        )
                      else
                        ..._completedJobs.map((job) {
                          final date = job['createdAt'] != null ? job['createdAt'].toString().substring(0, 10) : 'Recent';
                          final payout = job['partnerSalary'] ?? 700;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131313),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF3D4A3D)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(job['package']?['name'] ?? 'Completed Shoot', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 3),
                                    Text(date, style: const TextStyle(color: Color(0xFFBCCBB9), fontSize: 11)),
                                  ],
                                ),
                                Text('₹$payout', style: const TextStyle(color: Color(0xFF4BE277), fontWeight: FontWeight.w800, fontSize: 15)),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation Bar ──────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF131313),
                border: Border(top: BorderSide(color: Color(0xFF3D4A3D))),
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
                    icon: Icons.work,
                    label: 'Work',
                    isActive: true,
                    activeColor: const Color(0xFF4BE277),
                    onTap: () {},
                  ),
                  _navItem(
                    icon: Icons.account_balance_wallet,
                    label: 'Earnings',
                    isActive: false,
                    hasDot: true,
                    onTap: () => context.go('/earnings'),
                  ),
                  _navItem(
                    icon: Icons.account_circle,
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

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFF4BE277),
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
              Icon(icon, color: isActive ? activeColor : const Color(0xFF869585), size: 22),
              if (hasDot)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4BE277),
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
              color: isActive ? activeColor : const Color(0xFF869585),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
