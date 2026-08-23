import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  static const _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _recentBookings = [];
  Map<String, dynamic>? _activeBooking;
  bool _isLoading = true;
  String _currentLocation = 'Locating...';
  String _brandName = 'My Brand';
  String _brandHandle = '@orbit_creator';
  String _selectedStyle = 'Cinematic & Dynamic';

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('home_screen');
    _detectLiveLocation();
    _loadBrandDNA();
    _loadData();
  }

  Future<void> _loadBrandDNA() async {
    try {
      final name = await _storage.read(key: 'brand_name');
      final handle = await _storage.read(key: 'brand_handle');
      final style = await _storage.read(key: 'brand_style');
      if (mounted) {
        setState(() {
          if (name != null && name.isNotEmpty) _brandName = name;
          if (handle != null && handle.isNotEmpty) _brandHandle = handle;
          if (style != null && style.isNotEmpty) _selectedStyle = style;
        });
      }
    } catch (_) {}
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

  void _onTrackOrderPressed() {
    OrbitMotion.lightTap();
    if (_activeBooking != null) {
      context.push('/booking/${_activeBooking!['id']}');
    } else {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: OrbitColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: OrbitColors.borderMedium, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OrbitColors.secondary.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: OrbitColors.secondary, size: 30),
                ),
                const SizedBox(height: 16),
                const Text('No Active Shoots in Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Book a verified creator to arrive in 15 minutes.', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OrbitColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/packages');
                    },
                    child: const Text('Book a Shoot Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _openBrandIdentityModal() {
    OrbitMotion.lightTap();
    final nameCtrl = TextEditingController(text: _brandName);
    final handleCtrl = TextEditingController(text: _brandHandle);
    String tempStyle = _selectedStyle;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: OrbitColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: OrbitColors.borderMedium, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.star_rounded, color: Colors.pinkAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brand Identity & DNA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('Editors & creators use this DNA for your reels', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('BRAND / CREATOR NAME', style: TextStyle(color: OrbitColors.secondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Orbit Studios',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: OrbitColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.secondary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('INSTAGRAM / TIKTOK HANDLE', style: TextStyle(color: OrbitColors.secondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: handleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. @orbit_app',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: OrbitColors.surfaceElevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.secondary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('PREFERRED EDITING STYLE DNA', style: TextStyle(color: OrbitColors.secondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Cinematic & Dynamic', 'Fast-Paced Streetwear', 'Minimalist Aesthetic', 'Luxury & Real Estate'].map((style) {
                      final isSel = tempStyle == style;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempStyle = style),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? OrbitColors.secondary.withValues(alpha: 0.2) : OrbitColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? OrbitColors.secondary : OrbitColors.borderSubtle, width: isSel ? 1.5 : 1.0),
                          ),
                          child: Text(
                            style,
                            style: TextStyle(
                              color: isSel ? OrbitColors.secondary : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OrbitColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final bName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'My Brand';
                        final bHandle = handleCtrl.text.trim().isNotEmpty ? handleCtrl.text.trim() : '@orbit_creator';
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        await _storage.write(key: 'brand_name', value: bName);
                        await _storage.write(key: 'brand_handle', value: bHandle);
                        await _storage.write(key: 'brand_style', value: tempStyle);

                        if (mounted) {
                          setState(() {
                            _brandName = bName;
                            _brandHandle = bHandle;
                            _selectedStyle = tempStyle;
                          });
                        }
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Brand DNA saved! Creators and editors will follow these preferences.'),
                            backgroundColor: OrbitColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Save Brand DNA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline_rounded, color: Colors.black, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Utkarsh';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'U';

    final activeCount = _activeBooking != null ? 1 : 0;

    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_loadData(), _detectLiveLocation(), _loadBrandDNA()]);
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
                  // ── Top Header Actions: Book Now Button & Notification ──
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: OrbitColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: OrbitColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _onBookShootPressed(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'BOOK NOW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: OrbitColors.textPrimary, size: 24),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Shoot On Demand Title Header ───────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shoot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF7C5CFF)],
                    ).createShader(bounds),
                    child: const Text(
                      'On Demand.',
                      style: TextStyle(
                        fontSize: 36,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ORBIT V1.0.4 — PREMIUM ACCESS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
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

              // ── 2x2 Quick Action Cards ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.explore_outlined, color: Color(0xFF00E5FF), size: 20),
                      ),
                      title: 'EXPLORE\nSTYLES',
                      subtitle: 'SAMPLE REELS',
                      onTap: () => _onBookShootPressed(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C5CFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.videocam_outlined, color: Color(0xFF9B82FF), size: 20),
                      ),
                      title: 'TRACK\nORDER',
                      subtitle: '$activeCount ACTIVE',
                      onTap: _onTrackOrderPressed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.article_outlined, color: Colors.white70, size: 20),
                      ),
                      title: 'RECENT\nSHOOTS',
                      subtitle: '${_recentBookings.length} COMPLETED',
                      onTap: () => context.push('/history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.pinkAccent, size: 20),
                      ),
                      title: 'BRAND\nIDENTITY',
                      subtitle: _brandName.toUpperCase(),
                      onTap: _openBrandIdentityModal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space24),

              // ── Sample Video Reels Showcase ───────────────────────────
              OrbitReelShowcaseCarousel(
                onBookNow: () => _onBookShootPressed(),
              ),

              const SizedBox(height: OrbitSpacing.space24),

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

/// 2x2 Action Card Widget
class _ActionCard extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        OrbitMotion.lightTap();
        onTap();
      },
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OrbitColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OrbitColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            iconWidget,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
