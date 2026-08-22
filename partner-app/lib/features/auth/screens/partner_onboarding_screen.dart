import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_auth_provider.dart';

class PartnerOnboardingScreen extends ConsumerStatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  ConsumerState<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends ConsumerState<PartnerOnboardingScreen> {
  String _selectedCity = 'Nagpur';
  String _selectedState = 'All of MH';
  final String _selectedCategory = 'Video Shoots';

  // Step Completion State
  bool _stepGearDone = false;
  bool _stepPortfolioDone = false;
  bool _stepAadhaarDone = false;
  bool _stepProfilePicDone = false;
  bool _stepBankDone = false;
  final bool _stepLanguageDone = true; // Completed by default

  int get _completedStepsCount {
    int count = 0;
    if (_stepLanguageDone) count++;
    if (_stepGearDone) count++;
    if (_stepPortfolioDone) count++;
    if (_stepAadhaarDone) count++;
    if (_stepProfilePicDone) count++;
    if (_stepBankDone) count++;
    return count;
  }

  int get _remainingStepsCount => 6 - _completedStepsCount;

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Your Primary Base City', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...[
              {'city': 'Nagpur', 'state': 'All of MH'},
              {'city': 'Delhi NCR', 'state': 'All of North India'},
              {'city': 'Mumbai', 'state': 'All of MH & Goa'},
              {'city': 'Bengaluru', 'state': 'All of Karnataka'},
            ].map((loc) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, color: Colors.black87),
                  title: Text(loc['city']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                  subtitle: Text(loc['state']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: _selectedCity == loc['city'] ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                  onTap: () {
                    setState(() {
                      _selectedCity = loc['city']!;
                      _selectedState = loc['state']!;
                    });
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _openStepModal({
    required String title,
    required String subtitle,
    required Widget content,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  onSave();
                  Navigator.pop(ctx);
                },
                child: const Text('Save & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomReviewSheet(String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  onPressed: () => Navigator.pop(ctx),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Help', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Welcome back, ${userName.toLowerCase()}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have completed $_completedStepsCount step${_completedStepsCount > 1 ? 's' : ''} and there are only $_remainingStepsCount more steps left to start earning.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),

            // Progress bar
            _buildProgressBar(),

            const SizedBox(height: 20),

            // Review Choices Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review your signup choices', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam_outlined, size: 13, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(_selectedCategory, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_selectedCity, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Can earn in: $_selectedState', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                          ),
                          child: const Icon(Icons.edit_outlined, size: 16, color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCityPicker();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Need help row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Need help?', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Contact support if you need help to finish signup.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: const Icon(Icons.headset_mic_outlined, color: Colors.black87, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  final router = GoRouter.of(context);
                  await ref.read(partnerAuthProvider.notifier).completedOnboarding();
                  nav.pop();
                  router.go('/work');
                },
                child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(6, (index) {
        final isFilled = index < _completedStepsCount;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isFilled ? const Color(0xFF10B981) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepTile({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : (isRecommended ? const Color(0xFF2563EB) : Colors.grey.shade500),
                      fontSize: 13,
                      fontWeight: isCompleted || isRecommended ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.chevron_right_rounded,
              color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade400,
              size: isCompleted ? 20 : 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(partnerAuthProvider);
    final userName = user.name?.isNotEmpty == true ? user.name! : 'utkarsh';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Orbit',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Help',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // ── Signing Up For Row ──────────────────────────────────────────
            GestureDetector(
              onTap: _showCityPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signing up for',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$_selectedCity • $_selectedCategory • 🎥',
                        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Headline: Welcome, [Name] ───────────────────────────────────
            Text(
              'Welcome, ${userName.toLowerCase()}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete $_remainingStepsCount more steps to start earning.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),

            const SizedBox(height: 18),

            // ── 6-Step Green Progress Bar ──────────────────────────────────
            _buildProgressBar(),

            const SizedBox(height: 16),

            // ── 6 Onboarding Checklist Steps ───────────────────────────────
            // Step 1: Camera & Gimbal Gear
            _buildStepTile(
              title: 'Camera & Mobile Gimbal Gear',
              subtitle: _stepGearDone ? 'Verified (iPhone 15 Pro / DJI Gimbal)' : 'Recommended next step',
              isCompleted: _stepGearDone,
              isRecommended: !_stepGearDone,
              onTap: () {
                final gearCtrl = TextEditingController(text: 'iPhone 15 Pro Max + DJI Osmo Mobile 6');
                _openStepModal(
                  title: 'Camera Gear Details',
                  subtitle: 'Specify the phone camera or cinema rig you will film with.',
                  content: TextField(
                    controller: gearCtrl,
                    decoration: const InputDecoration(labelText: 'Primary Camera & Gimbal Model', border: OutlineInputBorder()),
                  ),
                  onSave: () => setState(() => _stepGearDone = true),
                );
              },
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Step 2: Creator Portfolio
            _buildStepTile(
              title: 'Creator Portfolio & Sample Reels',
              subtitle: _stepPortfolioDone ? 'Completed' : 'Instagram or Drive link',
              isCompleted: _stepPortfolioDone,
              isRecommended: false,
              onTap: () {
                final linkCtrl = TextEditingController(text: 'https://instagram.com/reels');
                _openStepModal(
                  title: 'Reels Portfolio Link',
                  subtitle: 'Add your portfolio or Instagram link showcasing your video editing and shoot quality.',
                  content: TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(labelText: 'Portfolio / Instagram URL', border: OutlineInputBorder()),
                  ),
                  onSave: () => setState(() => _stepPortfolioDone = true),
                );
              },
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Step 3: Aadhaar Card / ID
            _buildStepTile(
              title: 'Aadhaar Card / Government ID',
              subtitle: _stepAadhaarDone ? 'Verified' : 'Identity verification',
              isCompleted: _stepAadhaarDone,
              isRecommended: false,
              onTap: () {
                final aadhaarCtrl = TextEditingController(text: 'XXXX-XXXX-9821');
                _openStepModal(
                  title: 'Aadhaar Verification',
                  subtitle: 'Enter your 12-digit Aadhaar number for creator verification.',
                  content: TextField(
                    controller: aadhaarCtrl,
                    decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder()),
                  ),
                  onSave: () => setState(() => _stepAadhaarDone = true),
                );
              },
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Step 4: Profile Picture
            _buildStepTile(
              title: 'Profile Picture',
              subtitle: _stepProfilePicDone ? 'Uploaded' : 'Headshot for clients',
              isCompleted: _stepProfilePicDone,
              isRecommended: false,
              onTap: () {
                _openStepModal(
                  title: 'Creator Headshot',
                  subtitle: 'Upload a clear, friendly photo for clients to recognize you on shoots.',
                  content: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.black87),
                      ),
                      const SizedBox(width: 14),
                      const Text('Tap to choose photo from gallery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  onSave: () => setState(() => _stepProfilePicDone = true),
                );
              },
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Step 5: Bank Account / UPI
            _buildStepTile(
              title: 'Bank Account / UPI Details',
              subtitle: _stepBankDone ? 'Active for direct payouts' : 'For daily earnings transfer',
              isCompleted: _stepBankDone,
              isRecommended: false,
              onTap: () {
                final upiCtrl = TextEditingController(text: 'utkarsh@okhdfcbank');
                _openStepModal(
                  title: 'Payout Details',
                  subtitle: 'Enter your UPI ID or Bank Account for instant same-day shoot payouts.',
                  content: TextField(
                    controller: upiCtrl,
                    decoration: const InputDecoration(labelText: 'UPI ID / VPA', border: OutlineInputBorder()),
                  ),
                  onSave: () => setState(() => _stepBankDone = true),
                );
              },
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // Step 6: Preferred Language & Categories
            _buildStepTile(
              title: 'Preferred Language & Categories',
              subtitle: 'Completed',
              isCompleted: true,
              isRecommended: false,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // ── Floating Review & Continue CTA Button ──────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showBottomReviewSheet(userName),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Review Application & Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
