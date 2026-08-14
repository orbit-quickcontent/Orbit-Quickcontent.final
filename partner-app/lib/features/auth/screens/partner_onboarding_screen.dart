import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../providers/partner_auth_provider.dart';

class PartnerOnboardingScreen extends ConsumerStatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  ConsumerState<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends ConsumerState<PartnerOnboardingScreen> {
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your verification code');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await partnerApiClient.post('/partner/verify-code', data: {
        'code': code,
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
      });

      if (!mounted) return;
      if (res.data['success'] == true) {
        await ref.read(partnerAuthProvider.notifier).completedOnboarding();
        context.go('/work');
      } else {
        setState(() => _error = res.data['error'] ?? 'Verification failed');
      }
    } catch (e: any) {
      setState(() => _error = e.response?.data['error'] ?? 'Invalid verification code');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Partner Onboarding', style: OrbitPartnerTheme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OrbitPartnerTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, color: OrbitPartnerTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activation Required', style: OrbitPartnerTheme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Enter the unique verification code assigned during your training session.',
                          style: OrbitPartnerTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text('VERIFICATION CODE', style: OrbitPartnerTheme.textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. ORBIT-XYZ123',
                prefixIcon: const Icon(Icons.key, size: 18, color: OrbitPartnerTheme.textSecondary),
                errorText: _error,
              ),
            ),

            const SizedBox(height: 20),

            Text('PHONE NUMBER', style: OrbitPartnerTheme.textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone, size: 18, color: OrbitPartnerTheme.textSecondary),
              ),
            ),

            const SizedBox(height: 20),

            Text('BASE CITY', style: OrbitPartnerTheme.textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                hintText: 'e.g. Mumbai, Delhi, Bengaluru',
                prefixIcon: Icon(Icons.location_city, size: 18, color: OrbitPartnerTheme.textSecondary),
              ),
            ),

            const SizedBox(height: 36),

            PartnerButton(
              label: 'Activate Partner Account',
              onPressed: _isLoading ? null : _submitVerification,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
