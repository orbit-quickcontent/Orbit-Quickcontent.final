import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await partnerApiClient.post('/auth/send-otp', data: {'email': email, 'role': 'PARTNER'});
      if (!mounted) return;
      if (res.data['success'] == true) {
        context.push('/otp', extra: email);
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Network error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── Logo ───────────────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: OrbitPartnerTheme.partnerGradient,
                    boxShadow: [BoxShadow(color: OrbitPartnerTheme.primary.withOpacity(0.3), blurRadius: 12)],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icon/orbit_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.radio_button_checked, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('ORBIT', style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.4)),
                    color: OrbitPartnerTheme.primary.withOpacity(0.08),
                  ),
                  child: Text('PARTNER', style: OrbitPartnerTheme.textTheme.labelSmall?.copyWith(color: OrbitPartnerTheme.primary, letterSpacing: 2)),
                ),
              ]).animate().fadeIn(duration: 500.ms),

              const Spacer(flex: 1),

              // ── Hero ────────────────────────────────────────────────────────
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: OrbitPartnerTheme.textTheme.bodyLarge?.copyWith(color: OrbitPartnerTheme.textSecondary))
                    .animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                Text('Professional', style: OrbitPartnerTheme.textTheme.displayLarge)
                    .animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
                Text(
                  'Sign in to access available work, track your earnings, and manage your ORBIT portfolio.',
                  style: OrbitPartnerTheme.textTheme.bodyMedium?.copyWith(color: OrbitPartnerTheme.textSecondary),
                ).animate(delay: 200.ms).fadeIn(),
              ]),

              const SizedBox(height: 40),

              // ── Email ────────────────────────────────────────────────────────
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('EMAIL', style: OrbitPartnerTheme.textTheme.labelSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendOtp(),
                  style: OrbitPartnerTheme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'partner@email.com',
                    prefixIcon: const Icon(Icons.mail_outline, size: 18, color: OrbitPartnerTheme.textSecondary),
                    errorText: _error,
                    errorStyle: TextStyle(color: OrbitPartnerTheme.error),
                  ),
                ),
              ]).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              PartnerButton(
                label: 'Continue',
                onPressed: _isLoading ? null : _sendOtp,
                isLoading: _isLoading,
              ).animate(delay: 350.ms).fadeIn(),

              const SizedBox(height: 20),

              // Trust indicators
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OnlineStatusDot(isOnline: true),
                const SizedBox(width: 6),
                Text('Trusted by 500+ professional videographers', style: OrbitPartnerTheme.textTheme.bodySmall),
              ]).animate(delay: 400.ms).fadeIn(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
