import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/history'); break;
      case 2: context.go('/notifications'); break;
      case 3: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
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
        color: OrbitClientTheme.surfaceContainerLowest.withOpacity(0.92),
        border: const Border(top: BorderSide(color: OrbitClientTheme.outlineVariant, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Bookings', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 3, currentIndex: currentIndex, onTap: onTap),
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
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 24 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                gradient: isActive ? OrbitClientTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? OrbitClientTheme.primaryFixed : OrbitClientTheme.outline,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? OrbitClientTheme.primaryFixed : OrbitClientTheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
