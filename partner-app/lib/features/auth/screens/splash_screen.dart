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
    await Future.delayed(const Duration(milliseconds: 2500));
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
            ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 24),
            Text(
              'ORBIT Partner',
              style: OrbitPartnerTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: OrbitPartnerTheme.onSurface,
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
