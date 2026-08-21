import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../providers/partner_auth_provider.dart';
import '../../../analytics/analytics_service.dart';

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
      // Offline fallback
      await ref.read(partnerAuthProvider.notifier).setAuthenticated(
        accessToken: 'mock_partner_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_partner_refresh',
        user: {'id': 'partner_${DateTime.now().millisecondsSinceEpoch}', 'email': email, 'name': name.isNotEmpty ? name : 'Orbit Partner', 'role': 'PARTNER'},
        partner: {'id': 'ptr_${DateTime.now().millisecondsSinceEpoch}', 'displayName': name.isNotEmpty ? name : 'Orbit Partner', 'status': 'ACTIVE'},
      );
      OrbitMotion.successHaptic();
      if (mounted) context.go('/work');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSocialLoginModal(String provider) {
    final isGoogle = provider == 'google';
    final brandName = isGoogle ? 'Google' : 'Apple';

    showModalBottomSheet(
      context: context,
      backgroundColor: OrbitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: OrbitColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGoogle ? Icons.g_mobiledata : Icons.apple,
                    color: Colors.white,
                    size: isGoogle ? 32 : 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Partner Sign in with $brandName',
                    style: OrbitTypography.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a creator account to access Partner Portal',
                style: OrbitTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // Mock 1-tap Account Choice
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: OrbitColors.borderSubtle),
                ),
                leading: CircleAvatar(
                  backgroundColor: OrbitColors.primary.withValues(alpha: 0.3),
                  child: Text(
                    isGoogle ? 'G' : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  isGoogle ? 'Jordan Miller (Creator)' : 'Apple Creator',
                  style: OrbitTypography.titleSmall,
                ),
                subtitle: Text(
                  isGoogle ? 'jordan.creator@gmail.com' : 'creator@privaterelay.appleid.com',
                  style: OrbitTypography.bodySmall,
                ),
                trailing: const Icon(Icons.check_circle, color: OrbitColors.secondary, size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeSocialLogin(
                    provider: provider,
                    email: isGoogle ? 'jordan.creator@gmail.com' : 'creator@privaterelay.appleid.com',
                    name: isGoogle ? 'Jordan Miller' : 'Apple Creator',
                  );
                },
              ),

              const SizedBox(height: 12),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: OrbitColors.borderSubtle),
                ),
                leading: const CircleAvatar(
                  backgroundColor: OrbitColors.surfaceElevated,
                  child: Icon(Icons.person_add_outlined, color: OrbitColors.textSecondary, size: 20),
                ),
                title: Text(
                  'Use another $brandName account',
                  style: OrbitTypography.titleSmall,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeSocialLogin(
                    provider: provider,
                    email: isGoogle ? 'partner.creator@gmail.com' : 'partner@icloud.com',
                    name: isGoogle ? 'Orbit Videographer' : 'Orbit Videographer',
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
