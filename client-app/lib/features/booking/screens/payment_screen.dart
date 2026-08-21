import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const PaymentScreen({super.key, required this.params});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isConfirming = false;

  Future<void> _confirmAndProceed() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    final bookingId = widget.params['bookingId'] as String;
    final paymentId = 'pay_direct_${DateTime.now().millisecondsSinceEpoch}';

    try {
      await apiClient.post('/bookings/$bookingId/confirm-payment', data: {
        'paymentId': paymentId,
      });

      if (!mounted) return;
      context.pushReplacement('/finding-partner', extra: bookingId);
    } catch (_) {
      if (mounted) {
        context.pushReplacement('/finding-partner', extra: bookingId);
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.params['package'] as Map<String, dynamic>? ?? {};
    final priceDisplay = package['priceDisplay'] ?? 999;
    final packageName = package['name'] ?? 'Professional Shoot';

    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => context.pop()),
        title: Text('Confirm Booking', style: OrbitClientTheme.textTheme.headlineMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Confirmation amount card
            OrbitGlassCard(
              child: Column(
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b),
                    child: const Icon(Icons.check_circle_outline, size: 44, color: Colors.white),
                  )
                  .animate().scale(duration: 300.ms, curve: Curves.easeOutCubic).fadeIn(duration: 250.ms),
                  const SizedBox(height: 16),
                  Text('Booking Confirmation', style: OrbitClientTheme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('$packageName Package', style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  Text(
                    '₹$priceDisplay',
                    style: OrbitClientTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      foreground: Paint()..shader = OrbitClientTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, 200, 60)),
                    ),
                  ).animate(delay: 80.ms).fadeIn(duration: 250.ms),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.verified_outlined, size: 14, color: OrbitClientTheme.success),
                    const SizedBox(width: 6),
                    Text('Direct Instant Booking Enabled', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.success)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),

            OrbitGradientButton(
              label: 'Confirm & Dispatch Videographer',
              onPressed: _isConfirming ? null : _confirmAndProceed,
              isLoading: _isConfirming,
            ),
            const SizedBox(height: 16),

            Text(
              'By confirming you agree to ORBIT\'s Terms & Privacy Policy',
              style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
