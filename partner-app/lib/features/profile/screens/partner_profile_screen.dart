import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../providers/partner_auth_provider.dart';

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
        setState(() => _profile = res.data);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final user = _profile?['user'] ?? {};
    final name = _profile?['displayName'] ?? user['name'] ?? auth.name ?? 'Partner';
    final email = user['email'] ?? auth.email ?? '';
    final rating = _profile?['rating']?.toString() ?? '5.0';
    final completed = _profile?['completedProjects']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      appBar: AppBar(
        title: const Text('Partner Profile'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: OrbitPartnerTheme.partnerGradient,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: OrbitPartnerTheme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(email, style: OrbitPartnerTheme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: OrbitPartnerTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: OrbitPartnerTheme.outlineFaint),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('$rating Rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: OrbitPartnerTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: OrbitPartnerTheme.outlineFaint),
                      ),
                      child: Text('$completed Shoots Done', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              color: OrbitPartnerTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OrbitPartnerTheme.outlineFaint),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined, color: Colors.white),
                  title: const Text('Bank Account & Payouts'),
                  trailing: const Icon(Icons.chevron_right, color: OrbitPartnerTheme.textSecondary),
                  onTap: () {},
                ),
                const Divider(color: OrbitPartnerTheme.outlineFaint, height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined, color: Colors.white),
                  title: const Text('Partner Support & Help'),
                  trailing: const Icon(Icons.chevron_right, color: OrbitPartnerTheme.textSecondary),
                  onTap: () {},
                ),
                const Divider(color: OrbitPartnerTheme.outlineFaint, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: OrbitPartnerTheme.error),
                  title: const Text('Logout', style: TextStyle(color: OrbitPartnerTheme.error)),
                  onTap: () async {
                    await ref.read(partnerAuthProvider.notifier).logout();
                    if (mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
