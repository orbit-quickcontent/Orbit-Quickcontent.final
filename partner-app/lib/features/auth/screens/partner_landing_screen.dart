import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartnerLandingScreen extends StatelessWidget {
  const PartnerLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Top 60%: Rich Stylized Creator Scene Illustration ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.60,
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
                  // Stylized Background Architecture & Streetlamp
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

                  // Floating Highlight Badges in the Scene
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Instant Nearby Shoots',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Daily 100% Payouts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom 40%: High-Contrast White Sheet / Onboarding Card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.43,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
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
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                      const Text(
                        'Creator Partner app',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accept instant on-demand video shoots, film high-impact reels, and get paid same day.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Action Buttons
                  Column(
                    children: [
                      // Full-width Black "Continue ->" Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('has_seen_landing', true);
                            } catch (_) {}
                            if (context.mounted) {
                              context.go('/permissions');
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 24), // For center alignment balance
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // "or Book shoots as Client" Link
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
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'or Book shoots as Client',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 14,
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

    // Stylized Studio Light Beam
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

    // Stylized Creator Vehicle / Mobile Studio Hood on Left
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

    // Stylized Creator & Client Silhouette Figure on Right
    final personPaint = Paint()..color = const Color(0xFF0F172A);
    final skirtPaint = Paint()..color = const Color(0xFF0284C7);

    // Head
    canvas.drawCircle(Offset(w * 0.86, h * 0.32), 16, personPaint);
    // Torso / Camera Operator
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.81, h * 0.35, 30, 48), const Radius.circular(8)),
      personPaint,
    );
    // Lower Outfit
    final skirtPath = Path()
      ..moveTo(w * 0.81, h * 0.43)
      ..lineTo(w * 0.94, h * 0.43)
      ..lineTo(w * 0.98, h * 0.62)
      ..lineTo(w * 0.78, h * 0.62)
      ..close();
    canvas.drawPath(skirtPath, skirtPaint);

    // Legs / Boots
    final bootPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.80, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.88, h * 0.62, 12, 28), const Radius.circular(4)), bootPaint);

    // Cinema Gimbal / Rig in hand
    final gimbalPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.76, h * 0.40), Offset(w * 0.72, h * 0.35), gimbalPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.66, h * 0.32, 20, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1E293B),
    );
    // Lens glowing cyan circle
    canvas.drawCircle(Offset(w * 0.67, h * 0.39), 4, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
