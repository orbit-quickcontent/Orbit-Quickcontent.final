import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _recentBookings = [];
  Map<String, dynamic>? _activeBooking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await apiClient.get('/bookings', params: {'limit': '5'});
      final bookings = List<Map<String, dynamic>>.from(res.data['bookings'] ?? []);
      setState(() {
        _recentBookings = bookings;
        _activeBooking = bookings.firstWhere(
          (b) => b['status'] != 'COMPLETED' && b['status'] != 'CANCELLED',
          orElse: () => bookings.isNotEmpty ? bookings.first : {},
        );
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Test User';
    final userInitials = userName.isNotEmpty ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase() : 'TU';

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF00D2FF),
          backgroundColor: const Color(0xFF201F1F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top App Bar ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Stack(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00D2FF), width: 1.5),
                                  color: const Color(0xFF201F1F),
                                ),
                                child: Center(
                                  child: Text(
                                    userInitials,
                                    style: const TextStyle(
                                      color: Color(0xFFA5E7FF),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF131313), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
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
                          child: Stack(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF201F1F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none, color: Color(0xFFE5E2E1), size: 18),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00D2FF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
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
                          child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE5E2E1), size: 18),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Hero Header ───────────────────────────────────────────────
                const Text(
                  'Shoot',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE5E2E1),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFA5E7FF), Color(0xFF00D2FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'In Progress.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ORBIT V1.0.4 — PREMIUM ACCESS',
                  style: TextStyle(
                    color: Color(0xFFBBC9CF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),

                // ── 2x2 Bento Action Grid ────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    // Book New Shoot
                    GestureDetector(
                      onTap: () => context.push('/packages'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF001F28), size: 24),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'BOOK\nNEW SHOOT',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'INSTANT MATCHING',
                                  style: TextStyle(color: Color(0xFF00D2FF), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Track Order
                    GestureDetector(
                      onTap: () {
                        if (_activeBooking?['id'] != null) {
                          context.push('/tracking/${_activeBooking!['id']}');
                        } else {
                          context.push('/history');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6E208C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fingerprint, color: Color(0xFFEDB1FF), size: 24),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'TRACK\nORDER',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '1 ACTIVE',
                                  style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recent Projects
                    GestureDetector(
                      onTap: () => context.push('/history'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF353534),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description_outlined, color: Color(0xFFBBC9CF), size: 22),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'RECENT\nPROJECTS',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '12 DELIVERED',
                                  style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Brand Identity
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF353534),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_outline, color: Color(0xFFBBC9CF), size: 22),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'BRAND\nIDENTITY',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'ASSETS & DNA',
                                style: TextStyle(color: Color(0xFFBBC9CF), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Live Shoot Tracking Widget ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF6E208C), Color(0xFF00D2FF)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E0E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00D2FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'LIVE SHOOT TRACKING',
                                    style: TextStyle(
                                      color: Color(0xFF00D2FF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Personalized in progress',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: const [
                                  Icon(Icons.location_on_outlined, color: Color(0xFF859399), size: 13),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Kartar Mansion, 35, Dr Dadasah...',
                                      style: TextStyle(color: Color(0xFF859399), fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (_activeBooking?['id'] != null) {
                              context.push('/tracking/${_activeBooking!['id']}');
                            } else {
                              context.push('/history');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2FF),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Text('Track', style: TextStyle(color: Color(0xFF001F28), fontWeight: FontWeight.w800, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Color(0xFF001F28), size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Featured Packages Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bolt, color: Color(0xFF00D2FF), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Featured Packages',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/packages'),
                      child: Row(
                        children: const [
                          Text('View All', style: TextStyle(color: Color(0xFF00D2FF), fontSize: 12, fontWeight: FontWeight.w700)),
                          Icon(Icons.chevron_right, color: Color(0xFF00D2FF), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Horizontal Packages Scroll ────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Package 1: Personalized
                      Container(
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Personalized', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            const Text('60-120 mins delivery', style: TextStyle(color: Color(0xFF859399), fontSize: 11)),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: const [
                                Text('₹1,999', style: TextStyle(color: Color(0xFF00D2FF), fontSize: 26, fontWeight: FontWeight.w800)),
                                Text(' /session', style: TextStyle(color: Color(0xFF859399), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _featureItem('1 cinematic reel (30-60s)', const Color(0xFF00D2FF)),
                            const SizedBox(height: 8),
                            _featureItem('Professional color grading', const Color(0xFF00D2FF)),
                            const SizedBox(height: 8),
                            const Text('+3 more features', style: TextStyle(color: Color(0xFF859399), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push('/packages'),
                              child: Container(
                                width: double.infinity,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: const Center(
                                  child: Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Package 2: Professional
                      Container(
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEDB1FF).withValues(alpha: 0.3)),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF18181B),
                              const Color(0xFF6E208C).withValues(alpha: 0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Professional', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            const Text('60-120 mins delivery', style: TextStyle(color: Color(0xFF859399), fontSize: 11)),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: const [
                                Text('₹4,999', style: TextStyle(color: Color(0xFFEDB1FF), fontSize: 26, fontWeight: FontWeight.w800)),
                                Text(' /session', style: TextStyle(color: Color(0xFF859399), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _featureItem('3 cinematic reels', const Color(0xFFEDB1FF)),
                            const SizedBox(height: 8),
                            _featureItem('Brand DNA integration', const Color(0xFFEDB1FF)),
                            const SizedBox(height: 8),
                            const Text('+5 more features', style: TextStyle(color: Color(0xFF859399), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push('/packages'),
                              child: Container(
                                width: double.infinity,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00D2FF), Color(0xFF6E208C)],
                                  ),
                                ),
                                child: const Center(
                                  child: Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 3-Column Metrics Stats Card ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: const [
                            Text('60 min', style: TextStyle(color: Color(0xFF00D2FF), fontSize: 22, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('DELIVERY', style: TextStyle(color: Color(0xFF859399), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                      Expanded(
                        child: Column(
                          children: const [
                            Text('4K', style: TextStyle(color: Color(0xFFEDB1FF), fontSize: 22, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('QUALITY', style: TextStyle(color: Color(0xFF859399), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.1)),
                      Expanded(
                        child: Column(
                          children: const [
                            Text('500+', style: TextStyle(color: Color(0xFFCAB6FF), fontSize: 22, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('PROJECTS', style: TextStyle(color: Color(0xFF859399), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── CTA Banner ────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6E208C), Color(0xFF00D2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ready to Create Something Cinematic?',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Professional speed-graded custom reels delivered back inside 60 minutes.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/packages'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.bolt, color: Colors.black, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Book a Session',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Booking History ───────────────────────────────────────────
                Row(
                  children: const [
                    Icon(Icons.history, color: Color(0xFF859399), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Booking History',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_recentBookings.isEmpty && !_isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No past bookings yet', style: TextStyle(color: Color(0xFF859399), fontSize: 13)),
                    ),
                  )
                else
                  ..._recentBookings.map((b) {
                    final status = (b['status'] as String? ?? 'COMPLETED').replaceAll('_', ' ');
                    final date = b['createdAt'] != null ? b['createdAt'].toString().substring(0, 10) : 'Jul 1, 2026';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      b['package']?['name'] ?? 'Personalized',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('•', style: TextStyle(color: Color(0xFF859399))),
                                    const SizedBox(width: 6),
                                    Text(date, style: const TextStyle(color: Color(0xFF859399), fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  b['address'] ?? 'Kartar Mansion, 35, Dr Dadasaheb B...',
                                  style: const TextStyle(color: Color(0xFF859399), fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  '• Partner Salary: ₹700 (Paid)',
                                  style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: color, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFFE5E2E1), fontSize: 11)),
        ),
      ],
    );
  }
}
