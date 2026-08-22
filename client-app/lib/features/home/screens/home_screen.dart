import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
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

  // Brand Identity State
  String _brandName = 'My Brand';
  String _brandHandle = '@orbit_creator';
  String _selectedStyle = 'Cinematic & Dynamic';

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('home_screen');
    _detectLiveLocation();
    _loadData();
    _loadPackages();
    _loadBrandIdentity();
  }

  Future<void> _loadBrandIdentity() async {
    try {
      const storage = FlutterSecureStorage();
      final name = await storage.read(key: 'brand_name');
      final handle = await storage.read(key: 'brand_handle');
      final style = await storage.read(key: 'brand_style');
      if (mounted) {
        setState(() {
          if (name != null) _brandName = name;
          if (handle != null) _brandHandle = handle;
          if (style != null) _selectedStyle = style;
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
            'id': 'pkg_standard',
            'name': 'Personalized',
            'tier': 'STANDARD',
            'priceDisplay': 1999,
            'focus': '3 Master Reels + B-Roll',
            'deliveryTime': '60-120 mins delivery',
            'features': ['3 Short-form Reels', 'Motion Captions', 'Cinematic B-Roll', '4K Export'],
            'popular': true,
          },
          {
            'id': 'pkg_premium',
            'name': 'Professional',
            'tier': 'PREMIUM',
            'priceDisplay': 4999,
            'focus': '6 Master Reels + Brand Kit',
            'deliveryTime': '60-120 mins delivery',
            'features': ['6 Master Reels', 'Sound Design & VO', 'Custom Brand Kit', 'Raw Footage'],
            'popular': false,
          },
          {
            'id': 'pkg_quick',
            'name': 'Quick Impact',
            'tier': 'QUICK',
            'priceDisplay': 999,
            'focus': '1 High-Impact 9:16 Reel',
            'deliveryTime': '30-60 mins delivery',
            'features': ['1 Edited Reel (30s)', 'Trending Audio', 'Pro Color Grade', 'Fast Export'],
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

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
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
        backgroundColor: OrbitColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
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
                  style: ElevatedButton.styleFrom(backgroundColor: OrbitColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      );
    }
  }

  void _onRecentProjectsPressed() {
    OrbitMotion.lightTap();
    context.push('/history');
  }

  void _openBrandIdentityModal() {
    OrbitMotion.lightTap();
    final nameCtrl = TextEditingController(text: _brandName);
    final handleCtrl = TextEditingController(text: _brandHandle);
    String tempStyle = _selectedStyle;

    showModalBottomSheet(
      context: context,
      backgroundColor: OrbitColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brand Identity & DNA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Editors & creators use this DNA for your reels', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                    ],
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
                  filled: true,
                  fillColor: OrbitColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
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
                  filled: true,
                  fillColor: OrbitColors.surfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OrbitColors.borderSubtle)),
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
                        border: Border.all(color: isSel ? OrbitColors.secondary : OrbitColors.borderSubtle),
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
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: OrbitColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final bName = nameCtrl.text.trim();
                    final bHandle = handleCtrl.text.trim();
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);

                    const storage = FlutterSecureStorage();
                    await storage.write(key: 'brand_name', value: bName);
                    await storage.write(key: 'brand_handle', value: bHandle);
                    await storage.write(key: 'brand_style', value: tempStyle);

                    if (mounted) {
                      setState(() {
                        _brandName = bName;
                        _brandHandle = bHandle;
                        _selectedStyle = tempStyle;
                      });
                    }
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Brand DNA saved! Creators will follow these preferences.'), backgroundColor: OrbitColors.success),
                    );
                  },
                  child: const Text('Save Brand DNA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'Test User';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'TU';

    final hasActive = _activeBooking != null;
    final activeCount = hasActive ? 1 : 0;
    final deliveredCount = _recentBookings.length;

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
              left: 18,
              right: 18,
              top: 14,
              bottom: 100,
            ),
            children: [
              // ── Top Bar Header (TU Avatar + Good Afternoon + Search / Bell) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E2229),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
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
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E5FF),
                                border: Border.all(color: OrbitColors.background, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeGreeting(),
                            style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hi, $userName',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                        onPressed: () => context.push('/packages'),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 22),
                            onPressed: () => context.push('/notifications'),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E5FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 22),
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Headline: "Shoot In Progress." (ORBIT V1.0.4 — PREMIUM ACCESS) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shoot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      hasActive ? 'In Progress.' : 'On Demand.',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF29B6F6),
                        letterSpacing: -0.5,
                        height: 1.05,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF29B6F6).withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ORBIT V1.0.4 — PREMIUM ACCESS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 4 Quick Action Cards Grid (2x2) with Distinct Functions ──
              Row(
                children: [
                  // Card 1: EXPLORE STYLES (Replaces duplicate Book button)
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E5FF),
                        ),
                        child: const Icon(Icons.explore_outlined, color: Colors.black, size: 22),
                      ),
                      title: 'EXPLORE\nSTYLES',
                      subtitle: 'SAMPLE REELS',
                      onTap: () => context.push('/packages'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card 2: TRACK ORDER
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBA68C8), Color(0xFF8E24AA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'DNA',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                          ),
                        ),
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
                  // Card 3: RECENT PROJECTS
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF232830),
                        ),
                        child: const Icon(Icons.article_outlined, color: Colors.white70, size: 20),
                      ),
                      title: 'RECENT\nPROJECTS',
                      subtitle: '$deliveredCount DELIVERED',
                      onTap: _onRecentProjectsPressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card 4: BRAND IDENTITY
                  Expanded(
                    child: _ActionCard(
                      iconWidget: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF232830),
                        ),
                        child: const Icon(Icons.star_outline_rounded, color: Colors.white70, size: 20),
                      ),
                      title: 'BRAND\nIDENTITY',
                      subtitle: 'ASSETS & DNA',
                      onTap: _openBrandIdentityModal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Live Shoot Tracking Banner (If Active Shoot exists) ──
              if (hasActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131720),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E3A5F), width: 1.2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F1522), Color(0xFF131A28)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LIVE SHOOT TRACKING',
                              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_activeBooking!['package']?['name'] ?? 'Personalized'} in progress',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: OrbitColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _activeBooking!['address'] ?? _currentLocation,
                                    style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/booking/${_activeBooking!['id']}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text('Track', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Inspiration & Sample Reels Showcase ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Trending Reels & Styles',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/packages'),
                    child: const Row(
                      children: [
                        Text('Explore', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF00E5FF), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OrbitReelShowcaseCarousel(
                onBookNow: () => _onBookShootPressed(),
              ),

              const SizedBox(height: 24),

              // ── Featured Packages Section (Horizontal Cards) ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Featured Packages',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/packages'),
                    child: const Row(
                      children: [
                        Text('View All', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF00E5FF), size: 16),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Horizontal Packages Carousel
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _packages.length,
                  itemBuilder: (ctx, idx) {
                    final pkg = _packages[idx];
                    final pkgId = pkg['id']?.toString() ?? 'pkg_standard';
                    final isPopular = pkg['popular'] == true;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _onBookShootPressed(packageId: pkgId),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14171E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isPopular ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFF222733),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      pkg['name'] ?? 'Package',
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222733),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white70),
                                  ),
                                ],
                              ),
                              Text(
                                pkg['deliveryTime'] ?? '60-120 mins delivery',
                                style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${pkg['priceDisplay'] ?? 1999}',
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Book',
                                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent Shoots Timeline Section ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Shoots', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  if (_recentBookings.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push('/history'),
                      child: const Text('History', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading) ...[
                const OrbitLoadingCard(height: 70),
              ] else if (_recentBookings.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222733)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222733),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.movie_outlined, color: Color(0xFF00E5FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No recent shoots', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Book your first shoot to start creating reels.', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._recentBookings.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14171E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF222733)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222733),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.videocam_outlined, color: Color(0xFF00E5FF), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['package']?['name'] ?? 'Video Shoot',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    b['address'] ?? 'Confirmed Location',
                                    style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11),
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

/// 2x2 Premium Action Card
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
      onTap: onTap,
      child: Container(
        height: 142,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14171E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF222733), width: 1),
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
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
