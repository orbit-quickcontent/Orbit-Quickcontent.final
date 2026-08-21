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

    // Request Location, Camera, Notification
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
    ].request();

    // After granting foreground location, we technically need background location for partners
    // We request it sequentially as per permission_handler docs
    if (statuses[Permission.locationWhenInUse]?.isGranted ?? false) {
      await Permission.locationAlways.request();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
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
                  color: OrbitPartnerTheme.surface,
                  border: Border.all(color: OrbitPartnerTheme.outlineFaint, width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 60,
                  color: OrbitPartnerTheme.primary,
                ),
              )
              .animate()
              .scale(begin: const Offset(0.7, 0.7), duration: 300.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 250.ms),

              const SizedBox(height: 40),

              Text(
                'Required Permissions',
                textAlign: TextAlign.center,
                style: OrbitPartnerTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: OrbitPartnerTheme.onSurface,
                ),
              )
              .animate(delay: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 16),

              Text(
                'To receive booking requests and navigate to clients, you must grant access to your Location and Notifications. Camera access is needed for verification.',
                textAlign: TextAlign.center,
                style: OrbitPartnerTheme.textTheme.bodyLarge?.copyWith(
                  color: OrbitPartnerTheme.textSecondary,
                ),
              )
              .animate(delay: 140.ms).fadeIn(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, curve: Curves.easeOutCubic),

              const Spacer(),

              // Request Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrbitPartnerTheme.primary,
                    foregroundColor: OrbitPartnerTheme.onPrimary,
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
                          'Grant Permissions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ).animate(delay: 180.ms).fadeIn(duration: 250.ms).slideY(begin: 0.08, duration: 250.ms, curve: Curves.easeOutCubic),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
