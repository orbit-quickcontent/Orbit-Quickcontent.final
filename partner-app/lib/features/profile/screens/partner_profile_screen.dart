import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/partner_auth_provider.dart';

class PartnerProfileScreen extends ConsumerStatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  ConsumerState<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends ConsumerState<PartnerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await partnerApiClient.get('/partner/profile');
      if (mounted) {
        setState(() {
          _profile = res.data;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final user = _profile?['user'] ?? {};
    final name = _profile?['displayName'] ?? user['name'] ?? auth.name ?? 'utkarsh gupta';
    final email = user['email'] ?? auth.email ?? 'utkarshssg2608@gmail.com';
    final completedCount = _profile?['completedProjects']?.toString() ?? '0';
    final activeCount = _profile?['activeProjects']?.toString() ?? '0';
    final walletBalance = _profile?['walletBalance']?.toString() ?? '0';

    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top Header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: const Color(0xFF0B0C10),
              child: Row(
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
                              border: Border.all(color: const Color(0xFF4B5563)),
                              color: const Color(0xFF1F2937),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
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
                                border: Border.all(color: const Color(0xFF0B0C10), width: 1.5),
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
                                  color: const Color(0xFF8A2BE2).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFC785FF)),
                                ),
                                child: const Text(
                                  'PARTNER',
                                  style: TextStyle(
                                    color: Color(0xFFC785FF),
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
                            'Hi, $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2937),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Color(0xFFD1D5DB), size: 16),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _isOnline = !_isOnline),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF2ECC71)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  color: Color(0xFF2ECC71),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2937),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none, color: Color(0xFFD1D5DB), size: 16),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2937),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD1D5DB), size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Content ───────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: const Color(0xFF8A2BE2),
                backgroundColor: const Color(0xFF1A1C23),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // User Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D303A)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF374151), width: 2),
                                        color: const Color(0xFF111827),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Color(0xFFC785FF),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF2ECC71)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.verified_user_outlined, color: Color(0xFF2ECC71), size: 10),
                                                SizedBox(width: 2),
                                                Text('Verified', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 9, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        email,
                                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8A2BE2).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFC785FF)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.camera_alt_outlined, color: Color(0xFFC785FF), size: 10),
                                                SizedBox(width: 2),
                                                Text('Partner', style: TextStyle(color: Color(0xFFC785FF), fontSize: 9, fontWeight: FontWeight.w800)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF2ECC71)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                                                const SizedBox(width: 4),
                                                const Text('Online', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 9, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Wallet Balance
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E2235), Color(0xFF1A1C23)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF374151)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.wallet, color: Color(0xFF60A5FA), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WALLET BALANCE',
                                        style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹$walletBalance',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3-Column Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _statBox(
                              icon: Icons.camera_alt_outlined,
                              iconColor: const Color(0xFFC084FC),
                              count: completedCount,
                              label: 'SHOOTS',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statBox(
                              icon: Icons.schedule,
                              iconColor: const Color(0xFFFACC15),
                              count: activeCount,
                              label: 'ACTIVE',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statBox(
                              icon: Icons.star_border,
                              iconColor: const Color(0xFF60A5FA),
                              count: completedCount,
                              label: 'DONE',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Bank Account Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D303A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.account_balance, color: Color(0xFFC084FC), size: 16),
                                SizedBox(width: 6),
                                Text('BANK ACCOUNT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add, color: Color(0xFFC084FC), size: 16),
                                  SizedBox(width: 6),
                                  Text('+ Link Bank Account', style: TextStyle(color: Color(0xFFC084FC), fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Settings List
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C23),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D303A)),
                        ),
                        child: Column(
                          children: [
                            _settingsTile(
                              icon: Icons.shield_outlined,
                              title: 'Privacy Shield',
                              subtitle: 'Client data protection',
                            ),
                            const Divider(color: Color(0xFF2D303A), height: 1),
                            _settingsTile(
                              icon: Icons.settings_outlined,
                              title: 'App Settings',
                              subtitle: 'Notifications, sync preferences',
                            ),
                            const Divider(color: Color(0xFF2D303A), height: 1),
                            _settingsTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Guides, contact, report',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Logout Button
                      GestureDetector(
                        onTap: () async {
                          await ref.read(partnerAuthProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C23),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2D303A)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Color(0xFFF87171), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Log Out',
                                style: TextStyle(color: Color(0xFFF87171), fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Navigation Bar ──────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0B0C10),
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
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Earnings',
                    isActive: false,
                    hasDot: true,
                    onTap: () => context.go('/earnings'),
                  ),
                  _navItem(
                    icon: Icons.account_circle,
                    label: 'Profile',
                    isActive: true,
                    activeColor: const Color(0xFFC785FF),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D303A)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC084FC), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF4B5563), size: 16),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFFC785FF),
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
              Icon(icon, color: isActive ? activeColor : const Color(0xFF6B7280), size: 22),
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
