import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/orbit_theme.dart';
import '../analytics/analytics_service.dart';

class PartnerShell extends StatelessWidget {
  final Widget child;
  const PartnerShell({super.key, required this.child});

  int _indexFor(String loc) {
    if (loc.startsWith('/work-history') || loc.startsWith('/jobs') || loc.startsWith('/history')) return 1;
    if (loc.startsWith('/earnings')) return 2;
    if (loc.startsWith('/profile')) return 3;
    if (loc.startsWith('/work') || loc.startsWith('/available-work') || loc.startsWith('/home')) return 0;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    OrbitMotion.lightTap();
    switch (index) {
      case 0:
        partnerAnalytics.trackButtonClick('nav_home');
        context.go('/work');
        break;
      case 1:
        partnerAnalytics.trackButtonClick('nav_jobs');
        context.go('/work-history');
        break;
      case 2:
        partnerAnalytics.trackButtonClick('nav_earnings');
        context.go('/earnings');
        break;
      case 3:
        partnerAnalytics.trackButtonClick('nav_profile');
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(loc);

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: OrbitColors.surface,
          border: Border(top: BorderSide(color: OrbitColors.borderSubtle, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space16, vertical: OrbitSpacing.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Tab(icon: Icons.radar_outlined, activeIcon: Icons.radar_rounded, label: 'Home', index: 0, current: currentIndex, onTap: (i) => _onTap(context, i)),
                _Tab(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Jobs', index: 1, current: currentIndex, onTap: (i) => _onTap(context, i)),
                _Tab(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Earnings', index: 2, current: currentIndex, onTap: (i) => _onTap(context, i)),
                _Tab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 3, current: currentIndex, onTap: (i) => _onTap(context, i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;

  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        height: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? OrbitColors.primary : OrbitColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: OrbitTypography.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? OrbitColors.textPrimary : OrbitColors.textMuted,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
