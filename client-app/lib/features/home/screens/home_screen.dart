import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';
import '../../../analytics/analytics_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/reel_showcase_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _recentBookings = [];
  Map<String, dynamic>? _activeBooking;
  bool _isLoading = true;
  String _currentLocation = 'Locating...';
  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('home_screen');
    _detectLiveLocation();
    _loadData();
  }

  Future<void> _detectLiveLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _currentLocation = 'Tap to select location');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _currentLocation = 'Tap to select location');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final subLoc = place.subLocality?.isNotEmpty == true ? place.subLocality : null;
        final loc = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
        final admin = place.administrativeArea?.isNotEmpty == true ? place.administrativeArea : place.country;

        final parts = [subLoc ?? loc, admin].where((e) => e != null && e.isNotEmpty).toList();
        setState(() {
          _currentLocation = parts.isNotEmpty ? parts.join(', ') : 'Live GPS Location';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _currentLocation = 'Tap to select location');
      }
    }
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

  void _onBookShootPressed({String? packageId}) {
    OrbitMotion.lightTap();
    analytics.trackButtonClick('book_shoot_cta', screen: 'home_screen');
    if (packageId != null) {
      context.push('/location-picker', extra: packageId);
    } else {
      context.push('/packages');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Utkarsh';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_loadData(), _detectLiveLocation()]);
          },
          color: OrbitColors.secondary,
          backgroundColor: OrbitColors.surfaceElevated,
          child: ListView(
            padding: const EdgeInsets.only(
              left: OrbitSpacing.space20,
              right: OrbitSpacing.space20,
              top: OrbitSpacing.space16,
              bottom: 110, // Space for bottom nav
            ),
            children: [
              // ── Header (Live User & Live GPS Address) ─────────────────
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
                            decoration: const BoxDecoration(
                              gradient: OrbitColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitials,
                                style: OrbitTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
                                style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () => context.push('/location-picker', extra: 'pkg_standard'),
                                child: Row(
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
                                    const SizedBox(width: 2),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: OrbitColors.textMuted),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Top Header Action: Notification Bell (Matching Screenshot) ──
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: OrbitColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: OrbitColors.borderSubtle, width: 1),
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications_none_rounded, color: OrbitColors.textPrimary, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── 1. Hero Booking Card ("Create your next reel.") ──────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: OrbitColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: OrbitColors.borderSubtle, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: HYPERLOCAL • PRO CREATORS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.5), width: 1),
                      ),
                      child: const Text(
                        'HYPERLOCAL • PRO CREATORS',
                        style: TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title: Create your next reel.
                    const Text(
                      'Create your next reel.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Professional creators arrive in 15 mins. Edited and\ndelivered same-day.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Gradient Booking CTA Button
                    GestureDetector(
                      onTap: () => _onBookShootPressed(),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF00D9FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: const Color(0xFF00D9FF).withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.movie_creation_outlined, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'BOOK NEW SHOOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Video Reels Showcase ──────────────────────────────
              OrbitReelShowcaseCarousel(
                onBookNow: () => _onBookShootPressed(),
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── 3. Shoot Packages Section (Matching Screenshot) ──────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shoot Packages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/packages'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF00D2FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Package 1: Personalized (₹1999)
              _PackageCard(
                title: 'Personalized',
                price: '₹1999',
                subtitle: 'Individual creators, personal events',
                features: const [
                  '1 cinematic reel (30–60 sec)',
                  'Professional color grading',
                  'Background score licensing',
                ],
                onBook: () => _onBookShootPressed(packageId: 'pkg_quick'),
              ),

              const SizedBox(height: 14),

              // Package 2: Professional (UGC) (₹4999)
              _PackageCard(
                title: 'Professional (UGC)',
                price: '₹4999',
                isPopular: true,
                subtitle: 'Brands, businesses & high-growth creators',
                features: const [
                  '3 high-impact reels (30–60 sec)',
                  'Custom motion graphics & hooks',
                  'Priority same-day delivery',
                ],
                onBook: () => _onBookShootPressed(packageId: 'pkg_standard'),
              ),

              const SizedBox(height: 14),

              // Package 3: Commercial & Ads (₹8999)
              _PackageCard(
                title: 'Commercial & Ads',
                price: '₹8999',
                subtitle: 'Multi-cam, product commercials & campaign ads',
                features: const [
                  '5 cinematic reels + 4K master files',
                  'Professional lighting & audio setup',
                  'Full commercial usage rights',
                ],
                onBook: () => _onBookShootPressed(packageId: 'pkg_ad_campaign'),
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
                              'Tap to track videographer & shoot status',
                              style: OrbitTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: OrbitColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: OrbitSpacing.space16),
              ],

              // ── Recent Activity / Zero State ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Shoots', style: OrbitTypography.headingMedium),
                  if (_recentBookings.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text('History', style: OrbitTypography.labelMedium.copyWith(color: OrbitColors.secondary)),
                    ),
                ],
              ),
              const SizedBox(height: OrbitSpacing.space8),

              if (_isLoading) ...[
                const OrbitLoadingCard(height: 80),
              ] else if (_recentBookings.isEmpty) ...[
                OrbitEmptyState(
                  icon: Icons.movie_outlined,
                  title: 'No past shoots yet',
                  description: 'Experience seamless on-demand video production with certified creators.',
                  ctaLabel: 'Book your first shoot',
                  onCtaPressed: () => _onBookShootPressed(),
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
                              decoration: const BoxDecoration(
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

/// Shoot Package Card Widget (Matching Screenshot)
class _PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onBook;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    this.isPopular = false,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OrbitColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPopular ? const Color(0xFF00D2FF).withValues(alpha: 0.4) : OrbitColors.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title (+ Popular Tag) & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D2FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          color: Color(0xFF00D2FF),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF00D2FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Features List (with cyan checkmark circles)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: features.map((f) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00D2FF), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    f,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Book This Package Button
          GestureDetector(
            onTap: () {
              OrbitMotion.lightTap();
              onBook();
            },
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C3242), width: 1),
              ),
              child: const Center(
                child: Text(
                  'Book This Package',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
