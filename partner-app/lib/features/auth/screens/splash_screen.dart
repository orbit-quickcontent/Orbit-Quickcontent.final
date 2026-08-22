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
    final prefs = await SharedPreferences.getInstance();
    final hasSeenLanding = prefs.getBool('has_seen_landing') ?? false;
    final hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;
    
    if (!mounted) return;
    
    if (!hasSeenLanding) {
      context.go('/landing');
    } else if (!hasSeenPermissions) {
      context.go('/permissions');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OrbitPartnerTheme.surface,
                border: Border.all(color: OrbitPartnerTheme.outlineFaint, width: 2),
              ),
              child: const Icon(
                Icons.work_outline,
                size: 60,
                color: OrbitPartnerTheme.primary,
              ),
            ).animate().scaleXY(begin: 0.6, end: 1.0, duration: 350.ms, curve: Curves.easeOutCubic).fadeIn(duration: 250.ms),
            const SizedBox(height: 24),
            Text(
              'ORBIT Partner',
              style: OrbitPartnerTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: OrbitPartnerTheme.onSurface,
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
