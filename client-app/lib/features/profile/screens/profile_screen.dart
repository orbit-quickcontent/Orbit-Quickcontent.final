import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await apiClient.get('/auth/me');
      setState(() => _profile = res.data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final name = _profile?['name'] ?? auth.name ?? 'Test User';
    final email = _profile?['email'] ?? auth.email ?? 'test@example.com';
    final phone = _profile?['phone'] ?? '+91 9876543210';
    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'TU';

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // ── Top App Bar ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3C494E)),
                          color: const Color(0xFF2A2A2A),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFFA5E7FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'GOOD AFTERNOON',
                                style: TextStyle(
                                  color: Color(0xFFBBC9CF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6E208C),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'CREATOR',
                                  style: TextStyle(
                                    color: Color(0xFFE498FF),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hi, $name',
                            style: const TextStyle(
                              color: Color(0xFFA5E7FF),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF201F1F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search, color: Color(0xFFE5E2E1), size: 18),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF201F1F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: Color(0xFFE5E2E1), size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF201F1F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.expand_more, color: Color(0xFFE5E2E1), size: 18),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Profile Header Card ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF47D6FF), Color(0xFFEDB1FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF47D6FF).withValues(alpha: 0.3),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF001F28),
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF85),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF131313), width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.movie_outlined, color: Color(0xFF00D2FF), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'CREATOR',
                            style: TextStyle(
                              color: Color(0xFF00D2FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style_outlined, color: Color(0xFFBBC9CF), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Creator Persona',
                          style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00D2FF)),
                      ),
                      child: const Text(
                        'CLIENT MEMBERSHIP',
                        style: TextStyle(
                          color: Color(0xFF00D2FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── General Information Section ────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'General Information',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF353534),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3C494E)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFF27272A), height: 1),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _infoRow('Full Name', name, Colors.white),
                          const SizedBox(height: 16),
                          _infoRow('Email Address', email, Colors.white),
                          const SizedBox(height: 16),
                          _infoRow('Phone Number', phone, Colors.white),
                          const SizedBox(height: 16),
                          _infoRow('Creative Style Preset:', 'Creator', const Color(0xFF00D2FF)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Menu Settings Section ──────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    _menuOption(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                      iconColor: const Color(0xFF00D2FF),
                      title: 'Privacy & Security',
                      subtitle: 'Manage credentials & direct permissions',
                    ),
                    const Divider(color: Color(0xFF27272A), height: 1),
                    _menuOption(
                      icon: Icons.settings_outlined,
                      iconBg: const Color(0xFFEDB1FF).withValues(alpha: 0.15),
                      iconColor: const Color(0xFFEDB1FF),
                      title: 'App Settings',
                      subtitle: 'Toggle notifications & sound fx',
                    ),
                    const Divider(color: Color(0xFF27272A), height: 1),
                    _menuOption(
                      icon: Icons.help_outline,
                      iconBg: const Color(0xFFCAB6FF).withValues(alpha: 0.15),
                      iconColor: const Color(0xFFCAB6FF),
                      title: 'Help & Support',
                      subtitle: 'FAQs & support ticket logs',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Logout Action Button ───────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB4AB).withValues(alpha: 0.3)),
                    color: const Color(0xFFFFB4AB).withValues(alpha: 0.05),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFFFB4AB), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Log Out Profile',
                        style: TextStyle(color: Color(0xFFFFB4AB), fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBBC9CF), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _menuOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF859399), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF859399), size: 18),
        ],
      ),
    );
  }
}
