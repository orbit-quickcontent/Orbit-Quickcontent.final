import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const PaymentScreen({super.key, required this.params});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Razorpay _razorpay;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    // Auto-launch payment sheet
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchPayment());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _launchPayment() {
    final payment = widget.params['payment'] as Map<String, dynamic>;
    final package = widget.params['package'] as Map<String, dynamic>;

    setState(() => _isLaunching = true);

    final options = {
      'key': payment['keyId'],
      'amount': payment['amount'],
      'currency': payment['currency'],
      'name': 'ORBIT',
      'description': '${package['name']} Package',
      'order_id': payment['orderId'],
      'prefill': {'email': '', 'contact': ''},
      'theme': {'color': '#47D6FF', 'backdrop_color': '#131313'},
    };

    _razorpay.open(options);
    setState(() => _isLaunching = false);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final bookingId = widget.params['bookingId'] as String;
    context.pushReplacement('/finding-partner', extra: bookingId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: OrbitClientTheme.errorContainer,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  Widget build(BuildContext context) {
    final package = widget.params['package'] as Map<String, dynamic>;
    final payment = widget.params['payment'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => context.pop()),
        title: Text('Payment', style: OrbitClientTheme.textTheme.headlineMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Payment amount card
            OrbitGlassCard(
              child: Column(
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b),
                    child: const Icon(Icons.lock_outline, size: 40, color: Colors.white),
                  )
                  .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text('Secure Payment', style: OrbitClientTheme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('${package['name']} Package', style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  Text(
                    '₹${package['priceDisplay']}',
                    style: OrbitClientTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      foreground: Paint()..shader = OrbitClientTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, 200, 60)),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: OrbitClientTheme.success),
                    const SizedBox(width: 6),
                    Text('Secured by Razorpay', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.success)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),

            OrbitGradientButton(
              label: 'Pay ₹${package['priceDisplay']}',
              onPressed: _isLaunching ? null : _launchPayment,
              isLoading: _isLaunching,
            ),
            const SizedBox(height: 16),

            Text(
              'By paying you agree to ORBIT\'s Terms & Privacy Policy',
              style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
