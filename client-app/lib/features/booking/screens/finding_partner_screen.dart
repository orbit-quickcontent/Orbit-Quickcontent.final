import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

const String _kSocketUrl = String.fromEnvironment(
  'SOCKET_URL',
  defaultValue: 'http://10.0.2.2:5000',
);

class FindingPartnerScreen extends StatefulWidget {
  final String bookingId;
  const FindingPartnerScreen({super.key, required this.bookingId});

  @override
  State<FindingPartnerScreen> createState() => _FindingPartnerScreenState();
}

class _FindingPartnerScreenState extends State<FindingPartnerScreen> with SingleTickerProviderStateMixin {
  io.Socket? _socket;
  String _statusMessage = 'Finding the best videographer near you...';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _pollStatus();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSocket() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'orbit_access_token');

    _socket = io.io(_kSocketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    _socket!.connect();
    _socket!.emit('join:booking', widget.bookingId);

    _socket!.on('booking:status-update', (data) {
      if (!mounted) return;
      final status = data['status'];
      _handleStatusChange(status);
    });

    _socket!.on('dispatch:accepted', (data) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Partner found! Getting ready...');
    });
  }

  void _handleStatusChange(String status) {
    switch (status) {
      case 'DISPATCHING':
        setState(() => _statusMessage = 'Searching for partners nearby...');
        break;
      case 'PARTNER_OFFERED':
        setState(() => _statusMessage = 'Sending request to nearby partners...');
        break;
      case 'PARTNER_ASSIGNED':
        if (mounted) context.pushReplacement('/booking/${widget.bookingId}');
        break;
      case 'NO_PARTNER_AVAILABLE':
        if (mounted) {
          _showNoPartnerDialog();
        }
        break;
    }
  }

  void _pollStatus() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final res = await apiClient.get('/bookings/${widget.bookingId}');
        _handleStatusChange(res.data['status']);
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
                // Pulsing orbit animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: OrbitClientTheme.primaryFixed.withOpacity(0.15), width: 1),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1500.ms)
                    .fadeOut(duration: 1500.ms),

                    // Middle ring
                    Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: OrbitClientTheme.primaryFixed.withOpacity(0.3), width: 1.5),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(), delay: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms)
                    .fadeOut(duration: 1500.ms),

                    // Inner circle (gradient)
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: OrbitClientTheme.primaryGradient,
                        boxShadow: [BoxShadow(color: OrbitClientTheme.primaryFixed.withOpacity(0.4), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 800.ms),
                  ],
                ),

                const SizedBox(height: 48),

                Text('Finding Your Partner', style: OrbitClientTheme.textTheme.headlineLarge)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                Text(
                  _statusMessage,
                  style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(color: OrbitClientTheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ).animate(key: ValueKey(_statusMessage)).fadeIn(duration: 300.ms),

                const SizedBox(height: 48),

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
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
