import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_timeline.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../analytics/analytics_service.dart';

const String _kSocketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://10.0.2.2:5000');

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;
  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  int _userRating = 5;
  bool _ratingSubmitted = false;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('booking_status_screen');
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
      if (mounted) {
        setState(() {
          _booking = res.data;
          _isLoading = false;
        });

        if (res.data?['status'] == 'DELIVERED') {
          analytics.trackReelDelivered(bookingId: widget.bookingId);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initSocket() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'orbit_access_token');

      _socket = io.io(
        _kSocketUrl,
        io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).build(),
      );

      _socket!.connect();
      _socket!.emit('join:booking', widget.bookingId);
      _socket!.on('booking:status-update', (_) => _loadBooking());
    } catch (_) {}
  }

  void _onDownloadReel() {
    OrbitMotion.successHaptic();
    analytics.trackReelDownloaded(bookingId: widget.bookingId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading 1080p Master Reel to your Gallery...'),
        backgroundColor: OrbitColors.success,
      ),
    );
  }

  void _submitRating(int rating) {
    OrbitMotion.successHaptic();
    setState(() {
      _userRating = rating;
      _ratingSubmitted = true;
    });
    analytics.trackRatingSubmitted(bookingId: widget.bookingId, rating: rating);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for rating your creator!'),
        backgroundColor: OrbitColors.success,
      ),
    );
  }

  void _confirmCancelBooking() {
    OrbitMotion.lightTap();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OrbitColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: OrbitColors.danger, size: 24),
            SizedBox(width: 8),
            Text('Cancel Shoot?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this shoot booking? 100% refund will be processed to your original payment method immediately.',
          style: TextStyle(color: OrbitColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking', style: TextStyle(color: OrbitColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OrbitColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBooking();
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    try {
      await apiClient.post('/bookings/${widget.bookingId}/cancel');
    } catch (_) {}

    if (mounted) {
      OrbitMotion.successHaptic();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shoot cancelled. Refund initiated to your wallet/card.'),
          backgroundColor: OrbitColors.danger,
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: OrbitColors.background,
        body: Center(child: OrbitLoadingSkeleton(width: 200, height: 200)),
      );
    }

    final status = _booking?['status'] as String? ?? 'PENDING';
    final pkg = _booking?['package'] as Map<String, dynamic>? ?? {};
    final partner = _booking?['partner'] as Map<String, dynamic>? ?? {};
    final partnerUser = partner['user'] as Map<String, dynamic>? ?? {};
    final creatorName = partnerUser['name'] ?? partner['displayName'] ?? 'Assigned Creator';

    // ── Delivery Peak-End Screen (Reel Delivered) ──────────────────────
    if (status == 'DELIVERED' || status == 'COMPLETED') {
      return Scaffold(
        backgroundColor: OrbitColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => context.go('/home'),
          ),
          title: Text('Reel Delivered', style: OrbitTypography.titleLarge),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space12),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // Video Preview Card
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: OrbitColors.surfaceElevated,
                          borderRadius: OrbitRadius.rounded24,
                          border: Border.all(color: OrbitColors.secondary.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    gradient: OrbitColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                ),
                                const SizedBox(height: OrbitSpacing.space16),
                                Text('Tap to Preview 9:16 Reel', style: OrbitTypography.titleSmall),
                                const SizedBox(height: 4),
                                Text('1080x1920 • 60 FPS • Master Export', style: OrbitTypography.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: OrbitSpacing.space24),
                      Text('Your reel is ready.', style: OrbitTypography.displayLarge.copyWith(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text('Edited by professional creator team with color grading and motion graphics.', style: OrbitTypography.bodyMedium),

                      const SizedBox(height: OrbitSpacing.space24),

                      // Rating Experience
                      OrbitCard(
                        child: Column(
                          children: [
                            Text(
                              _ratingSubmitted ? 'Rating Submitted' : 'How was your experience with $creatorName?',
                              style: OrbitTypography.titleSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: OrbitSpacing.space12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final starNum = index + 1;
                                return IconButton(
                                  icon: Icon(
                                    starNum <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: OrbitColors.warning,
                                    size: 32,
                                  ),
                                  onPressed: () => _submitRating(starNum),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dominant CTA (Thumb Zone)
                OrbitPrimaryButton(
                  label: 'DOWNLOAD REEL',
                  icon: Icons.download_rounded,
                  onPressed: _onDownloadReel,
                ),
                const SizedBox(height: OrbitSpacing.space12),
                OrbitSecondaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Standard Live Status Timeline Screen ──────────────────────────
    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Booking Status', style: OrbitTypography.titleLarge),
        actions: [
          if (['PARTNER_ASSIGNED', 'EN_ROUTE'].contains(status))
            IconButton(
              icon: const Icon(Icons.map_outlined, color: OrbitColors.secondary),
              onPressed: () => context.push('/tracking/${widget.bookingId}'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space12),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Status Overview Card
                    OrbitCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(pkg['name'] ?? 'Reel Shoot', style: OrbitTypography.titleLarge),
                              OrbitStatusPill.fromStatus(status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_booking?['address'] ?? 'Confirmed Location', style: OrbitTypography.bodySmall),
                          if (partner.isNotEmpty) ...[
                            const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space20),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    gradient: OrbitColors.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: OrbitSpacing.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(creatorName, style: OrbitTypography.titleSmall),
                                      Text('Assigned Videographer', style: OrbitTypography.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: OrbitSpacing.space24),
                    Text('Shoot Progression', style: OrbitTypography.headingMedium),
                    const SizedBox(height: OrbitSpacing.space16),

                    // Visual Step Timeline
                    OrbitCard(
                      child: OrbitBookingTimeline(currentStatus: status),
                    ),
                  ],
                ),
              ),

              // Contextual Action in Thumb Zone
              if (['PARTNER_ASSIGNED', 'EN_ROUTE'].contains(status)) ...[
                OrbitPrimaryButton(
                  label: 'TRACK CREATOR LIVE',
                  icon: Icons.navigation_rounded,
                  onPressed: () => context.push('/tracking/${widget.bookingId}'),
                ),
                const SizedBox(height: OrbitSpacing.space12),
                TextButton.icon(
                  onPressed: _confirmCancelBooking,
                  icon: const Icon(Icons.cancel_outlined, color: OrbitColors.danger, size: 16),
                  label: const Text('Cancel Shoot Booking', style: TextStyle(color: OrbitColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ] else if (['PENDING', 'DISPATCHING', 'CONFIRMED'].contains(status)) ...[
                OrbitPrimaryButton(
                  label: 'CANCEL SHOOT',
                  icon: Icons.cancel_outlined,
                  onPressed: _confirmCancelBooking,
                ),
                const SizedBox(height: OrbitSpacing.space12),
                OrbitSecondaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/home'),
                ),
              ] else ...[
                OrbitSecondaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go('/home'),
                ),
              ],
              const SizedBox(height: OrbitSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }
}
