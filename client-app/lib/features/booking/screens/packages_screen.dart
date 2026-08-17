import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  void _bookPackage(Map<String, dynamic> pkg) {
    context.push('/location', extra: pkg['id'] ?? 'pkg_creator_personalized');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Test User';
    final userInitials = userName.isNotEmpty ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase() : 'TU';

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                            userInitials,
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
                            'Hi, $userName',
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

              const SizedBox(height: 24),

              // ── Hero Section ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.3)),
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.08),
                ),
                child: const Text(
                  'CHOOSE YOUR PACKAGE',
                  style: TextStyle(
                    color: Color(0xFF00D2FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'The Orbit ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Edge.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF00D2FF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select the package that fits your needs. Both include professional express editing delivered in 60-120 minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFBBC9CF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Package 1: Personalized ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalized',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Individual creators, personal events',
                      style: TextStyle(color: Color(0xFF859399), fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text('₹1,999', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Montserrat')),
                        Text(' /session', style: TextStyle(color: Color(0xFF859399), fontSize: 13)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF27272A)),
                    const SizedBox(height: 16),

                    _checkFeature('1 cinematic reel (30-60 sec)'),
                    _checkFeature('Professional color grading'),
                    _checkFeature('Background score licensing'),
                    _checkFeature('Same-day delivery (60-90 mins)'),
                    _checkFeature('1 revision round'),
                    _checkFeature('Ideal for active content creators'),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () => _bookPackage({'id': 'pkg_creator_personalized', 'name': 'Personalized'}),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF3C494E)),
                        ),
                        child: const Center(
                          child: Text(
                            'Book Now',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Package 2: Professional (UGC) - Most Popular ───────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1B1B),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDB1FF),
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20)),
                          ),
                          child: const Text(
                            'MOST POPULAR',
                            style: TextStyle(
                              color: Color(0xFF520070),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Professional (UGC)',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Brands, businesses, template creators',
                              style: TextStyle(color: Color(0xFF859399), fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: const [
                                Text('₹4,999', style: TextStyle(color: Color(0xFF00D2FF), fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Montserrat')),
                                Text(' /session', style: TextStyle(color: Color(0xFF859399), fontSize: 13)),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF27272A)),
                            const SizedBox(height: 16),

                            _checkFeature('3 cinematic reels (30-60 sec each)'),
                            _checkFeature('Brand DNA integration (logo, palette, font)'),
                            _checkFeature('Professional color grading & stabilization'),
                            _checkFeature('Licensed premium sound scores'),
                            _checkFeature('Same-day express delivery (90-120 mins)'),
                            _checkFeature('2 revision rounds with master editor'),
                            _checkFeature('Dedicated creator-editor sync'),

                            const SizedBox(height: 24),

                            GestureDetector(
                              onTap: () => _bookPackage({'id': 'pkg_creator_ugc_pro', 'name': 'Professional (UGC)'}),
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D2FF), Color(0xFF6E208C)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Book Now',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Trust Badges Section ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF3C494E).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_user_outlined, color: Color(0xFF00D2FF), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All videographers on the Orbit network match certified filming standards.',
                            style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, color: Color(0xFFEDB1FF), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'PCI compliance mock checkout secure links.',
                            style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check, color: Color(0xFF00D2FF), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFBBC9CF), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
