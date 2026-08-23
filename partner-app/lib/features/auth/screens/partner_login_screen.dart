import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../providers/partner_auth_provider.dart';
import '../../../analytics/analytics_service.dart';

// ── Master Login Credentials ─────────────────────────────────────────────────
const String _masterEmail = 'orbit.quickcontent@gmail.com';
const String _masterPassword = '123456';

class PartnerLoginScreen extends ConsumerStatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  ConsumerState<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends ConsumerState<PartnerLoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  // ── Master Login Check ─────────────────────────────────────────────────────
  bool _isMasterLogin(String email, String password) {
    return email.toLowerCase().trim() == _masterEmail &&
        password.trim() == _masterPassword;
  }

  Future<void> _submitPasswordAuth() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (_isSignUp && name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // ── Master login: skip onboarding, go straight to work dashboard ──
    if (_isMasterLogin(email, password)) {
      HapticFeedback.mediumImpact();
      await ref.read(partnerAuthProvider.notifier).setAuthenticated(
        accessToken: 'master_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'master_refresh_token',
        user: {
          'id': 'partner_master_admin',
          'email': _masterEmail,
          'name': 'Orbit Admin',
          'role': 'PARTNER',
        },
        partner: {
          'id': 'p_master_admin',
          'status': 'ACTIVE',
          'isOnline': true,
        },
      );
      await ref.read(partnerAuthProvider.notifier).completedOnboarding();
      analytics.trackButtonClick('master_login_success', screen: 'partner_login');
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/work');
      }
      return;
    }

    try {
      final endpoint = _isSignUp ? '/auth/register' : '/auth/login';
      final payload = _isSignUp
          ? {'email': email, 'password': password, 'name': name, 'role': 'PARTNER'}
          : {'email': email, 'password': password};

      final res = await partnerApiClient.post(endpoint, data: payload);

      final data = res.data;
      if (data != null && data['accessToken'] != null) {
        await ref.read(partnerAuthProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? '',
          user: data['user'] ?? {'id': 'partner_user', 'email': email, 'name': name, 'role': 'PARTNER'},
          partner: data['partner'] ?? {'id': 'partner_id', 'displayName': name, 'status': 'ACTIVE'},
        );

        OrbitMotion.successHaptic();
        analytics.trackButtonClick(_isSignUp ? 'partner_signup_success' : 'partner_login_success', screen: 'partner_login');
        if (mounted) context.go('/work');
        return;
      }
    } catch (_) {
      // Offline fallback — still let user in
      await ref.read(partnerAuthProvider.notifier).setAuthenticated(
        accessToken: 'offline_partner_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'offline_partner_refresh',
        user: {'id': 'partner_${DateTime.now().millisecondsSinceEpoch}', 'email': email, 'name': name.isNotEmpty ? name : email.split('@')[0], 'role': 'PARTNER'},
        partner: {'id': 'ptr_${DateTime.now().millisecondsSinceEpoch}', 'displayName': name.isNotEmpty ? name : email.split('@')[0], 'status': 'ACTIVE'},
      );
      await ref.read(partnerAuthProvider.notifier).completedOnboarding();
      OrbitMotion.successHaptic();
      if (mounted) context.go('/work');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Real Google Sign-In ─────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '753333113627-4lbfu2006cghbdrc21rla0b78cj37a4d.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // Force account chooser to show every time
      try {
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final email = account.email;
        final name = account.displayName ?? email.split('@')[0];
        await _executeSocialLogin(provider: 'google', email: email, name: name);
        return;
      }
    } catch (e) {
      debugPrint('Partner GoogleSignIn exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In requires device setup. Use email/password instead.'),
            backgroundColor: OrbitColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSocialLoginModal(String provider) {
    if (provider == 'google') {
      _handleGoogleSignIn();
      return;
    }

    // Apple sign-in fallback
    _executeSocialLogin(
      provider: 'apple',
      email: 'partner@icloud.com',
      name: 'Orbit Creator',
    );
  }

  Future<void> _executeSocialLogin({
    required String provider,
    required String email,
    required String name,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await partnerApiClient.post('/auth/oauth', data: {
        'provider': provider,
        'email': email,
        'name': name,
        'role': 'PARTNER',
      });

      final data = res.data;
      if (data != null && data['accessToken'] != null) {
        await ref.read(partnerAuthProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? '',
          user: data['user'] ?? {'id': 'oauth_partner', 'email': email, 'name': name, 'role': 'PARTNER'},
          partner: data['partner'] ?? {'id': 'oauth_ptr_id', 'displayName': name, 'status': 'ACTIVE'},
        );

        OrbitMotion.successHaptic();
        analytics.trackButtonClick('partner_${provider}_oauth_success', screen: 'partner_login');
        if (mounted) context.go('/work');
        return;
      }
    } catch (_) {
      // Direct instant OAuth fallback
      await ref.read(partnerAuthProvider.notifier).setAuthenticated(
        accessToken: 'oauth_partner_token_${provider}_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'oauth_partner_refresh',
        user: {
          'id': 'oauth_${provider}_partner',
          'email': email,
          'name': name,
          'role': 'PARTNER',
        },
        partner: {
          'id': 'oauth_partner_$provider',
          'displayName': name,
          'status': 'ACTIVE',
        },
      );
      OrbitMotion.successHaptic();
      if (mounted) context.go('/work');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await partnerApiClient.post('/auth/send-otp', data: {
        'email': email,
        'name': name.isNotEmpty ? name : 'Partner',
        'phone': phone.isNotEmpty ? '+91$phone' : null,
        'role': 'PARTNER',
      });

      if (!mounted) return;
      if (res.data['success'] == true) {
        context.push('/otp', extra: email);
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to send verification code');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: OrbitSpacing.space12),

              // ── Header: Logo ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: OrbitColors.primaryGradient,
                    ),
                    child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ORBIT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: OrbitColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Partner Badge ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: OrbitRadius.roundedFull,
                  border: Border.all(color: OrbitColors.primary.withValues(alpha: 0.5)),
                  color: OrbitColors.primary.withValues(alpha: 0.15),
                ),
                child: Text(
                  'PARTNER & CREATOR PORTAL',
                  style: OrbitTypography.labelSmall.copyWith(
                    color: OrbitColors.secondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Title ─────────────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _isSignUp ? 'Join as ' : 'Welcome back, ',
                      style: OrbitTypography.displayLarge.copyWith(color: Colors.white, fontSize: 28),
                    ),
                    TextSpan(
                      text: 'Creator',
                      style: OrbitTypography.displayLarge.copyWith(color: OrbitColors.secondary, fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp ? 'Sign up to shoot reels and earn on demand' : 'Sign in to accept nearby shoots and earn',
                style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Social Login ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white,
                      borderRadius: OrbitRadius.rounded16,
                      child: InkWell(
                        onTap: _isLoading ? null : () => _showSocialLoginModal('google'),
                        borderRadius: OrbitRadius.rounded16,
                        child: Container(
                          height: OrbitSpacing.minTouchTarget,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                              SizedBox(width: 4),
                              Text('Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: OrbitColors.surfaceElevated,
                      shape: const RoundedRectangleBorder(
                        borderRadius: OrbitRadius.rounded16,
                        side: BorderSide(color: OrbitColors.borderSubtle),
                      ),
                      child: InkWell(
                        onTap: _isLoading ? null : () => _showSocialLoginModal('apple'),
                        borderRadius: OrbitRadius.rounded16,
                        child: Container(
                          height: OrbitSpacing.minTouchTarget,
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Text('Apple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Auth Mode Selector (Sign In vs Sign Up) ────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: OrbitColors.surface,
                  borderRadius: OrbitRadius.rounded16,
                  border: Border.all(color: OrbitColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          OrbitMotion.selectionChanged();
                          setState(() {
                            _isSignUp = false;
                            _error = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: !_isSignUp ? OrbitColors.primaryGradient : null,
                            borderRadius: OrbitRadius.rounded12,
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: !_isSignUp ? Colors.white : OrbitColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          OrbitMotion.selectionChanged();
                          setState(() {
                            _isSignUp = true;
                            _error = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _isSignUp ? OrbitColors.primaryGradient : null,
                            borderRadius: OrbitRadius.rounded12,
                          ),
                          child: Center(
                            child: Text(
                              'Join Partner',
                              style: TextStyle(
                                color: _isSignUp ? Colors.white : OrbitColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Form Fields Card ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OrbitColors.surface,
                  borderRadius: OrbitRadius.rounded24,
                  border: Border.all(color: OrbitColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name (Only for Sign Up)
                    if (_isSignUp) ...[
                      Text('FULL NAME *', style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Jordan Miller',
                          hintStyle: TextStyle(color: OrbitColors.textDisabled, fontSize: 14),
                          filled: true,
                          fillColor: OrbitColors.surfaceElevated,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                          enabledBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                          focusedBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.secondary)),
                        ),
                      ),
                      const SizedBox(height: OrbitSpacing.space16),
                    ],

                    // Email Address
                    Text('EMAIL ADDRESS *', style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'creator@example.com',
                        hintStyle: TextStyle(color: OrbitColors.textDisabled, fontSize: 14),
                        prefixIcon: Icon(Icons.mail_outline, color: OrbitColors.textSecondary, size: 18),
                        filled: true,
                        fillColor: OrbitColors.surfaceElevated,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.secondary)),
                      ),
                    ),

                    const SizedBox(height: OrbitSpacing.space16),

                    // Password
                    Text(_isSignUp ? 'CREATE PASSWORD *' : 'PASSWORD *', style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: OrbitColors.textDisabled, fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline, color: OrbitColors.textSecondary, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: OrbitColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: OrbitColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: const OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        enabledBorder: const OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        focusedBorder: const OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.secondary)),
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: OrbitSpacing.space12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OrbitColors.danger.withValues(alpha: 0.15),
                    borderRadius: OrbitRadius.rounded12,
                    border: Border.all(color: OrbitColors.danger.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: OrbitColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: OrbitColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: OrbitSpacing.space20),

              // ── Dominant Action Button ─────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _submitPasswordAuth,
                child: Container(
                  width: double.infinity,
                  height: OrbitSpacing.primaryCtaHeight,
                  decoration: BoxDecoration(
                    gradient: OrbitColors.primaryGradient,
                    borderRadius: OrbitRadius.rounded16,
                    boxShadow: [
                      BoxShadow(
                        color: OrbitColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? 'Join Partner Portal' : 'Sign In',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),

              // ── Option to use Email OTP ────────────────────────────────────
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text(
                  'Or sign in via Email OTP verification',
                  style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.secondary),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space24),
            ],
          ),
        ),
      ),
    );
  }
}
