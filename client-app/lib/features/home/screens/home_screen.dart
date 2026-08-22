import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_button.dart';
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
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('home_screen');
    _detectLiveLocation();
    _loadData();
    _loadPackages();
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

  Future<void> _loadPackages() async {
    try {
      final res = await apiClient.get('/packages');
      final pkgs = List<Map<String, dynamic>>.from(res.data ?? []);
      if (mounted && pkgs.isNotEmpty) {
        setState(() => _packages = pkgs);
      } else {
        _setFallbackPackages();
      }
    } catch (_) {
      _setFallbackPackages();
    }
  }

  void _setFallbackPackages() {
    if (mounted) {
      setState(() {
        _packages = [
          {
            'id': 'pkg_quick',
            'name': 'Quick Reel',
            'tier': 'QUICK',
            'priceDisplay': 999,
            'focus': '1 High-Impact 9:16 Reel',
            'deliveryTime': '60 min delivery',
            'features': ['1 Edited Reel (30s)', 'Trending Audio Sync', 'Pro Color Grading', 'Same-Day Fast Delivery'],
            'popular': false,
          },
          {
            'id': 'pkg_standard',
            'name': 'Creator Standard',
            'tier': 'STANDARD',
            'priceDisplay': 1999,
            'focus': '3 Master Reels + B-Roll',
            'deliveryTime': '120 min delivery',
            'features': ['3 Short-form Reels', 'Motion Graphics & Captions', 'Cinematic B-Roll', '4K Master Export'],
            'popular': true,
          },
          {
            'id': 'pkg_premium',
            'name': 'Brand Premium',
            'tier': 'PREMIUM',
            'priceDisplay': 4999,
            'focus': '6 Master Reels + Brand Kit',
            'deliveryTime': 'Same Day delivery',
            'features': ['6 Master Reels', 'Sound Design & VO', 'Custom Brand Kit', 'Raw Footage Access'],
            'popular': false,
          },
        ];
      });
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
              bottom: 100, // Space for bottom nav
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
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: OrbitColors.textPrimary, size: 24),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space20),

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

              // ── Hero Section (Book New Shoot CTA) ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space20),
                decoration: BoxDecoration(
                  gradient: OrbitColors.heroGradient,
                  borderRadius: OrbitRadius.rounded24,
                  border: Border.all(color: OrbitColors.borderMedium, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                    const SizedBox(height: OrbitSpacing.space12),
                    Text(
                      'Create your next reel.',
                      style: OrbitTypography.displayLarge.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional creators arrive in 15 mins. Edited and delivered same-day.',
                      style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                    ),
                    const SizedBox(height: OrbitSpacing.space16),

                    // Dominant Primary CTA
                    OrbitPrimaryButton(
                      label: 'BOOK NEW SHOOT',
                      icon: Icons.movie_creation_outlined,
                      onPressed: () => _onBookShootPressed(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Clean Sample Video Reels Showcase ─────────────────────
              OrbitReelShowcaseCarousel(
                onBookNow: () => _onBookShootPressed(),
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Available Shoot Packages ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shoot Packages', style: OrbitTypography.headingMedium),
                  TextButton(
                    onPressed: () => context.push('/packages'),
                    child: Text('View All', style: OrbitTypography.labelMedium.copyWith(color: OrbitColors.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: OrbitSpacing.space8),

              // Package Cards List
              ..._packages.map((pkg) {
                final isPopular = pkg['popular'] == true;
                final pkgId = pkg['id']?.toString() ?? 'pkg_standard';
                final features = List<String>.from(pkg['features'] ?? []);

                return Padding(
                  padding: const EdgeInsets.only(bottom: OrbitSpacing.space12),
                  child: OrbitCard(
                    onTap: () => _onBookShootPressed(packageId: pkgId),
                    border: isPopular
                        ? Border.all(color: OrbitColors.secondary.withValues(alpha: 0.6), width: 1.5)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(pkg['name'] ?? 'Shoot Package', style: OrbitTypography.titleMedium),
                                if (isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: OrbitColors.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'POPULAR',
                                      style: TextStyle(color: OrbitColors.secondary, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '₹${pkg['priceDisplay'] ?? 999}',
                              style: OrbitTypography.titleLarge.copyWith(color: OrbitColors.secondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pkg['focus'] ?? 'Short-form reel shoot',
                          style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: features.take(3).map((f) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 12, color: OrbitColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(f, style: const TextStyle(color: OrbitColors.textMuted, fontSize: 11)),
                                ],
                              )).toList(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isPopular ? OrbitColors.secondary : OrbitColors.borderMedium),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _onBookShootPressed(packageId: pkgId),
                            child: Text(
                              'Book This Package',
                              style: TextStyle(
                                color: isPopular ? OrbitColors.secondary : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: OrbitSpacing.space20),

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
