import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await apiClient.post('/auth/send-otp', data: {'email': email});
      if (!mounted) return;
      if (res.data['success'] == true) {
        context.push('/otp', extra: email);
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ── ORBIT Logo ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: OrbitClientTheme.primaryGradient,
                    ),
                    child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ORBIT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      foreground: Paint()
                        ..shader = OrbitClientTheme.primaryGradient.createShader(
                          const Rect.fromLTWH(0, 0, 120, 40),
                        ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 16),

              // ── Client Account Badge ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: OrbitClientTheme.primaryFixed.withOpacity(0.3)),
                  color: OrbitClientTheme.primaryFixed.withOpacity(0.08),
                ),
                child: Text(
                  'CLIENT ACCOUNT',
                  style: OrbitClientTheme.textTheme.labelSmall?.copyWith(
                    color: OrbitClientTheme.primaryFixed,
                    letterSpacing: 2,
                  ),
                ),
              ).animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 40),

              // ── Hero Text ──────────────────────────────────────────────────
              Text(
                'Join the',
                style: OrbitClientTheme.textTheme.displayLarge?.copyWith(
                  color: OrbitClientTheme.primaryFixed,
                  fontSize: 36,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => OrbitClientTheme.primaryGradient.createShader(bounds),
                child: Text(
                  'Orbit',
                  style: OrbitClientTheme.textTheme.displayLarge?.copyWith(fontSize: 36),
                ),
              ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 8),

              Text(
                'Sign in or create your account to get started',
                style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(
                  color: OrbitClientTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 48),

              // ── Email Input ────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMAIL ADDRESS',
                    style: OrbitClientTheme.textTheme.labelSmall?.copyWith(
                      color: OrbitClientTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendOtp(),
                    style: OrbitClientTheme.textTheme.bodyMedium?.copyWith(
                      color: OrbitClientTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: Icon(Icons.mail_outline, color: OrbitClientTheme.outline, size: 20),
                      errorText: _error,
                      errorStyle: TextStyle(color: OrbitClientTheme.error),
                    ),
                  ),
                ],
              ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.15),

              const SizedBox(height: 28),

              // ── CTA Button ────────────────────────────────────────────────
              OrbitGradientButton(
                label: 'Continue with Email',
                onPressed: _isLoading ? null : _sendOtp,
                isLoading: _isLoading,
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.15),

              const SizedBox(height: 32),

              // ── Divider ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: OrbitClientTheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'SECURE LOGIN',
                      style: OrbitClientTheme.textTheme.labelSmall?.copyWith(
                        color: OrbitClientTheme.outline,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: OrbitClientTheme.outlineVariant)),
                ],
              ).animate(delay: 450.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Privacy Note ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: OrbitClientTheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Your data is encrypted & secure',
                    style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                      color: OrbitClientTheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
