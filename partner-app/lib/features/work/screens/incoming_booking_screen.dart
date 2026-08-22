import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_map_workspace.dart';
import '../../../analytics/analytics_service.dart';

class IncomingBookingScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;
  const IncomingBookingScreen({super.key, required this.dispatch});

  @override
  State<IncomingBookingScreen> createState() => _IncomingBookingScreenState();
}

class _IncomingBookingScreenState extends State<IncomingBookingScreen> {
  final ValueNotifier<int> _countdown = ValueNotifier<int>(15);
  Timer? _timer;
  bool _isResponding = false;
  late final DateTime _receivedAt;

  @override
  void initState() {
    super.initState();
    _receivedAt = DateTime.now();
    OrbitMotion.successHaptic();

    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    partnerAnalytics.trackRequestReceived(
      bookingId: booking['id']?.toString() ?? 'unknown',
      earning: (booking['earning'] ?? booking['partnerSalary'] ?? 500) as int,
      distanceKm: ((booking['distanceKm'] ?? 1.8) as num).toDouble(),
    );

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown.value > 0) {
        _countdown.value--;
      } else {
        t.cancel();
        if (mounted) _respond(accept: false);
      }
    });
  }

  Future<void> _respond({required bool accept}) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    _timer?.cancel();

    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    final bookingId = booking['id']?.toString() ?? widget.dispatch['bookingId']?.toString() ?? widget.dispatch['id']?.toString();
    if (bookingId == null) {
      if (mounted) context.go('/work');
      return;
    }

    final responseTimeMs = DateTime.now().difference(_receivedAt).inMilliseconds;

    try {
      if (accept) {
        OrbitMotion.successHaptic();
        partnerAnalytics.trackRequestAccepted(bookingId: bookingId, responseTimeMs: responseTimeMs);
        await partnerApiClient.post('/bookings/$bookingId/accept');
        if (mounted) context.go('/job/$bookingId');
      } else {
        OrbitMotion.lightTap();
        partnerAnalytics.trackRequestRejected(bookingId: bookingId, reason: 'manual_decline');
        await partnerApiClient.post('/bookings/$bookingId/decline');
        if (mounted) context.go('/work');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Job no longer available or assigned to another creator.'),
            backgroundColor: OrbitColors.danger,
          ),
        );
        context.go('/work');
      }
    } catch (_) {
      if (mounted) context.go('/work');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? widget.dispatch;
    final totalEarning = (booking['earning'] ?? booking['partnerSalary'] ?? 500) as int;
    final distanceKm = ((booking['distanceKm'] ?? 1.8) as num).toDouble();
    final durationMin = (booking['shootDurationMin'] ?? 25) as int;
    final locationName = booking['locationName']?.toString() ?? 'The Loft Cafe';
    final address = booking['address']?.toString() ?? 'Baner High Street, Pune';
    final clientName = booking['clientName']?.toString() ?? 'Arjun & Maya';
    final shootType = booking['shootType']?.toString() ?? '1 Reel (30s vertical) • Color Grade';

    final breakdown = booking['pricingBreakdown'] as Map<String, dynamic>? ?? {
      'shoot': 400,
      'distance': 50,
      'surge': 50,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: Stack(
        children: [
          // ── Background Live Map ───────────────────────────────────────────
          const OrbitMapWorkspace(
            isOnline: true,
            isNavigating: true,
          ),

          // ── Top Decline Button & Countdown Pill ───────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _isResponding ? null : () => _respond(accept: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF252B33)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  // Circular Countdown Badge
                  ValueListenableBuilder<int>(
                    valueListenable: _countdown,
                    builder: (context, val, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15181D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${val}s',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Decision-Critical Request Sheet ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF15181D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF252B33), width: 1.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, -6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client & Shoot Type Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW ORBIT SHOOT',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text('4.9 ★ $clientName', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── UPFRONT PAYOUT & SURGE ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('₹', style: TextStyle(color: Color(0xFF22C55E), fontSize: 24, fontWeight: FontWeight.w900)),
                              Text(
                                '$totalEarning',
                                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '1.6x Peak Surge applied • 100% direct payout',
                            style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2027),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF252B33)),
                        ),
                        child: Text(
                          '${distanceKm}km • ~${durationMin}min',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: Color(0xFF252B33), height: 24),

                  // ── Location & Shoot Specs ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2027),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_outlined, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(locationName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(address, style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Shoot Specs Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2027),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_outlined, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shootType,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Transparent Earnings Breakdown Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0D10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF252B33)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Shoot: ₹${breakdown['shoot'] ?? 400}', style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11)),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        Text('Travel: ₹${breakdown['distance'] ?? 50}', style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 11)),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        Text('Surge: ₹${breakdown['surge'] ?? 50}', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── ACCEPT JOB DOMINANT CTA ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _isResponding ? null : () => _respond(accept: true),
                      child: _isResponding
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ACCEPT JOB',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
                              ],
                            ),
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
