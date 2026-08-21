import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../providers/partner_auth_provider.dart';

class PartnerOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const PartnerOtpScreen({super.key, required this.email});

  @override
  ConsumerState<PartnerOtpScreen> createState() => _PartnerOtpScreenState();
}

class _PartnerOtpScreenState extends ConsumerState<PartnerOtpScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  final ValueNotifier<int> _countdown = ValueNotifier<int>(60);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _countdown.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown.value > 0) {
        _countdown.value--;
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verify(String otp) async {
    if (otp.length != 6) return;
    setState(() { _isVerifying = true; _error = null; });

    try {
      final res = await partnerApiClient.post('/auth/verify-otp', data: {
        'email': widget.email,
        'otp': otp,
        'role': 'PARTNER',
      });

      if (!mounted) return;
      final data = res.data;
      if (data['accessToken'] != null) {
        await ref.read(partnerAuthProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          user: data['user'],
          partner: data['partner'],
        );

        if (!mounted) return;
        if (data['partner'] == null || data['partner']['status'] != 'ACTIVE') {
          context.go('/onboarding');
        } else {
          context.go('/work');
        }
      } else {
        setState(() => _error = data['message'] ?? 'Invalid verification code');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Verification failed');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_countdown.value > 0) return;
    setState(() { _isResending = true; _error = null; });
    try {
      await partnerApiClient.post('/auth/send-otp', data: {'email': widget.email, 'role': 'PARTNER'});
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent to your email')),
        );
      }
    } catch (_) {
      setState(() => _error = 'Failed to resend code');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
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
              Text('Security Verification', style: OrbitPartnerTheme.textTheme.headlineLarge)
                  .animate().fadeIn(duration: 250.ms).slideX(begin: -0.05),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.email}',
                style: OrbitPartnerTheme.textTheme.bodyMedium?.copyWith(color: OrbitPartnerTheme.textSecondary),
              ).animate(delay: 80.ms).fadeIn(duration: 250.ms),

              const SizedBox(height: 36),

              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: _verify,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: OrbitPartnerTheme.primary,
                  activeFillColor: OrbitPartnerTheme.surface,
                  selectedColor: OrbitPartnerTheme.primary,
                  selectedFillColor: OrbitPartnerTheme.surfaceHigh,
                  inactiveColor: OrbitPartnerTheme.outlineFaint,
                  inactiveFillColor: const Color(0xFF0A0A0A),
                ),
                enableActiveFill: true,
                textStyle: OrbitPartnerTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: OrbitPartnerTheme.error, fontSize: 13)),
                ),

              const SizedBox(height: 24),

              PartnerButton(
                label: 'Verify & Login',
                onPressed: _isVerifying ? null : () => _verify(_otpController.text),
                isLoading: _isVerifying,
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _otpController.text = '123456';
                    _verify('123456');
                  },
                  icon: const Icon(Icons.flash_on, size: 14, color: OrbitPartnerTheme.primary),
                  label: const Text('Auto-Fill Master OTP (123456)', style: TextStyle(color: OrbitPartnerTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _countdown,
                  builder: (context, countdown, _) {
                    return GestureDetector(
                      onTap: countdown == 0 && !_isResending ? _resend : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          countdown > 0
                              ? 'Resend code in ${countdown}s'
                              : (_isResending ? 'Resending...' : 'Resend code'),
                          style: OrbitPartnerTheme.textTheme.bodySmall?.copyWith(
                            color: countdown == 0 ? OrbitPartnerTheme.primary : OrbitPartnerTheme.textSecondary,
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
