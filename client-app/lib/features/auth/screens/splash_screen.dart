import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;
    
    if (!hasSeenPermissions) {
      context.go('/permissions');
    } else {
      context.go('/login');
    }
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
              // Sleek Glowing ORBIT Symbol
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: OrbitClientTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: OrbitClientTheme.primaryFixed.withOpacity(0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              )
              .animate()
              .scaleXY(begin: 0.8, end: 1.0, duration: 300.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 250.ms),

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
              .animate(delay: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 8),

              Text(
                'Hyperlocal Video Marketplace',
                style: OrbitClientTheme.textTheme.bodySmall?.copyWith(
                  color: OrbitClientTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              )
              .animate(delay: 200.ms)
              .fadeIn(duration: 300.ms),

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
                  .animate(delay: (300 + i * 120).ms, onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.6, end: 1.0, duration: 400.ms, curve: Curves.easeInOut)
                  .fadeIn(duration: 200.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
