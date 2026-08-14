import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E0E), Color(0xFF131313), Color(0xFF0A0A0A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing ORBIT logo container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: OrbitClientTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: OrbitClientTheme.primaryFixed.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: OrbitClientTheme.secondary.withOpacity(0.2),
                      blurRadius: 60,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 50),
              )
              .animate()
              .scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ORBIT wordmark
              Text(
                'ORBIT',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  foreground: Paint()
                    ..shader = OrbitClientTheme.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 60),
                    ),
                ),
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),

              const SizedBox(height: 8),

              Text(
                'Hyperlocal Video Marketplace',
                style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                  color: OrbitClientTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              )
              .animate(delay: 600.ms)
              .fadeIn(duration: 500.ms),

              const SizedBox(height: 80),

              // Animated loading dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) =>
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: OrbitClientTheme.primaryGradient,
                    ),
                  )
                  .animate(delay: (800 + i * 150).ms, onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.5, end: 1.0, duration: 500.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 300.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
