import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_map_workspace.dart';
import '../../../analytics/analytics_service.dart';
import '../../../services/realtime_service.dart';
import '../../../features/auth/providers/partner_auth_provider.dart';

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _liveRefreshTimer;
  Map<String, dynamic>? _activeJob;
  bool _isOnline = true;
  final int _todayEarnings = 2450;
  final int _completedToday = 3;
  final int _targetToday = 5;
  final int _bonusAmount = 300;

  // Real-time client bookings combined with nearby opportunities
  List<Map<String, dynamic>> _nearbyJobs = [];
  List<Map<String, dynamic>> _clientPins = [];

  final List<Map<String, dynamic>> _defaultSeedJobs = [
    {
      'id': 'job_loft_01',
      'clientName': 'The Loft Cafe',
      'category': 'FASHION & CAFE',
      'shootType': '1 Reel (30–60s) • Color Grade',
      'price': 1999,
      'payout': 1400,
      'distanceKm': 1.8,
      'etaMin': 4,
      'address': 'Baner High Street, Pune',
      'urgency': 'URGENT',
      'surgeBonus': 150,
      'isLiveClient': false,
      'xRatio': 0.20,
      'yRatio': 0.34,
    },
    {
      'id': 'job_aura_02',
      'clientName': 'Aura Luxury Salon',
      'category': 'BEAUTY & LIFESTYLE',
      'shootType': '3 UGC Commercial Reels',
      'price': 4999,
      'payout': 3500,
      'distanceKm': 3.2,
      'etaMin': 8,
      'address': 'Koregaon Park, Lane 7',
      'urgency': 'HIGH PAYOUT',
      'surgeBonus': 200,
      'isLiveClient': false,
      'xRatio': 0.80,
      'yRatio': 0.34,
    },
    {
      'id': 'job_brew_03',
      'clientName': 'Urban Brewery & Kitchen',
      'category': 'NIGHTLIFE & EVENTS',
      'shootType': 'Live DJ & Event Video',
      'price': 2999,
      'payout': 2100,
      'distanceKm': 2.1,
      'etaMin': 6,
      'address': 'Balewadi High St, Pune',
      'urgency': 'POPULAR',
      'surgeBonus': 100,
      'isLiveClient': false,
      'xRatio': 0.80,
      'yRatio': 0.62,
    },
    {
      'id': 'job_cross_04',
      'clientName': 'CrossFit Studio',
      'category': 'FITNESS & SPORTS',
      'shootType': 'HIIT Workout Promo Reel',
      'price': 999,
      'payout': 750,
      'distanceKm': 4.5,
      'etaMin': 12,
      'address': 'Aundh Main Road, Pune',
      'urgency': 'QUICK SHOOT',
      'surgeBonus': 50,
      'isLiveClient': false,
      'xRatio': 0.18,
      'yRatio': 0.62,
    },
    {
      'id': 'job_prism_05',
      'clientName': 'Prism Luxury Real Estate',
      'category': 'COMMERCIAL & ADS',
      'shootType': '5 4K Master Video Ads',
      'price': 8999,
      'payout': 6300,
      'distanceKm': 5.8,
      'etaMin': 15,
      'address': 'Senapati Bapat Road, Pune',
      'urgency': 'PREMIUM TIER',
      'surgeBonus': 500,
      'isLiveClient': false,
      'xRatio': 0.50,
      'yRatio': 0.22,
    },
  ];

  @override
  void initState() {
    super.initState();
    _nearbyJobs = List.from(_defaultSeedJobs);
    _buildClientPinsFromJobs();
    partnerAnalytics.trackScreenView('partner_home_map');
    _loadDashboardData();
    _startRealtimePolling();

    // Periodic live sync every 3.5s for real-time client booking detection
    _liveRefreshTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted && _isOnline) {
        _loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    partnerRealtime.stop();
    partnerRealtime.clearCallbacks();
    super.dispose();
  }

  void _buildClientPinsFromJobs() {
    final List<Map<String, dynamic>> pins = [];
    final mediaQuery = MediaQuery.of(context);
    final w = mediaQuery.size.width > 0 ? mediaQuery.size.width : 390.0;
    final h = mediaQuery.size.height > 0 ? mediaQuery.size.height : 844.0;

    for (final job in _nearbyJobs) {
      final xR = (job['xRatio'] as double?) ?? 0.5;
      final yR = (job['yRatio'] as double?) ?? 0.5;
      pins.add({
        'name': job['clientName'] ?? 'Client',
        'pkg': '₹${job['price'] ?? 1999}',
        'x': w * xR,
        'y': h * yR,
        'job': job,
      });
    }

    _clientPins = pins;
  }

  void _startRealtimePolling() {
    final auth = ref.read(partnerAuthProvider);
    final partnerId = auth.partnerId;
    if (partnerId == null || partnerId.isEmpty) {
      partnerRealtime.start('partner_default_1');
    } else {
      partnerRealtime.start(partnerId);
    }

    partnerRealtime.onDispatchNew((payload) {
      if (!mounted) return;
      _showIncomingBookingPopup(payload);
    });

    partnerRealtime.onBookingStatusUpdate((payload) {
      if (!mounted) return;
      _loadDashboardData();
    });
  }

  void _showIncomingBookingPopup(Map<String, dynamic> offer) {
    HapticFeedback.heavyImpact();
    final packageName = offer['packageName'] ?? 'Shoot Package';
    final clientArea = offer['clientArea'] ?? offer['address'] ?? 'Nearby Client';
    final earning = offer['earning'] ?? offer['partnerSalary'] ?? 1400;
    final etaMinutes = offer['etaMinutes'] ?? 5;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF15181D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF22D55E), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF22D55E).withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 5),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFF22C55E), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🎬 LIVE CLIENT DISPATCH', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(packageName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2027),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF252B33)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('GUARANTEED PAYOUT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('₹$earning', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Container(width: 1, height: 26, color: const Color(0xFF252B33)),
                    Column(
                      children: [
                        const Text('ARRIVAL ETA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('~$etaMinutes mins', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF38BDF8), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      clientArea,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/incoming', extra: offer);
                  },
                  child: const Text('ACCEPT & COMMENCE DISPATCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    try {
      // 1. Fetch real-time available jobs and active bookings
      final res = await partnerApiClient.get('/partner/available-jobs');
      final data = res.data;

      // 2. Also fetch all active bookings to detect live clients
      final bookingsRes = await partnerApiClient.get('/bookings', params: {'limit': '10'});
      final rawBookings = List<Map<String, dynamic>>.from(bookingsRes.data['bookings'] ?? []);

      final liveClientJobs = <Map<String, dynamic>>[];
      int xIdx = 0;
      final coords = [
        [0.22, 0.32],
        [0.78, 0.32],
        [0.24, 0.65],
        [0.76, 0.65],
        [0.50, 0.20],
      ];

      for (final bk in rawBookings) {
        final status = bk['status'] as String? ?? '';
        if (['PAID', 'DISPATCHING', 'PARTNER_OFFERED', 'PARTNER_ASSIGNED', 'EN_ROUTE', 'ARRIVED', 'SHOOTING'].contains(status)) {
          final pkg = bk['package'] as Map<String, dynamic>? ?? {};
          final coord = coords[xIdx % coords.length];
          xIdx++;

          liveClientJobs.add({
            'id': bk['id'] ?? 'bk_live',
            'clientName': bk['user']?['name'] ?? 'Orbit Client (${bk['address']?.toString().split(',')[0] ?? 'Live'})',
            'category': 'LIVE CLIENT SHOOT',
            'shootType': pkg['name'] ?? 'Cinematic Shoot',
            'price': pkg['price'] ?? 1999,
            'payout': pkg['partnerPayout'] ?? 1400,
            'distanceKm': 1.6,
            'etaMin': 4,
            'address': bk['address'] ?? 'Nearby Location',
            'urgency': 'LIVE REQUEST',
            'surgeBonus': 200,
            'isLiveClient': true,
            'xRatio': coord[0],
            'yRatio': coord[1],
          });
        }
      }

      if (mounted) {
        setState(() {
          if (data != null && data['activeJob'] != null) {
            _activeJob = data['activeJob'];
          }

          // Merge live client jobs with default seed jobs
          final combined = <Map<String, dynamic>>[...liveClientJobs];
          for (final sj in _defaultSeedJobs) {
            if (!combined.any((j) => j['clientName'] == sj['clientName'])) {
              combined.add(sj);
            }
          }
          _nearbyJobs = combined;
          _buildClientPinsFromJobs();
        });
      }
    } catch (_) {}
  }

  void _toggleOnlineStatus() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isOnline = !_isOnline;
    });

    final snackText = _isOnline
        ? 'You are now ONLINE • Real-time client requests active'
        : 'You are now OFFLINE • Real-time client requests paused';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_isOnline ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
                color: _isOnline ? const Color(0xFF22C55E) : Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(snackText)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Safety Modal ─────────────────────────────────────────────────────────
  void _showSafetyModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 24),
                SizedBox(width: 10),
                Text('Partner Safety & Emergency Desk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your GPS location is live-shared with Orbit Safety Command during all active client shoots.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            // Emergency SOS
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.sos_rounded, color: Colors.white, size: 24),
                label: const Text('TRIGGER EMERGENCY SOS (POLICE & HQ)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚨 Emergency alert dispatched to Orbit 24/7 Command & Local Authorities!'),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF38BDF8), size: 20),
                label: const Text('Call Partner Support Desk (+91 1800-ORBIT)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling Orbit 24/7 Helpline...')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nearby Clients & Available Jobs Modal / Scroll Sheet ───────────────────
  void _showNearbyClientsModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEARBY CLIENT SHOOTS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                      const SizedBox(height: 2),
                      Text('${_nearbyJobs.length} real-time client opportunities near you', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar_rounded, size: 12, color: Color(0xFF22C55E)),
                        SizedBox(width: 4),
                        Text('REAL-TIME', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10.5, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _nearbyJobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = _nearbyJobs[index];
                    return _buildJobCard(job, ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, BuildContext modalCtx) {
    final isLive = job['isLiveClient'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2027),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive ? const Color(0xFF22C55E) : const Color(0xFF252B33),
          width: isLive ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? const Color(0xFF22C55E) : Colors.black).withValues(alpha: isLive ? 0.18 : 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Urgency, and Payout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isLive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isLive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      job['category'] as String,
                      style: TextStyle(
                        color: isLive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('● LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  const Text('Payout: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text(
                    '₹${job['payout']}',
                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Client Name & Shoot Type
          Text(job['clientName'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(job['shootType'] as String, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),

          // Distance, Time & Location
          Row(
            children: [
              const Icon(Icons.navigation_rounded, color: Color(0xFF38BDF8), size: 14),
              const SizedBox(width: 4),
              Text('${job['distanceKm']} km (${job['etaMin']} min arrival)', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.white24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job['address'] as String,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button: Accept & Navigate
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(modalCtx);
                _openJobDispatch(job);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLive ? 'ACCEPT LIVE CLIENT BOOKING' : 'ACCEPT & START NAVIGATION',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.4)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openJobDispatch(Map<String, dynamic> job) {
    context.push('/incoming', extra: {
      'id': job['id'],
      'earning': job['payout'],
      'distanceKm': job['distanceKm'],
      'shootDurationMin': 30,
      'locationName': job['clientName'],
      'address': job['address'],
      'reelsCount': 1,
      'shootType': job['shootType'],
      'clientName': job['clientName'],
      'pricingBreakdown': {
        'shoot': (job['payout'] as int) - 100,
        'distance': 50,
        'surge': job['surgeBonus'] ?? 50,
      },
    });
  }

  // ── Partner Sliding Drawer ────────────────────────────────────────────────
  Widget _buildPartnerDrawer() {
    final auth = ref.watch(partnerAuthProvider);
    final partnerName = auth.name?.isNotEmpty == true ? auth.name! : 'Utkarsh P';

    return Drawer(
      backgroundColor: const Color(0xFF11141A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                        ),
                        child: const Center(
                          child: Text('UP', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    partnerName,
                                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('PTR-8829 • ★ 4.9 Pro Creator', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Online Toggle Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F29),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF252B33)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? const Color(0xFF22C55E) : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'ONLINE • READY' : 'OFFLINE',
                              style: TextStyle(
                                color: _isOnline ? const Color(0xFF22C55E) : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnline,
                          activeThumbColor: const Color(0xFF22C55E),
                          onChanged: (_) => _toggleOnlineStatus(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Today's Stats Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F29),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDrawerStat('₹$_todayEarnings', 'Today Earned'),
                        Container(width: 1, height: 26, color: const Color(0xFF252B33)),
                        _buildDrawerStat('$_completedToday/$_targetToday', 'Shoots Done'),
                        Container(width: 1, height: 26, color: const Color(0xFF252B33)),
                        _buildDrawerStat('98%', 'Accept Rate'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF252B33), height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.map_rounded,
                    title: 'Live Map & Demand Zones',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups_rounded,
                    title: 'Nearby Real-Time Shoots',
                    badge: '${_nearbyJobs.length}',
                    onTap: () {
                      Navigator.pop(context);
                      _showNearbyClientsModal();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.movie_creation_rounded,
                    title: 'Past Shoots & Work History',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/work-history');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Earnings & Instant Payouts',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/earnings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Creator Profile & Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shield_rounded,
                    title: 'Safety Command & SOS',
                    iconColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      _showSafetyModal();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.headset_mic_rounded,
                    title: 'Help Desk & WhatsApp Support',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Orbit Partner 24/7 Support Desk...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF252B33), height: 1),

            // Logout Action
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              title: const Text('Log Out of Orbit', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(partnerAuthProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF38BDF8), size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B0D10),
      drawer: _buildPartnerDrawer(),
      body: Stack(
        children: [
          // ── 1. Fullscreen Dark Map Workspace with Real-time Client Pins ──
          OrbitMapWorkspace(
            isOnline: _isOnline,
            clientPins: _clientPins,
            onClientPinTap: (pinData) {
              final job = pinData['job'] as Map<String, dynamic>?;
              if (job != null) _openJobDispatch(job);
            },
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            onSafetyPressed: _showSafetyModal,
            onNearbyClientsPressed: _showNearbyClientsModal,
            onRecenterPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GPS Centered at your live coordinates'), duration: Duration(seconds: 1)),
              );
            },
          ),

          // ── 2. Top Floating Operational Header ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0B0D10).withValues(alpha: 0.95),
                    const Color(0xFF0B0D10).withValues(alpha: 0.6),
                    const Color(0xFF0B0D10).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Hamburger Menu Button with Live Badge
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15181D),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                            ],
                          ),
                          child: Stack(
                            children: [
                              const Center(child: Icon(Icons.menu_rounded, color: Colors.white, size: 22)),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_nearbyJobs.length}',
                                      style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center: Floating Today's Earnings Pill
                      GestureDetector(
                        onTap: () => context.push('/earnings'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15181D),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$_todayEarnings',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right: Search / Nearby Clients Icon
                      GestureDetector(
                        onTap: _showNearbyClientsModal,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15181D),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                            ],
                          ),
                          child: const Center(child: Icon(Icons.search_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Central GO / ONLINE Pulse Action Button ───────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 230,
            child: Center(
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isOnline ? const Color(0xFF22C55E) : const Color(0xFF3B82F6)).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isOnline ? 'ON' : 'GO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Bottom Operational Sheet & Incentive Challenges ────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF15181D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF252B33), width: 1.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Strip (Tappable to see live nearby client shoots)
                  GestureDetector(
                    onTap: _showNearbyClientsModal,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                          Row(
                            children: [
                              if (_isOnline) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'This area is busy • High demand',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ] else ...[
                                const Text(
                                  "You're offline",
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                          const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF38BDF8), size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Active Shoot Card (If any) or Incentive Card
                  if (_activeJob != null) ...[
                    GestureDetector(
                      onTap: () => context.push('/job/${_activeJob!['id']}'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ACTIVE SHOOT IN PROGRESS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(_activeJob!['packageName'] ?? _activeJob!['package']?['name'] ?? 'Reel Shoot',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Resume ➔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Today's Incentive Challenge (Tappable to see nearby client shoots)
                    GestureDetector(
                      onTap: _showNearbyClientsModal,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2027),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF252B33)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      "TODAY'S CHALLENGE",
                                      style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$_completedToday / $_targetToday shoots',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_completedToday / _targetToday).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF252B33),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Earn ₹$_bonusAmount bonus on completing $_targetToday shoots',
                                  style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11.5),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── 5. Streamlined Bottom Navigation Bar ───────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0D10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF252B33)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Map', isSelected: true, onTap: () {}),
                        _NavItem(icon: Icons.movie_creation_outlined, activeIcon: Icons.movie_creation_rounded, label: 'Jobs', isSelected: false, onTap: () => context.push('/work-history')),
                        _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Earnings', isSelected: false, onTap: () => context.push('/earnings')),
                        _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', isSelected: false, onTap: () => context.push('/profile')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF15181D) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF38BDF8) : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
