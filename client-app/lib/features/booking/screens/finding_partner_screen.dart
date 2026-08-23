import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class FindingPartnerScreen extends StatefulWidget {
  final String bookingId;
  const FindingPartnerScreen({super.key, required this.bookingId});

  @override
  State<FindingPartnerScreen> createState() => _FindingPartnerScreenState();
}

class _FindingPartnerScreenState extends State<FindingPartnerScreen> {
  String _statusMessage = 'Finding the best videographer near you...';
  Timer? _pollingTimer;
  Timer? _eventPollingTimer;
  String _lastEventSince = DateTime.now().subtract(const Duration(minutes: 5)).toUtc().toIso8601String();

  @override
  void initState() {
    super.initState();
    _pollBookingStatus();
    _pollRealtimeEvents();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _eventPollingTimer?.cancel();
    super.dispose();
  }

  void _handleStatusChange(String? status) {
    if (status == null) return;
    switch (status) {
      case 'DISPATCHING':
        setState(() => _statusMessage = 'Searching for creators nearby...');
        break;
      case 'PARTNER_OFFERED':
        setState(() => _statusMessage = 'Notifying nearest verified videographers...');
        break;
      case 'PARTNER_ASSIGNED':
      case 'EN_ROUTE':
      case 'ARRIVED':
      case 'SHOOTING':
      case 'DELIVERED':
        if (mounted) context.pushReplacement('/booking/${widget.bookingId}');
        break;
      case 'NO_PARTNER_AVAILABLE':
        if (mounted) {
          _showNoPartnerDialog();
        }
        break;
    }
  }

  /// Poll booking status via direct GET /bookings/:id (fallback)
  void _pollBookingStatus() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final res = await apiClient.get('/bookings/${widget.bookingId}');
        _handleStatusChange(res.data['status']);
      } catch (_) {}
    });
  }

  /// Poll real-time events via GET /events/poll/booking/:id (primary)
  void _pollRealtimeEvents() {
    _eventPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await apiClient.get(
          '/events/poll/booking/${widget.bookingId}',
          params: {'since': _lastEventSince},
        );
        final data = res.data;
        if (data == null) return;

        final serverTime = data['serverTime'] as String?;
        if (serverTime != null) _lastEventSince = serverTime;

        final events = data['events'] as List? ?? [];
        for (final evt in events) {
          final event = evt as Map<String, dynamic>;
          final eventType = event['event'] as String? ?? '';
          final payload = event['payload'] as Map<String, dynamic>? ?? {};

          if (eventType == 'booking:status-update') {
            _handleStatusChange(payload['status'] as String?);
          } else if (eventType == 'dispatch:accepted') {
            if (mounted) {
              setState(() => _statusMessage = 'Partner found! Getting ready...');
            }
          }
        }
      } catch (_) {}
    });
  }

  void _showNoPartnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: OrbitClientTheme.surfaceContainerLow,
        title: const Text('No Partners Available'),
        content: const Text('We couldn\'t find a partner near you right now. Please try again later or book for a different time slot.'),
        actions: [
          TextButton(onPressed: () => context.go('/home'), child: const Text('Go Home')),
          TextButton(onPressed: () => context.go('/packages'), child: const Text('Try Again')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E0E), Color(0xFF131313)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ultra-smooth 60fps GPU Radar Animation
                const _PulsingOrbitRadar(),

                const SizedBox(height: 48),

                Text('Finding Your Partner', style: OrbitClientTheme.textTheme.headlineLarge)
                    .animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(color: OrbitClientTheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Searching radius indicator
                OrbitGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Text('SEARCHING WITHIN', style: OrbitClientTheme.textTheme.labelSmall),
                      const SizedBox(height: 8),
                      OrbitGradientText(
                        '2 km → 5 km → 10 km',
                        style: OrbitClientTheme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 250.ms).slideY(begin: 0.08),

                const SizedBox(height: 32),

                // Manual Navigation Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      OrbitGradientButton(
                        label: 'View Booking Status',
                        height: 48,
                        onPressed: () => context.pushReplacement('/booking/${widget.bookingId}'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text('Return to Home', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight, hardware-accelerated pulsing orbit radar widget
class _PulsingOrbitRadar extends StatefulWidget {
  const _PulsingOrbitRadar();

  @override
  State<_PulsingOrbitRadar> createState() => _PulsingOrbitRadarState();
}

class _PulsingOrbitRadarState extends State<_PulsingOrbitRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final wave1 = (progress).clamp(0.0, 1.0);
        final wave2 = ((progress + 0.5) % 1.0).clamp(0.0, 1.0);

        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer wave
              Transform.scale(
                scale: 0.8 + (wave1 * 0.5),
                child: Opacity(
                  opacity: (1.0 - wave1).clamp(0.0, 0.4),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OrbitClientTheme.primaryFixed,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Inner wave
              Transform.scale(
                scale: 0.8 + (wave2 * 0.45),
                child: Opacity(
                  opacity: (1.0 - wave2).clamp(0.0, 0.5),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OrbitClientTheme.primaryFixed,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Center pulsing core
              Transform.scale(
                scale: 0.96 + (0.06 * (1.0 - (progress - 0.5).abs() * 2)),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: OrbitClientTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: OrbitClientTheme.primaryFixed.withValues(alpha: 0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
