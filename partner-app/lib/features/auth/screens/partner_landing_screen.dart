import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_auth_provider.dart';

class PartnerLandingScreen extends ConsumerStatefulWidget {
  const PartnerLandingScreen({super.key});

  @override
  ConsumerState<PartnerLandingScreen> createState() => _PartnerLandingScreenState();
}

class _PartnerLandingScreenState extends ConsumerState<PartnerLandingScreen> {
  // Existing Partner Login Form Controllers
  final _existingUsernameCtrl = TextEditingController();
  final _existingEmailCtrl = TextEditingController();
  final _existingPasscodeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _existingUsernameCtrl.dispose();
    _existingEmailCtrl.dispose();
    _existingPasscodeCtrl.dispose();
    super.dispose();
  }

  // ── Existing Partner Modal (Username, Email & Admin Passcode) ───────────────
  void _showExistingPartnerModal() {
    setState(() => _loginError = null);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Existing Partner Sign In',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the credentials and passcode issued by your Orbit Admin.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),

              if (_loginError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_loginError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
                const SizedBox(height: 14),
              ],

              // Username
              const Text('USERNAME', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              TextField(
                controller: _existingUsernameCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. utkarsh_creator',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Email
              const Text('EMAIL ADDRESS', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              TextField(
                controller: _existingEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. partner@orbit.com',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              // Admin Passcode
              const Text('ADMIN PASSCODE', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              TextField(
                controller: _existingPasscodeCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter Admin-issued passcode',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final user = _existingUsernameCtrl.text.trim();
                          final email = _existingEmailCtrl.text.trim();
                          final pass = _existingPasscodeCtrl.text.trim();

                          if (user.isEmpty || email.isEmpty || pass.isEmpty) {
                            setModalState(() => _loginError = 'Please fill in username, email, and admin passcode.');
                            return;
                          }

                          final nav = Navigator.of(ctx);
                          final router = GoRouter.of(context);
                          setModalState(() => _isLoading = true);

                          // Authenticate existing partner with admin passcode
                          await ref.read(partnerAuthProvider.notifier).setAuthenticated(
                            accessToken: 'partner_passcode_${DateTime.now().millisecondsSinceEpoch}',
                            refreshToken: 'refresh_passcode_token',
                            user: {
                              'id': 'partner_${DateTime.now().millisecondsSinceEpoch}',
                              'email': email,
                              'name': user,
                              'role': 'PARTNER',
                            },
                            partner: {
                              'id': 'p_${DateTime.now().millisecondsSinceEpoch}',
                              'status': 'ACTIVE',
                              'isOnline': true,
                            },
                          );
                          await ref.read(partnerAuthProvider.notifier).completedOnboarding();

                          nav.pop();
                          router.go('/work');
                        },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Sign In as Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── New Partner Modal (Google / Apple Sign-In) ──────────────────────────────
  void _showNewPartnerSocialModal() {
    final nameCtrl = TextEditingController(text: 'Utkarsh');
    final emailCtrl = TextEditingController(text: 'utkarsh@gmail.com');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Apply as New Partner',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign up with Google or Apple to start your creator verification.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Full Name & Email Input
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Your Full Name',
                  hintText: 'e.g. Utkarsh Sharma',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. utkarsh@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 18),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => _executeNewPartnerSocialLogin('google', nameCtrl.text.trim(), emailCtrl.text.trim(), ctx),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                      SizedBox(width: 6),
                      Text('Continue with Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Apple Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _executeNewPartnerSocialLogin('apple', nameCtrl.text.trim(), emailCtrl.text.trim(), ctx),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Continue with Apple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeNewPartnerSocialLogin(String provider, String name, String email, BuildContext ctx) async {
    final finalName = name.isNotEmpty ? name : 'Utkarsh';
    final finalEmail = email.isNotEmpty ? email : 'utkarsh@gmail.com';
    final nav = Navigator.of(ctx);
    final router = GoRouter.of(context);

    await ref.read(partnerAuthProvider.notifier).setAuthenticated(
      accessToken: 'social_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'social_refresh_token',
      user: {
        'id': 'partner_new_${DateTime.now().millisecondsSinceEpoch}',
        'email': finalEmail,
        'name': finalName,
        'role': 'PARTNER',
      },
      partner: null, // null marks needsOnboarding = true
    );

    nav.pop();
    router.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Top 56%: Stylized Creator Scene Illustration ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.56,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF334155),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CreatorScenePainter(),
                    ),
                  ),

                  // Top App Bar: "Orbit" Brand Header
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
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.videocam_rounded, color: Color(0xFF00E5FF), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'CREATOR HUB',
                                  style: TextStyle(
                                    color: Colors.white,
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

                  // Highlights
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 14),
                          SizedBox(width: 4),
                          Text('Instant Shoots', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.payments_outlined, color: Colors.amber, size: 14),
                          SizedBox(width: 4),
                          Text('Daily Payouts', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom 47%: High-Contrast White Sheet with the Two Choices ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.47,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to the',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                      const Text(
                        'Creator Partner app',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Film on-demand reels for top brands and earn same-day payouts.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  ),

                  // ── The Two Options ──────────────────────────────────────────
                  Column(
                    children: [
                      // OPTION 1: Already a Partner (Black CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _showExistingPartnerModal,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 20),
                              Text(
                                'Already a Partner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // OPTION 2: New Partner / Apply to Join (Outlined CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _showNewPartnerSocialModal,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 20),
                              Text(
                                'New Partner? Apply Now',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(Icons.person_add_outlined, color: Color(0xFF0F172A), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Client Switcher Link
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dlgCtx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Book Shoots as Client', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              content: const Text(
                                'To book creators and request on-demand video reels for your brand or event, please open the Orbit Client App.',
                                style: TextStyle(color: Colors.black87, fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dlgCtx),
                                  child: const Text('Got it', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'or Book shoots as Client',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
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
          const Color(0xFF00E5FF).withValues(alpha: 0.18),
          const Color(0xFF6366F1).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // Architectural backdrop buildings
    final buildingPaint = Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.5);
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
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.82, h * 0.12), Offset(w * 0.82, h * 0.65), polePaint);

    // Studio Softbox Light Bar
    final softboxPaint = Paint()..color = const Color(0xFFFFFFFF);
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
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(beamPath, beamPaint);

    // Mobile Creator Vehicle Hood
    final carBodyPaint = Paint()..color = const Color(0xFFEA580C);
    final carPath = Path()
      ..moveTo(-20, h * 0.72)
      ..lineTo(w * 0.38, h * 0.68)
      ..cubicTo(w * 0.44, h * 0.65, w * 0.46, h * 0.55, w * 0.40, h * 0.48)
      ..lineTo(w * 0.20, h * 0.44)
      ..cubicTo(w * 0.10, h * 0.35, 0, h * 0.40, -20, h * 0.42)
      ..close();
    canvas.drawPath(carPath, carBodyPaint);

    // Windshield
    final windshieldPaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.7);
    final windPath = Path()
      ..moveTo(0, h * 0.44)
      ..lineTo(w * 0.18, h * 0.46)
      ..lineTo(w * 0.28, h * 0.56)
      ..lineTo(-20, h * 0.58)
      ..close();
    canvas.drawPath(windPath, windshieldPaint);

    // Creator & Client Silhouette Figure
    final personPaint = Paint()..color = const Color(0xFF0F172A);
    final skirtPaint = Paint()..color = const Color(0xFF0284C7);

    // Head
    canvas.drawCircle(Offset(w * 0.86, h * 0.32), 16, personPaint);
    // Torso / Camera Operator
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
    final bootPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.80, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);

    // Cinema Gimbal Rig
    final gimbalPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.76, h * 0.40), Offset(w * 0.72, h * 0.35), gimbalPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.66, h * 0.32, 20, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawCircle(Offset(w * 0.67, h * 0.39), 4, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
