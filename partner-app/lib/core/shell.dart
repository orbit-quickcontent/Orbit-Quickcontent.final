import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

class PartnerShell extends StatelessWidget {
  final Widget child;
  const PartnerShell({super.key, required this.child});

  int _indexFor(String loc) {
    if (loc.startsWith('/work')) return 0;
    if (loc.startsWith('/earnings')) return 1;
    if (loc.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: OrbitPartnerTheme.surface.withOpacity(0.95),
          border: const Border(top: BorderSide(color: OrbitPartnerTheme.outlineFaint)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Tab(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Work', index: 0, current: _indexFor(loc), onTap: (i) => context.go('/work')),
              _Tab(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Earnings', index: 1, current: _indexFor(loc), onTap: (i) => context.go('/earnings')),
              _Tab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 2, current: _indexFor(loc), onTap: (i) => context.go('/profile')),
            ],
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
  const _Tab({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? OrbitPartnerTheme.primary : OrbitPartnerTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? OrbitPartnerTheme.primary : OrbitPartnerTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
