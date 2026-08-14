import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

const String _kSocketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://10.0.2.2:5000');

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;
  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  Map<String, dynamic>? _booking;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final res = await apiClient.get('/bookings/${widget.bookingId}');
      setState(() {
        _booking = res.data;
        _history = List<Map<String, dynamic>>.from(res.data['statusHistory'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
    _socket!.on('booking:status-update', (_) => _loadBooking());
    _socket!.on('partner:location', (data) {
      // Navigate to live tracking
      if (mounted && _booking?['status'] == 'EN_ROUTE') {
        context.push('/tracking/${widget.bookingId}');
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED': case 'PAYOUT_COMPLETED': return OrbitClientTheme.success;
      case 'PARTNER_ASSIGNED': case 'EN_ROUTE': case 'ARRIVED': case 'SHOOTING':
      case 'UPLOADING': case 'EDITING': return OrbitClientTheme.primaryFixed;
      case 'CANCELLED': case 'FAILED': return OrbitClientTheme.error;
      default: return OrbitClientTheme.onSurfaceVariant;
    }
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final status = _booking?['status'] ?? '';
    final pkg = _booking?['package'] as Map<String, dynamic>? ?? {};
    final partner = _booking?['partner'] as Map<String, dynamic>? ?? {};
    final partnerUser = partner['user'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => context.pop()),
        title: Text('Booking Status', style: OrbitClientTheme.textTheme.headlineMedium),
        actions: [
          if (status == 'EN_ROUTE' || status == 'PARTNER_ASSIGNED')
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => context.push('/tracking/${widget.bookingId}'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: OrbitClientTheme.primaryFixed))
          : RefreshIndicator(
              onRefresh: _loadBooking,
              color: OrbitClientTheme.primaryFixed,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Status Hero Card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor(status).withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(status).withOpacity(0.15),
                            border: Border.all(color: _statusColor(status).withOpacity(0.4), width: 1.5),
                          ),
                          child: Icon(_statusIcon(status), color: _statusColor(status), size: 30),
                        )
                        .animate(onPlay: status == 'EN_ROUTE' ? (c) => c.repeat(reverse: true) : null)
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 800.ms),
                        const SizedBox(height: 14),
                        Text(_statusLabel(status), style: OrbitClientTheme.textTheme.headlineMedium?.copyWith(color: _statusColor(status))),
                        const SizedBox(height: 6),
                        Text(_statusDescription(status), style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant), textAlign: TextAlign.center),
                        if (status == 'DELIVERED') ...[
                          const SizedBox(height: 16),
                          OrbitGradientButton(label: '🎬 Watch Your Reel', height: 44, onPressed: () {
                            // Open reel URL
                          }),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 20),

                  // ── Partner Card ─────────────────────────────────────────
                  if (partner.isNotEmpty) ...[
                    OrbitGlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: OrbitClientTheme.primaryGradient,
                            ),
                            child: Center(child: Text(
                              (partnerUser['name']?.isNotEmpty == true ? partnerUser['name']![0] : 'P').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
                            )),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('YOUR PARTNER', style: OrbitClientTheme.textTheme.labelSmall),
                              Text(partnerUser['name'] ?? 'Partner', style: OrbitClientTheme.textTheme.titleMedium),
                              Row(children: [
                                const Icon(Icons.star, size: 13, color: Color(0xFFFFD700)),
                                const SizedBox(width: 3),
                                Text('${partner['rating'] ?? '4.9'} • ${partner['completedProjects'] ?? 0} shoots', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                              ]),
                            ]),
                          ),
                          if (status == 'EN_ROUTE' || status == 'ARRIVED')
                            GestureDetector(
                              onTap: () => context.push('/tracking/${widget.bookingId}'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: OrbitClientTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Package Summary ──────────────────────────────────────
                  OrbitGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('BOOKING DETAILS', style: OrbitClientTheme.textTheme.labelSmall),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Package', value: pkg['name'] ?? ''),
                      _DetailRow(label: 'Location', value: _booking?['address'] ?? ''),
                      _DetailRow(label: 'Time Slot', value: _booking?['timeSlot'] ?? ''),
                      _DetailRow(label: 'Booking ID', value: '#${widget.bookingId.substring(0, 8).toUpperCase()}'),
                    ]),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // ── Status Timeline ──────────────────────────────────────
                  if (_history.isNotEmpty) ...[
                    OrbitGlassCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('TIMELINE', style: OrbitClientTheme.textTheme.labelSmall),
                        const SizedBox(height: 16),
                        ..._history.reversed.take(8).toList().asMap().entries.map((e) =>
                          _TimelineItem(entry: e.value, isLast: e.key == 0),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PAID': return Icons.payment;
      case 'DISPATCHING': case 'PARTNER_OFFERED': return Icons.search;
      case 'PARTNER_ASSIGNED': return Icons.person_pin;
      case 'EN_ROUTE': return Icons.directions_car;
      case 'ARRIVED': return Icons.location_on;
      case 'SHOOTING': return Icons.videocam;
      case 'UPLOADING': case 'SYNCED': return Icons.cloud_upload;
      case 'EDITING': return Icons.movie_creation;
      case 'DELIVERED': return Icons.check_circle;
      case 'CANCELLED': return Icons.cancel;
      default: return Icons.info_outline;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'PAID': return 'Payment successful! Finding a partner near you.';
      case 'DISPATCHING': return 'Searching for available partners in your area.';
      case 'PARTNER_OFFERED': return 'Notifying partners. Waiting for acceptance.';
      case 'PARTNER_ASSIGNED': return 'A partner has been assigned. They\'re on their way!';
      case 'EN_ROUTE': return 'Your partner is heading to your location.';
      case 'ARRIVED': return 'Your partner has arrived at the location.';
      case 'SHOOTING': return 'Your shoot is in progress!';
      case 'UPLOADING': case 'SYNCED': return 'Your footage is being uploaded for editing.';
      case 'EDITING': return 'Our editors are working on your reel.';
      case 'DELIVERED': return '🎉 Your ORBIT reel is ready to download!';
      case 'CANCELLED': return 'This booking has been cancelled.';
      default: return 'Processing your booking...';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline))),
          Expanded(child: Text(value, style: OrbitClientTheme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isLast;
  const _TimelineItem({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final status = entry['toStatus'] as String? ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isLast ? OrbitClientTheme.primaryGradient : null,
                color: isLast ? null : OrbitClientTheme.outline,
              ),
            ),
            if (entry != null)
              Container(width: 1, height: 28, color: OrbitClientTheme.outlineVariant),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              status.replaceAll('_', ' '),
              style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                color: isLast ? OrbitClientTheme.onSurface : OrbitClientTheme.onSurfaceVariant,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
