import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _recentBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await apiClient.get('/bookings', params: {'limit': '3'});
      setState(() {
        _recentBookings = List<Map<String, dynamic>>.from(res.data['bookings'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: OrbitClientTheme.primaryFixed,
        backgroundColor: OrbitClientTheme.surfaceHigh,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              backgroundColor: OrbitClientTheme.background,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$greeting 👋',
                                style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                                  color: OrbitClientTheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                user.name?.isNotEmpty == true ? user.name! : user.email ?? 'Welcome',
                                style: OrbitClientTheme.textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        GestureDetector(
                          onTap: () => context.go('/notifications'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: OrbitClientTheme.surfaceHigh,
                              border: Border.all(color: OrbitClientTheme.outlineVariant),
                            ),
                            child: const Icon(Icons.notifications_outlined, size: 18, color: OrbitClientTheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profile avatar
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: OrbitClientTheme.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                (user.name?.isNotEmpty == true ? user.name![0] : user.email?[0] ?? 'U').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildListDelegate([
                // ── Hero CTA Card ─────────────────────────────────────────────
                _HeroCTACard().animate().fadeIn(delay: 100.ms).slideY(begin: 0.15),
                const SizedBox(height: 24),

                // ── Quick Stats ───────────────────────────────────────────────
                Text('YOUR ACTIVITY', style: OrbitClientTheme.textTheme.labelMedium)
                    .animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 12),
                _QuickStatsRow(totalBookings: _recentBookings.length)
                    .animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 28),

                // ── Recent Bookings ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT BOOKINGS', style: OrbitClientTheme.textTheme.labelMedium),
                    GestureDetector(
                      onTap: () => context.go('/history'),
                      child: Text(
                        'View all',
                        style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                          color: OrbitClientTheme.primaryFixed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 12),

                if (_isLoading)
                  ..._shimmerCards()
                else if (_recentBookings.isEmpty)
                  _EmptyBookingsState()
                else
                  ..._recentBookings.asMap().entries.map((entry) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BookingCard(booking: entry.value)
                          .animate(delay: (350 + entry.key * 80).ms).fadeIn().slideY(begin: 0.1),
                    ),
                  ),

                const SizedBox(height: 100), // Bottom nav padding
              ])),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _shimmerCards() => List.generate(2, (_) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: OrbitClientTheme.surfaceHigh,
        highlightColor: OrbitClientTheme.surfaceBright,
        child: Container(height: 80, decoration: BoxDecoration(color: OrbitClientTheme.surfaceHigh, borderRadius: BorderRadius.circular(16))),
      ),
    ),
  );
}

class _HeroCTACard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001A24), Color(0xFF0D0020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OrbitClientTheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: OrbitClientTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('NEW BOOKING', style: OrbitClientTheme.textTheme.labelSmall?.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Book a Professional',
            style: OrbitClientTheme.textTheme.headlineLarge,
          ),
          Text(
            'Videographer',
            style: OrbitClientTheme.textTheme.headlineLarge?.copyWith(
              foreground: Paint()
                ..shader = OrbitClientTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, 200, 40)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get a cinematic reel delivered in ~120 minutes',
            style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          OrbitGradientButton(
            label: 'Book Now',
            onPressed: () => context.push('/packages'),
            height: 46,
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int totalBookings;
  const _QuickStatsRow({required this.totalBookings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Bookings', value: '$totalBookings', icon: Icons.video_camera_back_outlined, gradient: OrbitClientTheme.primaryGradient)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Reels Created', value: '$totalBookings', icon: Icons.movie_filter_outlined, gradient: const LinearGradient(colors: [Color(0xFF9D50FF), Color(0xFFEDB1FF)]))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient gradient;
  const _StatCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => gradient.createShader(b),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(value, style: OrbitClientTheme.textTheme.displayLarge?.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED': return OrbitClientTheme.success;
      case 'SHOOTING': case 'EN_ROUTE': case 'PARTNER_ASSIGNED': return OrbitClientTheme.primaryFixed;
      case 'CANCELLED': case 'FAILED': return OrbitClientTheme.error;
      default: return OrbitClientTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] ?? '';
    final pkg = booking['package'] as Map<String, dynamic>? ?? {};
    return GestureDetector(
      onTap: () => context.push('/booking/${booking['id']}'),
      child: OrbitGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(status).withOpacity(0.1),
                border: Border.all(color: _statusColor(status).withOpacity(0.3)),
              ),
              child: Icon(Icons.videocam_outlined, size: 20, color: _statusColor(status)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pkg['name'] ?? 'Package', style: OrbitClientTheme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(booking['address'] ?? '', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            OrbitStatusChip(
              label: status.replaceAll('_', ' '),
              color: _statusColor(status),
              backgroundColor: _statusColor(status).withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b),
              child: const Icon(Icons.video_camera_back_outlined, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('No bookings yet', style: OrbitClientTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Book your first professional videographer', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OrbitGradientButton(label: 'Book Now', onPressed: () => context.push('/packages'), width: 160, height: 44),
          ],
        ),
      ),
    );
  }
}
