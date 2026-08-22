import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/orbit_theme.dart';
import '../analytics/analytics_service.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/packages')) return 1;
    if (location.startsWith('/history') || location.startsWith('/activity') || location.startsWith('/notifications') || location.startsWith('/booking')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    OrbitMotion.lightTap();
    switch (index) {
      case 0:
        analytics.trackButtonClick('nav_home');
        context.go('/home');
        break;
      case 1:
        analytics.trackButtonClick('nav_packages');
        context.go('/packages');
        break;
      case 2:
        analytics.trackButtonClick('nav_activity');
        context.go('/history');
        break;
      case 3:
        analytics.trackButtonClick('nav_profile');
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: _OrbitBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onItemTapped(context, i),
      ),
    );
  }
}

class _OrbitBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _OrbitBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.movie_outlined, activeIcon: Icons.movie_rounded, label: 'Packages', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.bolt_outlined, activeIcon: Icons.bolt_rounded, label: 'Activity', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 3, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
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
