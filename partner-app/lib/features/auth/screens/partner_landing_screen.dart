import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/partner_auth_provider.dart';

// ── Master Login Credentials ─────────────────────────────────────────────────
const String _masterEmail = 'orbit.quickcontent@gmail.com';
const String _masterPassword = '123456';

class PartnerLandingScreen extends ConsumerStatefulWidget {
  const PartnerLandingScreen({super.key});

  @override
  ConsumerState<PartnerLandingScreen> createState() => _PartnerLandingScreenState();
}

class _PartnerLandingScreenState extends ConsumerState<PartnerLandingScreen>
    with SingleTickerProviderStateMixin {
  // Existing Partner Login Form Controllers
  final _existingEmailCtrl = TextEditingController();
  final _existingPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _existingEmailCtrl.dispose();
    _existingPasswordCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Master Login Check ─────────────────────────────────────────────────────
  bool _isMasterLogin(String email, String password) {
    return email.toLowerCase().trim() == _masterEmail &&
        password.trim() == _masterPassword;
  }

  // ── Execute Login ──────────────────────────────────────────────────────────
  Future<void> _executeLogin(String email, String name, {bool skipOnboarding = false}) async {
    final router = GoRouter.of(context);

    await ref.read(partnerAuthProvider.notifier).setAuthenticated(
      accessToken: 'partner_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      user: {
        'id': 'partner_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'name': name,
        'role': 'PARTNER',
      },
      partner: skipOnboarding
          ? {
              'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
              'status': 'ACTIVE',
              'isOnline': true,
            }
          : null,
    );

    if (skipOnboarding) {
      await ref.read(partnerAuthProvider.notifier).completedOnboarding();
      router.go('/work');
    } else {
      router.go('/onboarding');
    }
  }

  // ── Show Login Modal ───────────────────────────────────────────────────────
  void _showLoginModal() {
    _existingEmailCtrl.clear();
    _existingPasswordCtrl.clear();
    setState(() {
      _loginError = null;
      _obscurePassword = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF12161B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFF9B82FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Login with your credentials',
                          style: TextStyle(color: Color(0xFF9AA3AE), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error Banner
              if (_loginError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF450A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loginError!,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              const Text(
                'EMAIL',
                style: TextStyle(
                  color: Color(0xFF9AA3AE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _existingEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'partner@orbit.com',
                  hintStyle: const TextStyle(color: Color(0xFF68717D), fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C5CFF), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF181D23),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF252B33)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF252B33)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              const Text(
                'PASSWORD',
                style: TextStyle(
                  color: Color(0xFF9AA3AE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _existingPasswordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  hintStyle: const TextStyle(color: Color(0xFF68717D), fontSize: 14),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7C5CFF), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF68717D),
                      size: 20,
                    ),
                    onPressed: () => setModalState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF181D23),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF252B33)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF252B33)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFF), Color(0xFF9B82FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final email = _existingEmailCtrl.text.trim();
                            final pass = _existingPasswordCtrl.text.trim();

                            if (email.isEmpty || pass.isEmpty) {
                              setModalState(() => _loginError = 'Please enter email and password.');
                              return;
                            }

                            // Check master login
                            if (_isMasterLogin(email, pass)) {
                              setModalState(() {
                                _isLoading = true;
                                _loginError = null;
                              });
                              HapticFeedback.mediumImpact();
                              Navigator.of(ctx).pop();
                              await _executeLogin(
                                _masterEmail,
                                'Orbit Admin',
                                skipOnboarding: true,
                              );
                              if (mounted) setState(() => _isLoading = false);
                              return;
                            }

                            // For any other email/password: attempt generic partner login
                            setModalState(() {
                              _isLoading = true;
                              _loginError = null;
                            });
                            HapticFeedback.mediumImpact();
                            Navigator.of(ctx).pop();
                            await _executeLogin(
                              email,
                              email.split('@')[0],
                              skipOnboarding: true,
                            );
                            if (mounted) setState(() => _isLoading = false);
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '753333113627-4lbfu2006cghbdrc21rla0b78cj37a4d.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      try {
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final email = account.email;
        final name = account.displayName ?? email.split('@')[0];
        await _executeLogin(email, name, skipOnboarding: false);
        return;
      }
    } catch (e) {
      debugPrint('Partner GoogleSignIn exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In requires a configured device. Use email/password login instead.'),
            backgroundColor: const Color(0xFF181D23),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── New Partner Apply Modal ────────────────────────────────────────────────
  void _showApplyModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF12161B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply as Creator Partner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Join our creator network',
                        style: TextStyle(color: Color(0xFF9AA3AE), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Google Sign-In
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181D23),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF252B33)),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _handleGoogleSignIn();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR ENTER DETAILS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Color(0xFF68717D)),
                hintText: 'e.g. Utkarsh Sharma',
                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C5CFF), size: 20),
                filled: true,
                fillColor: const Color(0xFF181D23),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF252B33)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF252B33)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Email field
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: const TextStyle(color: Color(0xFF68717D)),
                hintText: 'e.g. yourname@gmail.com',
                hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7C5CFF), size: 20),
                filled: true,
                fillColor: const Color(0xFF181D23),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF252B33)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF252B33)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Continue Application
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final n = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Creator';
                    final e = emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : 'creator@orbit.app';
                    Navigator.of(ctx).pop();
                    _executeLogin(e, n, skipOnboarding: false);
                  },
                  child: const Text(
                    'Submit Application →',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: Stack(
        children: [
          // ── Top Area: Stylized Creator Scene ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B0D10),
                    Color(0xFF12161B),
                    Color(0xFF181D23),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // Background custom paint
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CreatorScenePainter(),
                    ),
                  ),

                  // Animated glow orb
                  Positioned(
                    top: size.height * 0.15,
                    left: size.width * 0.3,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C5CFF).withValues(alpha: 0.12 * _pulseAnimation.value),
                              blurRadius: 80,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top App Bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Orbit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF7C5CFF),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C5CFF).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C5CFF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF7C5CFF).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.videocam_rounded, color: Color(0xFF7C5CFF), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'PARTNER',
                                  style: TextStyle(
                                    color: Color(0xFF9B82FF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Feature pills
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D10).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7C5CFF).withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF7C5CFF), size: 14),
                          SizedBox(width: 5),
                          Text('Instant Shoots', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0D10).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.payments_outlined, color: Color(0xFF22C55E), size: 14),
                          SizedBox(width: 5),
                          Text('Daily Payouts', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Sheet: Dark-themed with Two CTAs ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.48,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF12161B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: const Color(0xFF7C5CFF).withValues(alpha: 0.15), width: 1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 30,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Welcome text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to the',
                        style: TextStyle(
                          color: Color(0xFF9AA3AE),
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFF9B82FF), Color(0xFF38BDF8)],
                        ).createShader(bounds),
                        child: const Text(
                          'Creator Partner Hub',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Film on-demand reels for top brands.\nEarn same-day payouts.',
                        style: TextStyle(color: Color(0xFF68717D), fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),

                  // CTAs
                  Column(
                    children: [
                      // Sign In CTA (Primary)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C5CFF), Color(0xFF9B82FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _showLoginModal,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Sign In as Partner',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New Partner / Apply (Secondary)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF252B33), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: const Color(0xFF181D23),
                          ),
                          onPressed: _showApplyModal,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, color: Color(0xFF9AA3AE), size: 20),
                              SizedBox(width: 10),
                              Text(
                                'New Partner? Apply Now',
                                style: TextStyle(
                                  color: Color(0xFFF5F7FA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Client switcher
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dlgCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF181D23),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Book Shoots as Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: const Text(
                                'To book creators and request on-demand video reels for your brand, please open the Orbit Client App.',
                                style: TextStyle(color: Color(0xFF9AA3AE), fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dlgCtx),
                                  child: const Text('Got it', style: TextStyle(color: Color(0xFF7C5CFF), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'or Book shoots as Client →',
                            style: TextStyle(
                              color: Color(0xFF7C5CFF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Scene Painter for Filmmaker / Creator On-Location Visual
class _CreatorScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.2),
        radius: 0.9,
        colors: [
          const Color(0xFF7C5CFF).withValues(alpha: 0.12),
          const Color(0xFF6366F1).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // Architectural backdrop buildings
    final buildingPaint = Paint()..color = const Color(0xFF181D23).withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.35, h * 0.5), const Radius.circular(8)),
      buildingPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.52, h * 0.15, w * 0.4, h * 0.6), const Radius.circular(8)),
      buildingPaint,
    );

    // Studio / Street Light Pole
    final polePaint = Paint()
      ..color = const Color(0xFF252B33)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.82, h * 0.12), Offset(w * 0.82, h * 0.65), polePaint);

    // Studio Softbox Light Bar
    final softboxPaint = Paint()..color = const Color(0xFF9B82FF).withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.68, h * 0.10, w * 0.26, 16), const Radius.circular(6)),
      softboxPaint,
    );

    // Light Beam
    final beamPath = Path()
      ..moveTo(w * 0.70, h * 0.12)
      ..lineTo(w * 0.92, h * 0.12)
      ..lineTo(w * 0.65, h * 0.75)
      ..lineTo(w * 0.20, h * 0.75)
      ..close();
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7C5CFF).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(beamPath, beamPaint);

    // Mobile Creator Vehicle
    final carBodyPaint = Paint()..color = const Color(0xFF7C5CFF).withValues(alpha: 0.7);
    final carPath = Path()
      ..moveTo(-20, h * 0.72)
      ..lineTo(w * 0.38, h * 0.68)
      ..cubicTo(w * 0.44, h * 0.65, w * 0.46, h * 0.55, w * 0.40, h * 0.48)
      ..lineTo(w * 0.20, h * 0.44)
      ..cubicTo(w * 0.10, h * 0.35, 0, h * 0.40, -20, h * 0.42)
      ..close();
    canvas.drawPath(carPath, carBodyPaint);

    // Windshield
    final windshieldPaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.5);
    final windPath = Path()
      ..moveTo(0, h * 0.44)
      ..lineTo(w * 0.18, h * 0.46)
      ..lineTo(w * 0.28, h * 0.56)
      ..lineTo(-20, h * 0.58)
      ..close();
    canvas.drawPath(windPath, windshieldPaint);

    // Creator Silhouette
    final personPaint = Paint()..color = const Color(0xFF0B0D10);
    final skirtPaint = Paint()..color = const Color(0xFF7C5CFF).withValues(alpha: 0.8);

    // Head
    canvas.drawCircle(Offset(w * 0.86, h * 0.32), 16, personPaint);
    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.81, h * 0.35, 30, 48), const Radius.circular(8)),
      personPaint,
    );
    // Skirt
    final skirtPath = Path()
      ..moveTo(w * 0.81, h * 0.43)
      ..lineTo(w * 0.94, h * 0.43)
      ..lineTo(w * 0.98, h * 0.62)
      ..lineTo(w * 0.78, h * 0.62)
      ..close();
    canvas.drawPath(skirtPath, skirtPaint);

    // Boots
    final bootPaint = Paint()..color = const Color(0xFF0B0D10);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.80, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);

    // Cinema Gimbal Rig
    final gimbalPaint = Paint()
      ..color = const Color(0xFF7C5CFF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.76, h * 0.40), Offset(w * 0.72, h * 0.35), gimbalPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.66, h * 0.32, 20, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF181D23),
    );
    canvas.drawCircle(Offset(w * 0.67, h * 0.39), 4, Paint()..color = const Color(0xFF7C5CFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
