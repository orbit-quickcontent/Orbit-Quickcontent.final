import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import 'package:dio/dio.dart';

class BookingReviewScreen extends StatelessWidget {
  final Map<String, dynamic> params;
  const BookingReviewScreen({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final packageId = params['packageId'] as String;
    final latitude = params['latitude'] as double;
    final longitude = params['longitude'] as double;
    final address = params['address'] as String;

    return _ReviewBody(packageId: packageId, latitude: latitude, longitude: longitude, address: address);
  }
}

class _ReviewBody extends StatefulWidget {
  final String packageId;
  final double latitude, longitude;
  final String address;
  const _ReviewBody({required this.packageId, required this.latitude, required this.longitude, required this.address});

  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  Map<String, dynamic>? _package;
  DateTime _bookingDate = DateTime.now().add(const Duration(hours: 1));
  String _selectedSlot = 'Immediate';
  bool _isLoading = false;
  bool _isSubmitting = false;

  final _slots = ['Immediate', 'Morning (9AM-12PM)', 'Afternoon (12PM-5PM)', 'Evening (5PM-9PM)'];

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    try {
      final res = await apiClient.get('/packages');
      final pkgs = List<Map<String, dynamic>>.from(res.data);
      setState(() => _package = pkgs.firstWhere((p) => p['id'] == widget.packageId));
    } catch (_) {}
  }

  Future<void> _createBooking() async {
    if (_package == null) return;
    setState(() => _isSubmitting = true);

    try {
      final res = await apiClient.post('/bookings', data: {
        'packageId': widget.packageId,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'address': widget.address,
        'bookingDate': _bookingDate.toIso8601String(),
        'timeSlot': _selectedSlot,
      });

      if (!mounted) return;
      final data = res.data;
      context.push('/payment', extra: {
        'bookingId': data['booking']['id'],
        'payment': data['payment'],
        'package': _package,
      });
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['error'] ?? 'Failed to create booking')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => context.pop()),
        title: Text('Review Booking', style: OrbitClientTheme.textTheme.headlineMedium),
      ),
      body: _package == null
          ? const Center(child: CircularProgressIndicator(color: OrbitClientTheme.primaryFixed))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Package summary
                OrbitGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b), child: const Icon(Icons.videocam, size: 24, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_package!['name'] ?? '', style: OrbitClientTheme.textTheme.titleLarge)),
                        Text('₹${_package!['priceDisplay']}', style: OrbitClientTheme.textTheme.headlineMedium?.copyWith(
                          foreground: Paint()..shader = OrbitClientTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, 100, 32)),
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Text(_package!['focus'] ?? '', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 16),

                // Location
                OrbitGlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('LOCATION', style: OrbitClientTheme.textTheme.labelSmall),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, color: OrbitClientTheme.primaryFixed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.address, style: OrbitClientTheme.textTheme.bodySmall)),
                    ]),
                  ]),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 16),

                // Time slot
                OrbitGlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TIME SLOT', style: OrbitClientTheme.textTheme.labelSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _slots.map((slot) => GestureDetector(
                        onTap: () => setState(() => _selectedSlot = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: _selectedSlot == slot ? OrbitClientTheme.primaryGradient : null,
                            color: _selectedSlot != slot ? OrbitClientTheme.surfaceHigh : null,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _selectedSlot == slot ? Colors.transparent : OrbitClientTheme.outlineVariant),
                          ),
                          child: Text(slot, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                            color: _selectedSlot == slot ? Colors.white : OrbitClientTheme.onSurfaceVariant,
                            fontWeight: _selectedSlot == slot ? FontWeight.w600 : FontWeight.w400,
                          )),
                        ),
                      )).toList(),
                    ),
                  ]),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Price breakdown
                OrbitGlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PRICE BREAKDOWN', style: OrbitClientTheme.textTheme.labelSmall),
                    const SizedBox(height: 12),
                    _PriceRow(label: 'Package Fee', value: '₹${_package!['priceDisplay']}'),
                    _PriceRow(label: 'Platform Fee', value: 'Included'),
                    _PriceRow(label: 'Editing & Delivery', value: 'Included'),
                    const Divider(color: OrbitClientTheme.outlineVariant, height: 20),
                    _PriceRow(
                      label: 'Total',
                      value: '₹${_package!['priceDisplay']}',
                      isBold: true,
                      valueColor: OrbitClientTheme.primaryFixed,
                    ),
                  ]),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 28),

                OrbitGradientButton(
                  label: 'Proceed to Payment',
                  onPressed: _isSubmitting ? null : _createBooking,
                  isLoading: _isSubmitting,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  final Color? valueColor;
  const _PriceRow({required this.label, required this.value, this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          )),
          Text(value, style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: valueColor,
          )),
        ],
      ),
    );
  }
}
