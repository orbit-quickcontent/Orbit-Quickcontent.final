import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  final ValueNotifier<int> _resendCountdown = ValueNotifier<int>(60);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendCountdown.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _resendCountdown.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown.value > 0) {
        _resendCountdown.value--;
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;
    setState(() { _isVerifying = true; _error = null; });

    try {
      final res = await apiClient.post('/auth/verify-otp', data: {
        'email': widget.email,
        'otp': otp,
      });

      if (!mounted) return;
      final data = res.data;
      if (data['accessToken'] != null) {
        await ref.read(authStateProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          user: data['user'],
        );
        if (mounted) context.go('/personal-info');
      } else {
        setState(() => _error = data['message'] ?? 'Invalid OTP');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Verification failed');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown.value > 0) return;
    setState(() { _isResending = true; _error = null; });

    try {
      await apiClient.post('/auth/send-otp', data: {'email': widget.email});
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? 'Failed to resend OTP');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: OrbitClientTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: OrbitClientTheme.primaryFixed.withValues(alpha: 0.3), blurRadius: 16)],
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 28),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              Text('Verify your email', style: OrbitClientTheme.textTheme.headlineLarge)
                  .animate(delay: 60.ms).fadeIn(duration: 250.ms).slideX(begin: -0.05),
              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  style: OrbitClientTheme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(color: OrbitClientTheme.primaryFixed, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 250.ms),

              const SizedBox(height: 36),

              // Pin code input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor: OrbitClientTheme.primaryFixed,
                  selectedColor: OrbitClientTheme.primaryFixed,
                  inactiveColor: OrbitClientTheme.outlineVariant,
                  activeFillColor: OrbitClientTheme.surfaceHigh,
                  selectedFillColor: OrbitClientTheme.surfaceHigh,
                  inactiveFillColor: OrbitClientTheme.surfaceHigh,
                ),
                enableActiveFill: true,
                cursorColor: OrbitClientTheme.primaryFixed,
                textStyle: const TextStyle(
                  color: OrbitClientTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (_) => setState(() => _error = null),
                onCompleted: _verifyOtp,
              ),

              const SizedBox(height: 8),

              // Universal Sandbox Hint
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: OrbitClientTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OrbitClientTheme.outlineVariant),
                ),
                child: const Text(
                  'Development & Test Master Bypass OTP: 123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OrbitClientTheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: OrbitClientTheme.error, fontSize: 13)),
                ),

              const SizedBox(height: 24),

              // Verify button
              OrbitGradientButton(
                label: 'Verify Code',
                onPressed: _isVerifying ? null : () => _verifyOtp(_otpController.text),
                isLoading: _isVerifying,
              ),

              const SizedBox(height: 12),

              // Quick Auto-fill 123456 for instant testing
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _otpController.text = '123456';
                    _verifyOtp('123456');
                  },
                  icon: const Icon(Icons.flash_on, size: 14, color: OrbitClientTheme.primaryFixed),
                  label: const Text('Auto-Fill Master OTP (123456)', style: TextStyle(color: OrbitClientTheme.primaryFixed, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              // Resend Timer (Isolated with ValueListenableBuilder for zero re-render lag)
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _resendCountdown,
                  builder: (context, countdown, _) {
                    return GestureDetector(
                      onTap: countdown == 0 && !_isResending ? _resendOtp : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          countdown > 0
                              ? 'Resend code in ${countdown}s'
                              : (_isResending ? 'Resending...' : 'Resend OTP'),
                          style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                            color: countdown == 0 ? OrbitClientTheme.primaryFixed : OrbitClientTheme.outline,
                            fontWeight: countdown == 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
