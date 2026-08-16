import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Request Location and Notification
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();

    // In a real app we might handle denied permissions by showing a rationale dialog.
    // For now, after requesting, we mark permissions as "seen" and proceed to onboarding.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (!mounted) return;
    context.go('/onboarding');
  }

  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (!mounted) return;
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OrbitClientTheme.surface,
                  border: Border.all(color: OrbitClientTheme.border, width: 2),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 60,
                  color: OrbitClientTheme.primary,
                ),
              )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(),

              const SizedBox(height: 40),

              Text(
                'Unlock the Full Experience',
                textAlign: TextAlign.center,
                style: OrbitClientTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: OrbitClientTheme.onBackground,
                ),
              )
              .animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 16),

              Text(
                'We need your location to find the best videographers near you, and notifications to keep you updated on your bookings.',
                textAlign: TextAlign.center,
                style: OrbitClientTheme.textTheme.bodyLarge?.copyWith(
                  color: OrbitClientTheme.onSurfaceVariant,
                ),
              )
              .animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

              const Spacer(),

              // Request Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrbitClientTheme.primary,
                    foregroundColor: OrbitClientTheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Allow Access',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2),

              const SizedBox(height: 16),

              // Skip Button
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: OrbitClientTheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
