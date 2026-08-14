import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class IncomingBookingScreen extends StatefulWidget {
  final Map<String, dynamic> dispatch;
  const IncomingBookingScreen({super.key, required this.dispatch});

  @override
  State<IncomingBookingScreen> createState() => _IncomingBookingScreenState();
}

class _IncomingBookingScreenState extends State<IncomingBookingScreen>
    with TickerProviderStateMixin {
  int _countdown = 45;
  Timer? _timer;
  bool _isResponding = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
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

    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? {};
    final bookingId = booking['id'] as String?;
    if (bookingId == null) {
      if (mounted) context.go('/work');
      return;
    }

    try {
      if (accept) {
        await partnerApiClient.post('/bookings//accept');
        if (mounted) context.go('/job/');
      } else {
        await partnerApiClient.post('/bookings//decline');
        if (mounted) context.go('/work');
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to respond. Please try again.')),
        );
        setState(() => _isResponding = false);
        _startTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.dispatch['booking'] as Map<String, dynamic>? ?? {};
    final pkg = booking['package'] as Map<String, dynamic>? ?? {};
    final progressFraction = _countdown / 45.0;

    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressFraction,
                      strokeWidth: 5,
                      backgroundColor: OrbitPartnerTheme.surface,
                      valueColor: AlwaysStoppedAnimation(
                        _countdown > 15 ? OrbitPartnerTheme.primary
                            : _countdown > 5 ? const Color(0xFFFFB347)
                            : OrbitPartnerTheme.error,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: _countdown > 15 ? OrbitPartnerTheme.primary
                                : _countdown > 5 ? const Color(0xFFFFB347)
                                : OrbitPartnerTheme.error,
                          ),
                        ),
                        Text('seconds', style: OrbitPartnerTheme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: OrbitPartnerTheme.partnerGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'NEW SHOOT REQUEST',
                  style: OrbitPartnerTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.black, letterSpacing: 2, fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OrbitPartnerTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pkg['name'] ?? 'Shoot Request', style: OrbitPartnerTheme.textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(pkg['focus'] ?? 'Professional Video Shoot', style: OrbitPartnerTheme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: OrbitPartnerTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.4)),
                          ),
                          child: Text('Rs.500', style: TextStyle(color: OrbitPartnerTheme.primary, fontWeight: FontWeight.w800, fontSize: 22)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: OrbitPartnerTheme.outlineFaint),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: OrbitPartnerTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking['address'] ?? 'Location shared on acceptance',
                            style: OrbitPartnerTheme.textTheme.bodySmall,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined, color: OrbitPartnerTheme.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(booking['timeSlot'] ?? 'Immediate', style: OrbitPartnerTheme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isResponding ? null : () => _respond(accept: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: OrbitPartnerTheme.error,
                        side: BorderSide(color: OrbitPartnerTheme.error.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isResponding ? null : () => _respond(accept: true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: OrbitPartnerTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isResponding
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Accept Shoot', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 16),
              Text(
                'Auto-decline in  seconds',
                style: OrbitPartnerTheme.textTheme.bodySmall?.copyWith(color: OrbitPartnerTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
