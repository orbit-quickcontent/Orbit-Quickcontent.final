import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await apiClient.get('/auth/me');
      setState(() => _profile = res.data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final name = _profile?['name'] ?? auth.name ?? auth.email ?? 'User';
    final email = _profile?['email'] ?? auth.email ?? '';

    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Profile', style: OrbitClientTheme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: OrbitClientTheme.primaryGradient),
                  child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(height: 12),
                Text(name, style: OrbitClientTheme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(email, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline)),
                const SizedBox(height: 4),
                OrbitStatusChip(label: 'CLIENT', color: OrbitClientTheme.primaryFixed, backgroundColor: OrbitClientTheme.primaryFixed.withOpacity(0.1)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Menu items
          ...[
            _MenuItem(icon: Icons.history, label: 'Booking History', onTap: () => context.go('/history')),
            _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.go('/notifications')),
            _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
            _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            _MenuItem(icon: Icons.logout, label: 'Logout', onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            }, isDestructive: true),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? OrbitClientTheme.error : OrbitClientTheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OrbitGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Icon(icon, size: 20, color: isDestructive ? color : OrbitClientTheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(color: color))),
            Icon(Icons.chevron_right, size: 18, color: OrbitClientTheme.outline),
          ]),
        ),
      ),
    );
  }
}
