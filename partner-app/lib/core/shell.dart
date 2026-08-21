import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/orbit_theme.dart';
import '../analytics/analytics_service.dart';

class PartnerShell extends StatelessWidget {
  final Widget child;
  const PartnerShell({super.key, required this.child});

  int _indexFor(String loc) {
    if (loc.startsWith('/work') || loc.startsWith('/home')) return 0;
    if (loc.startsWith('/jobs') || loc.startsWith('/history')) return 1;
    if (loc.startsWith('/earnings')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    OrbitMotion.lightTap();
    switch (index) {
      case 0:
        partnerAnalytics.trackButtonClick('nav_work');
        context.go('/work');
        break;
      case 1:
        partnerAnalytics.trackButtonClick('nav_jobs');
        context.go('/work');
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
        decoration: BoxDecoration(
          color: OrbitColors.surface.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: OrbitColors.borderMedium, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space12, vertical: OrbitSpacing.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Tab(icon: Icons.radar_outlined, activeIcon: Icons.radar_rounded, label: 'Work', index: 0, current: currentIndex, onTap: (i) => _onTap(context, i)),
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
        height: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: OrbitMotion.micro,
              curve: OrbitMotion.standard,
              height: 3,
              width: isActive ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: isActive ? OrbitColors.primaryGradient : null,
                borderRadius: OrbitRadius.roundedFull,
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? OrbitColors.secondary : OrbitColors.textMuted,
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
