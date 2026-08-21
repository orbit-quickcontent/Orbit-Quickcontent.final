import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../auth/providers/partner_auth_provider.dart';

class PartnerProfileScreen extends ConsumerStatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  ConsumerState<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends ConsumerState<PartnerProfileScreen> {
  Map<String, dynamic>? _profile;

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
    final name = _profile?['displayName'] ?? user['name'] ?? auth.name ?? 'Creator Partner';
    final email = user['email'] ?? auth.email ?? 'partner@orbit.app';
    final phone = _profile?['phone'] ?? '+91 98765 43210';
    final rating = _profile?['rating']?.toString() ?? '4.9';
    final partnerId = _profile?['id']?.toString().substring(0, 8).toUpperCase() ?? 'PTR-8829';

    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'OP';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        backgroundColor: OrbitColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: Text(
          'CREATOR PROFILE',
          style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OrbitSpacing.space16),
          children: [
            // ── 1. Compact Profile Identity Header ─────────────────────────
            OrbitCard(
              padding: const EdgeInsets.all(OrbitSpacing.space20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: OrbitColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: OrbitColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: OrbitTypography.headingMedium.copyWith(
                          color: OrbitColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: OrbitColors.primary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $partnerId • ★ $rating',
                          style: OrbitTypography.bodySmall.copyWith(
                            color: OrbitColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: OrbitTypography.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrbitSpacing.space20),

            // ── 2. Settings & Account Grouped List ─────────────────────────
            Text(
              'ACCOUNT SETTINGS',
              style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: OrbitSpacing.space8),

            OrbitCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileSettingRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    subtitle: '$name • $phone',
                    onTap: () {},
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.account_balance_outlined,
                    title: 'Bank & UPI Details',
                    subtitle: 'HDFC Bank • Instant Payout Enabled',
                    onTap: () {},
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.assignment_outlined,
                    title: 'Documents & Verification',
                    subtitle: 'Aadhaar, PAN & Creator Portfolio (Verified)',
                    onTap: () {},
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Dispatch Sounds',
                    subtitle: 'High Priority Haptic Alerts Enabled',
                    onTap: () => context.push('/notifications'),
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Partner Support',
                    subtitle: '24/7 Creator Operations Desk',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrbitSpacing.space24),

            // ── 3. Danger Zone Log Out ─────────────────────────────────────
            OrbitDangerButton(
              label: 'LOG OUT OF ORBIT',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(partnerAuthProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: OrbitColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: OrbitColors.primary, size: 20),
      ),
      title: Text(title, style: OrbitTypography.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: OrbitTypography.bodySmall.copyWith(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: OrbitColors.textMuted, size: 20),
    );
  }
}
