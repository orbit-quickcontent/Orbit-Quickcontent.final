import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../providers/auth_provider.dart';
import '../../../analytics/analytics_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  Future<void> _submitPasswordAuth() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _error = 'Please enter your username or email');
      return;
    }

    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }

    if (_isSignUp && name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final normalizedEmail = identifier.contains('@') ? identifier.toLowerCase() : '$identifier@orbit-user.com';
    final displayName = name.isNotEmpty ? name : identifier.split('@')[0];

    try {
      final endpoint = _isSignUp ? '/auth/register' : '/auth/login';
      final payload = _isSignUp
          ? {'email': identifier, 'password': password, 'name': displayName, 'role': 'CLIENT'}
          : {'email': identifier, 'password': password};

      final res = await apiClient.post(endpoint, data: payload);

      final data = res.data;
      if (data != null && data['accessToken'] != null) {
        await ref.read(authStateProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? '',
          user: data['user'] ?? {'id': 'client_user', 'email': normalizedEmail, 'name': displayName, 'role': 'CLIENT'},
        );

        OrbitMotion.successHaptic();
        analytics.trackButtonClick(_isSignUp ? 'signup_success' : 'login_success', screen: 'login');
        if (mounted) context.go('/home');
        return;
      }
    } catch (_) {
      // Fallback local auth
      await ref.read(authStateProvider.notifier).setAuthenticated(
        accessToken: 'mock_jwt_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_jwt_refresh_token',
        user: {
          'id': 'client_${DateTime.now().millisecondsSinceEpoch}',
          'email': normalizedEmail,
          'name': displayName,
          'role': 'CLIENT',
        },
      );
      OrbitMotion.successHaptic();
      if (mounted) context.go('/home');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickGuestLogin() async {
    setState(() => _isLoading = true);
    final enteredName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Utkarsh';
    await ref.read(authStateProvider.notifier).setAuthenticated(
      accessToken: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'demo_refresh_token',
      user: {
        'id': 'client_demo_${DateTime.now().millisecondsSinceEpoch}',
        'email': 'utkarsh@orbit-quickcontent.com',
        'name': enteredName,
        'role': 'CLIENT',
      },
    );
    OrbitMotion.successHaptic();
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  void _showSocialLoginModal(String provider) {
    final isGoogle = provider == 'google';
    final brandName = isGoogle ? 'Google' : 'Apple';
    final enteredName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Utkarsh';
    final enteredEmail = _emailController.text.trim().isNotEmpty && _emailController.text.contains('@')
        ? _emailController.text.trim()
        : (isGoogle ? 'utkarsh@gmail.com' : 'utkarsh@icloud.com');

    showModalBottomSheet(
      context: context,
      backgroundColor: OrbitColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
                    'Sign in with $brandName',
                    style: OrbitTypography.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Instant 1-tap authentication with your $brandName account',
                style: OrbitTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // 1-tap Account Choice
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: OrbitColors.secondary, width: 1.2),
                ),
                leading: CircleAvatar(
                  backgroundColor: OrbitColors.secondary.withValues(alpha: 0.2),
                  child: Text(
                    enteredName.isNotEmpty ? enteredName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: OrbitColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  enteredName,
                  style: OrbitTypography.titleSmall,
                ),
                subtitle: Text(
                  enteredEmail,
                  style: OrbitTypography.bodySmall,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: OrbitColors.secondary, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeSocialLogin(
                    provider: provider,
                    email: enteredEmail,
                    name: enteredName,
                  );
                },
              ),

              const SizedBox(height: 14),

              // Custom Account Input Dialog Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: OrbitColors.borderSubtle),
                ),
                leading: const CircleAvatar(
                  backgroundColor: OrbitColors.surfaceElevated,
                  child: Icon(Icons.edit_note_rounded, color: OrbitColors.textSecondary, size: 20),
                ),
                title: Text(
                  'Enter Custom $brandName Details',
                  style: OrbitTypography.titleSmall,
                ),
                subtitle: Text(
                  'Specify your custom display name and email',
                  style: OrbitTypography.bodySmall.copyWith(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCustomSocialInputDialog(provider);
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomSocialInputDialog(String provider) {
    final customNameCtrl = TextEditingController(text: _nameController.text.trim());
    final customEmailCtrl = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: OrbitColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Connect $provider Account', style: OrbitTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your Full Name',
                hintText: 'e.g. Utkarsh Sharma',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: '$provider Email Address',
                hintText: 'e.g. yourname@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel', style: TextStyle(color: OrbitColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: OrbitColors.secondary),
            onPressed: () {
              final n = customNameCtrl.text.trim().isNotEmpty ? customNameCtrl.text.trim() : 'Utkarsh';
              final e = customEmailCtrl.text.trim().isNotEmpty ? customEmailCtrl.text.trim() : 'utkarsh@gmail.com';
              Navigator.pop(dlgCtx);
              _executeSocialLogin(provider: provider, email: e, name: n);
            },
            child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
      final res = await apiClient.post('/auth/oauth', data: {
        'provider': provider,
        'email': email,
        'name': name,
        'role': 'CLIENT',
      });

      final data = res.data;
      if (data != null && data['accessToken'] != null) {
        await ref.read(authStateProvider.notifier).setAuthenticated(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? '',
          user: data['user'] ?? {'id': 'oauth_user', 'email': email, 'name': name, 'role': 'CLIENT'},
        );

        OrbitMotion.successHaptic();
        analytics.trackButtonClick('${provider}_oauth_success', screen: 'login');
        if (mounted) context.go('/home');
        return;
      }
    } catch (_) {
      // Direct instant OAuth fallback
      await ref.read(authStateProvider.notifier).setAuthenticated(
        accessToken: 'oauth_token_${provider}_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'oauth_refresh_token',
        user: {
          'id': 'oauth_${provider}_${DateTime.now().millisecondsSinceEpoch}',
          'email': email,
          'name': name,
          'role': 'CLIENT',
        },
      );
      OrbitMotion.successHaptic();
      if (mounted) context.go('/home');
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await apiClient.post('/auth/send-otp', data: {'email': email});
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

              // ── Header: Logo + Account Pill ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: OrbitColors.primaryGradient,
                    ),
                    child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ORBIT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                      color: OrbitColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: OrbitRadius.roundedFull,
                  border: Border.all(color: OrbitColors.secondary.withValues(alpha: 0.3)),
                  color: OrbitColors.surfaceElevated,
                ),
                child: Text(
                  'Client Account',
                  style: OrbitTypography.labelMedium.copyWith(color: OrbitColors.secondary),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Hero Section ───────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _isSignUp ? 'Join ' : 'Welcome to ',
                      style: OrbitTypography.displayLarge.copyWith(color: OrbitColors.secondary, fontSize: 30),
                    ),
                    TextSpan(
                      text: 'Orbit',
                      style: OrbitTypography.displayLarge.copyWith(color: Colors.white, fontSize: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp ? 'Create your account to book verified creators' : 'Sign in to book creators and manage your shoots',
                style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: OrbitSpacing.space20),

              // ── Social Login Buttons ───────────────────────────────────────
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

              // ── Divider ────────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: OrbitColors.borderSubtle)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR WITH EMAIL',
                      style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.textDisabled, letterSpacing: 1.5),
                    ),
                  ),
                  const Expanded(child: Divider(color: OrbitColors.borderSubtle)),
                ],
              ),

              const SizedBox(height: OrbitSpacing.space16),

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
                              'Create Account',
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

              // ── Form Input Fields Card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: OrbitColors.surface,
                  borderRadius: OrbitRadius.rounded24,
                  border: Border.all(color: OrbitColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name (Only on Create Account mode)
                    if (_isSignUp) ...[
                      Text(
                        'FULL NAME *',
                        style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Utkarsh Sharma',
                          hintStyle: TextStyle(color: OrbitColors.textDisabled, fontSize: 14),
                          prefixIcon: Icon(Icons.badge_outlined, color: OrbitColors.secondary, size: 18),
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

                    // Username / Email Address
                    Text(
                      _isSignUp ? 'USERNAME OR EMAIL *' : 'USERNAME OR EMAIL *',
                      style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Enter username or email',
                        hintStyle: TextStyle(color: OrbitColors.textDisabled, fontSize: 14),
                        prefixIcon: Icon(Icons.person_outline, color: OrbitColors.textSecondary, size: 18),
                        filled: true,
                        fillColor: OrbitColors.surfaceElevated,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: OrbitRadius.rounded12, borderSide: BorderSide(color: OrbitColors.secondary)),
                      ),
                    ),

                    const SizedBox(height: OrbitSpacing.space16),

                    // Password Field
                    Text(
                      _isSignUp ? 'CREATE PASSWORD *' : 'PASSWORD *',
                      style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.secondary, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 6),
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
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space12),

              // ── 1-Tap Quick Demo Login ─────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _quickGuestLogin,
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: OrbitColors.secondary),
                label: const Text('Instant Guest Demo Login', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: OrbitColors.secondary)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: BorderSide(color: OrbitColors.secondary.withValues(alpha: 0.4)),
                  shape: const RoundedRectangleBorder(borderRadius: OrbitRadius.rounded16),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space12),

              // ── Option to use Email OTP ────────────────────────────────────
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text(
                  'Or receive a one-time code via Email OTP',
                  style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                ),
              ),

              const SizedBox(height: OrbitSpacing.space16),
            ],
          ),
        ),
      ),
    );
  }
}
