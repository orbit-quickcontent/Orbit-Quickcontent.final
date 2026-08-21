import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';
import '../../../analytics/analytics_service.dart';
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
  String _currentLocation = 'Connaught Place, New Delhi';

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('home_screen');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await apiClient.get('/bookings', params: {'limit': '5'});
      final bookings = List<Map<String, dynamic>>.from(res.data['bookings'] ?? []);

      if (mounted) {
        setState(() {
          _recentBookings = bookings;
          _activeBooking = bookings.cast<Map<String, dynamic>?>().firstWhere(
                (b) => b != null && !['COMPLETED', 'CANCELLED', 'DELIVERED'].contains(b['status']),
                orElse: () => null,
              );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBookShootPressed() {
    analytics.trackButtonClick('hero_book_shoot_cta', screen: 'home_screen');
    context.push('/packages');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Creator';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'OR';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: OrbitColors.secondary,
          backgroundColor: OrbitColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.only(
              left: OrbitSpacing.space20,
              right: OrbitSpacing.space20,
              top: OrbitSpacing.space16,
              bottom: 100, // Space for bottom nav
            ),
            children: [
              // ── Header (User & Location) ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: OrbitColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitials,
                                style: OrbitTypography.titleSmall.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: OrbitSpacing.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, $userName',
                                style: OrbitTypography.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: OrbitColors.secondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _currentLocation,
                                      style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: OrbitColors.textPrimary, size: 24),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Active Booking Alert (If any) ─────────────────────────
              if (_activeBooking != null) ...[
                OrbitCard(
                  backgroundColor: OrbitColors.primary.withValues(alpha: 0.12),
                  border: Border.all(color: OrbitColors.primary.withValues(alpha: 0.4), width: 1),
                  onTap: () => context.push('/booking/${_activeBooking!['id']}'),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: OrbitColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_rounded, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: OrbitSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Shoot in Progress', style: OrbitTypography.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view real-time status & creator tracking',
                              style: OrbitTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: OrbitColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.space20),
              ],

              // ── Hero Section (Book New Shoot CTA) ──────────────────────
              Container(
                padding: const EdgeInsets.all(OrbitSpacing.space24),
                decoration: BoxDecoration(
                  gradient: OrbitColors.heroGradient,
                  borderRadius: OrbitRadius.rounded24,
                  border: Border.all(color: OrbitColors.borderMedium, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: OrbitColors.secondary.withValues(alpha: 0.15),
                            borderRadius: OrbitRadius.roundedFull,
                            border: Border.all(color: OrbitColors.secondary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'HYPERLOCAL • PRO CREATORS',
                            style: OrbitTypography.labelSmall.copyWith(
                              color: OrbitColors.secondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrbitSpacing.space16),
                    Text(
                      'Create your next reel.',
                      style: OrbitTypography.displayLarge.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: OrbitSpacing.space8),
                    Text(
                      'Professional video creators arrive in 15 minutes. Edited and delivered same-day.',
                      style: OrbitTypography.bodyMedium.copyWith(color: OrbitColors.textSecondary),
                    ),
                    const SizedBox(height: OrbitSpacing.space24),

                    // Dominant Primary CTA — Book New Shoot
                    OrbitPrimaryButton(
                      label: 'BOOK NEW SHOOT',
                      icon: Icons.movie_creation_outlined,
                      onPressed: _onBookShootPressed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space32),

              // ── Services Section ──────────────────────────────────────
              Text('Services', style: OrbitTypography.headingMedium),
              const SizedBox(height: OrbitSpacing.space12),

              Row(
                children: [
                  Expanded(child: _ServiceCard(title: 'Reels', subtitle: 'Short-form', icon: Icons.phone_android_rounded, onTap: _onBookShootPressed)),
                  const SizedBox(width: OrbitSpacing.space12),
                  Expanded(child: _ServiceCard(title: 'Events', subtitle: 'Live Coverage', icon: Icons.celebration_rounded, onTap: _onBookShootPressed)),
                ],
              ),
              const SizedBox(height: OrbitSpacing.space12),
              Row(
                children: [
                  Expanded(child: _ServiceCard(title: 'Product', subtitle: 'Showcase', icon: Icons.shopping_bag_rounded, onTap: _onBookShootPressed)),
                  const SizedBox(width: OrbitSpacing.space12),
                  Expanded(child: _ServiceCard(title: 'Lifestyle', subtitle: 'Vlogs & Fitness', icon: Icons.wb_sunny_rounded, onTap: _onBookShootPressed)),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space32),

              // ── Recent Bookings / Zero State ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity', style: OrbitTypography.headingMedium),
                  if (_recentBookings.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text('View All', style: OrbitTypography.labelMedium.copyWith(color: OrbitColors.secondary)),
                    ),
                ],
              ),
              const SizedBox(height: OrbitSpacing.space12),

              if (_isLoading) ...[
                const OrbitLoadingCard(height: 90),
                const OrbitLoadingCard(height: 90),
              ] else if (_recentBookings.isEmpty) ...[
                OrbitEmptyState(
                  icon: Icons.movie_outlined,
                  title: 'Ready when you are',
                  description: 'You haven\'t booked any reels yet. Experience seamless on-demand video production.',
                  ctaLabel: 'Book your first shoot',
                  onCtaPressed: _onBookShootPressed,
                ),
              ] else ...[
                ..._recentBookings.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: OrbitSpacing.space12),
                      child: OrbitCard(
                        onTap: () => context.push('/booking/${b['id']}'),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: OrbitColors.surfaceHighlight,
                                borderRadius: OrbitRadius.rounded12,
                              ),
                              child: const Icon(Icons.videocam_outlined, color: OrbitColors.secondary, size: 22),
                            ),
                            const SizedBox(width: OrbitSpacing.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['package']?['name'] ?? 'Video Shoot',
                                    style: OrbitTypography.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b['address'] ?? 'Confirmed Location',
                                    style: OrbitTypography.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            OrbitStatusPill.fromStatus(b['status'] ?? 'PENDING'),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OrbitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(OrbitSpacing.space8),
            decoration: BoxDecoration(
              color: OrbitColors.surfaceHighlight,
              borderRadius: OrbitRadius.rounded12,
            ),
            child: Icon(icon, size: 22, color: OrbitColors.secondary),
          ),
          const SizedBox(height: OrbitSpacing.space12),
          Text(title, style: OrbitTypography.titleSmall),
          const SizedBox(height: 2),
          Text(subtitle, style: OrbitTypography.bodySmall.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
