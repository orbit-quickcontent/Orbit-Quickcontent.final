import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await apiClient.get('/bookings', params: {'limit': '50'});
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(res.data['bookings'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED': case 'PAYOUT_COMPLETED': return OrbitClientTheme.success;
      case 'PARTNER_ASSIGNED': case 'EN_ROUTE': case 'SHOOTING': case 'EDITING': return OrbitClientTheme.primaryFixed;
      case 'CANCELLED': case 'FAILED': return OrbitClientTheme.error;
      default: return OrbitClientTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('My Bookings', style: OrbitClientTheme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: OrbitClientTheme.primaryFixed))
          : _bookings.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b), child: const Icon(Icons.history, size: 64, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: OrbitClientTheme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Your booking history will appear here', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  OrbitGradientButton(label: 'Book Now', onPressed: () => context.push('/packages'), width: 160, height: 44),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: OrbitClientTheme.primaryFixed,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final b = _bookings[i];
                      final pkg = b['package'] as Map<String, dynamic>? ?? {};
                      final status = b['status'] as String? ?? '';
                      return GestureDetector(
                        onTap: () => context.push('/booking/${b['id']}'),
                        child: OrbitGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(status).withOpacity(0.1), border: Border.all(color: _statusColor(status).withOpacity(0.3))),
                              child: Icon(status == 'DELIVERED' ? Icons.play_circle_outline : Icons.videocam_outlined, color: _statusColor(status), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(pkg['name'] ?? '', style: OrbitClientTheme.textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(b['address'] ?? '', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              OrbitStatusChip(label: status.replaceAll('_', ' '), color: _statusColor(status), backgroundColor: _statusColor(status).withOpacity(0.1)),
                              const SizedBox(height: 4),
                              Text('₹${pkg['priceDisplay'] ?? ''}', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
