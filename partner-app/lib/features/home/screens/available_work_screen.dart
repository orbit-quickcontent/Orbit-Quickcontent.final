import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/partner_auth_provider.dart';

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen> {
  List<Map<String, dynamic>> _availableJobs = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableJobs();
  }

  Future<void> _loadAvailableJobs() async {
    try {
      final res = await partnerApiClient.get('/partner/available-jobs');
      setState(() {
        _availableJobs = List<Map<String, dynamic>>.from(res.data['jobs'] ?? []);
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
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Sticky Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0B0C10),
                border: Border(bottom: BorderSide(color: Color(0xFF1F2937), width: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Profile
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF374151), width: 1.5),
                                  color: const Color(0xFF1A1A1A),
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
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF050505), width: 1.5),
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
                                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF581C87).withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF581C87)),
                                    ),
                                    child: const Text(
                                      'PARTNER',
                                      style: TextStyle(
                                        color: Color(0xFFC084FC),
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

                      // Action Buttons
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111827),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _isOnline = !_isOnline),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFF065F46)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        if (_isOnline)
                                          BoxShadow(
                                            color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: _isOnline ? const Color(0xFF4ADE80) : const Color(0xFF9CA3AF),
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
                              color: Color(0xFF111827),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, color: Color(0xFF9CA3AF), size: 18),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF111827),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Sub Status Banner
                  Row(
                    children: const [
                      Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ready for your next gig',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Content Area ──────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAvailableJobs,
                color: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFF1A1A1A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.6)),
                            ),
                            child: const Icon(Icons.work_outline, color: Color(0xFF60A5FA), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Available Work',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'New bookings waiting for you',
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Jobs List or Empty State
                      if (_availableJobs.isEmpty && !_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF141414), Color(0xFF0A0A0A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1F2937)),
                                ),
                                child: const Icon(Icons.work_outline, color: Color(0xFF4B5563), size: 30),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Available Work',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'New bookings will appear here when clients book sessions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Keep the app open to receive real-time notifications.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._availableJobs.map((job) {
                          final pkgName = job['package']?['name'] ?? 'Personalized Session';
                          final payout = job['partnerSalary'] ?? 700;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF1F2937)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(pkgName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                    Text('₹$payout', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w800, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(job['address'] ?? 'Client Location', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.push('/work/${job['id']}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    minimumSize: const Size(double.infinity, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Accept Gig', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
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
                color: Color(0xFF0E0E0E),
                border: Border(top: BorderSide(color: Color(0xFF1F2937))),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home (Active)
                  _navItem(
                    icon: Icons.grid_view,
                    label: 'Home',
                    isActive: true,
                    activeColor: const Color(0xFF3B82F6),
                    onTap: () {},
                  ),

                  // Work
                  _navItem(
                    icon: Icons.work_outline,
                    label: 'Work',
                    isActive: false,
                    onTap: () => context.go('/work-history'),
                  ),

                  // Earnings
                  _navItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Earnings',
                    isActive: false,
                    hasDot: true,
                    onTap: () => context.go('/earnings'),
                  ),

                  // Profile
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

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFF3B82F6),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isActive ? activeColor : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              if (hasDot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
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
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
