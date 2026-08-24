import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../auth/providers/partner_auth_provider.dart';

class PartnerProfileScreen extends ConsumerStatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  ConsumerState<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends ConsumerState<PartnerProfileScreen> {
  Map<String, dynamic>? _profile;
  String _displayName = 'Utkarsh P';
  String _phone = '+91 98765 43210';
  String _upiId = 'partner@okhdfcbank';
  String _bankName = 'HDFC Bank (A/C •••• 4921)';
  String _operatingCity = 'Mumbai, Maharashtra';
  bool _instantPayoutEnabled = true;
  bool _soundAlerts = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await partnerApiClient.get('/partner/profile');
      if (mounted) {
        setState(() {
          _profile = res.data;
          final user = _profile?['user'] ?? {};
          if (_profile?['displayName'] != null) _displayName = _profile!['displayName'];
          if (user['name'] != null) _displayName = user['name'];
          if (_profile?['phone'] != null) _phone = _profile!['phone'];
          if (_profile?['upiId'] != null) _upiId = _profile!['upiId'];
          if (_profile?['city'] != null) _operatingCity = _profile!['city'];
        });
      }
    } catch (_) {}
  }

  // ── Personal Information Modal ─────────────────────────────────────────────
  void _showPersonalInfoModal() {
    HapticFeedback.mediumImpact();
    final nameCtrl = TextEditingController(text: _displayName);
    final phoneCtrl = TextEditingController(text: _phone);
    final cityCtrl = TextEditingController(text: _operatingCity);
    final gearCtrl = TextEditingController(text: 'Sony FX3 + 24-70mm GM II, DJI RS3, DJI Mic 2');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 10),
                  Text('Personal Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              _buildFieldLabel('FULL NAME'),
              _buildTextField(nameCtrl, 'Enter your full name'),
              const SizedBox(height: 14),
              _buildFieldLabel('PHONE NUMBER'),
              _buildTextField(phoneCtrl, 'Enter phone number', keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _buildFieldLabel('PRIMARY OPERATING CITY / ZONE'),
              _buildTextField(cityCtrl, 'e.g. Mumbai / Bandra & South Mumbai'),
              const SizedBox(height: 14),
              _buildFieldLabel('PRIMARY GEAR & CAMERA SETUP'),
              _buildTextField(gearCtrl, 'Camera, lenses, audio equipment', maxLines: 2),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() {
                      _displayName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _displayName;
                      _phone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _phone;
                      _operatingCity = cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : _operatingCity;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Personal information updated successfully!'),
                        backgroundColor: Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bank & UPI Details Modal ───────────────────────────────────────────────
  void _showBankDetailsModal() {
    HapticFeedback.mediumImpact();
    final upiCtrl = TextEditingController(text: _upiId);
    final bankCtrl = TextEditingController(text: _bankName);
    final ifscCtrl = TextEditingController(text: 'HDFC0001234');
    bool tempInstant = _instantPayoutEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF22C55E), size: 22),
                    SizedBox(width: 10),
                    Text('Bank & UPI Payout Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('PRIMARY UPI ID (FOR INSTANT PAYOUTS)'),
                _buildTextField(upiCtrl, 'e.g. partner@okhdfcbank'),
                const SizedBox(height: 14),
                _buildFieldLabel('BANK NAME & ACCOUNT'),
                _buildTextField(bankCtrl, 'e.g. HDFC Bank (A/C •••• 4921)'),
                const SizedBox(height: 14),
                _buildFieldLabel('IFSC CODE'),
                _buildTextField(ifscCtrl, 'e.g. HDFC0001234'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2027),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF252B33)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instant Daily Settlement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                          SizedBox(height: 2),
                          Text('Payouts credited automatically after each shoot', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: tempInstant,
                        activeThumbColor: const Color(0xFF22C55E),
                        onChanged: (val) => setModalState(() => tempInstant = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setState(() {
                        _upiId = upiCtrl.text.trim().isNotEmpty ? upiCtrl.text.trim() : _upiId;
                        _bankName = bankCtrl.text.trim().isNotEmpty ? bankCtrl.text.trim() : _bankName;
                        _instantPayoutEnabled = tempInstant;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payout details saved! Instant transfers active.'),
                          backgroundColor: Color(0xFF22C55E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Update Payout Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Documents & Verification Modal ─────────────────────────────────────────
  void _showDocumentsModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 22),
                SizedBox(width: 10),
                Text('Documents & Verification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 18),
            _buildDocItem('Government ID (Aadhaar / PAN)', 'Verified • KYC Approved', Icons.check_circle_rounded, const Color(0xFF22C55E)),
            const SizedBox(height: 12),
            _buildDocItem('Camera Gear & Equipment Audit', 'Verified • 4K 10-bit Master Certified', Icons.check_circle_rounded, const Color(0xFF22C55E)),
            const SizedBox(height: 12),
            _buildDocItem('Creator Showreel / Portfolio', 'Approved • Tier 1 Pro Badge', Icons.check_circle_rounded, const Color(0xFF22C55E)),
            const SizedBox(height: 12),
            _buildDocItem('Commercial Drone License', 'Optional • Not Uploaded', Icons.info_outline_rounded, Colors.grey),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document re-verification submitted to partner review desk')),
                  );
                },
                child: const Text('Re-upload or Update Documents', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifications & Sounds Modal ───────────────────────────────────────────
  void _showNotificationsModal() {
    HapticFeedback.mediumImpact();
    bool tempSound = _soundAlerts;
    bool tempHaptics = _hapticFeedback;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: Color(0xFF9333EA), size: 22),
                  SizedBox(width: 10),
                  Text('Dispatch Sound & Alerts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High Priority Sound Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Plays custom sound on incoming booking dispatch', style: TextStyle(color: Colors.white60, fontSize: 12)),
                value: tempSound,
                activeThumbColor: const Color(0xFF9333EA),
                onChanged: (val) => setModalState(() => tempSound = val),
              ),
              const Divider(color: Color(0xFF252B33)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic Vibration Pulses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Heavy vibration when client request is nearby', style: TextStyle(color: Colors.white60, fontSize: 12)),
                value: tempHaptics,
                activeThumbColor: const Color(0xFF9333EA),
                onChanged: (val) => setModalState(() => tempHaptics = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    setState(() {
                      _soundAlerts = tempSound;
                      _hapticFeedback = tempHaptics;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Help & Partner Support Modal ───────────────────────────────────────────
  void _showHelpSupportModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.support_agent_rounded, color: Color(0xFF38BDF8), size: 24),
                SizedBox(width: 10),
                Text('Partner Operations & Help Desk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('24/7 priority support for active shoots and creator queries', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
            const SizedBox(height: 20),
            // Call Support Button
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling Orbit Partner Desk: +91 1800-ORBIT-PRO')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2027),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF252B33)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E), size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Emergency Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Toll-Free 1800-ORBIT-PRO (Instant response)', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // WhatsApp Support
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening WhatsApp Partner Support channel...')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2027),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF252B33)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF22C55E), size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WhatsApp Partner Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Instant chat for shoot location & client issues', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Report Shoot Dispute
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket created: Partner support team will review within 10 mins')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2027),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF252B33)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Color(0xFFF59E0B), size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report Shoot / Client Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Client absent, weather delay, or extra reel request', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1C2027),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252B33))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF252B33))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2027),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252B33)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(partnerAuthProvider);
    final user = _profile?['user'] ?? {};
    final name = _displayName.isNotEmpty ? _displayName : (user['name'] ?? auth.name ?? 'Creator Partner');
    final email = user['email'] ?? auth.email ?? 'partner@orbit.app';
    final rating = _profile?['rating']?.toString() ?? '4.9';
    final partnerId = _profile?['id']?.toString().substring(0, 8).toUpperCase() ?? 'PTR-8829';

    final initials = name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join('').toUpperCase()
        : 'OP';

    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        backgroundColor: OrbitColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: Text(
          'CREATOR PROFILE',
          style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(OrbitSpacing.space16),
          children: [
            // ── 1. Compact Profile Identity Header ─────────────────────────
            OrbitCard(
              padding: const EdgeInsets.all(OrbitSpacing.space20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: OrbitColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: OrbitColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: OrbitTypography.headingMedium.copyWith(
                          color: OrbitColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: OrbitTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: OrbitColors.primary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $partnerId • ★ $rating • $_operatingCity',
                          style: OrbitTypography.bodySmall.copyWith(
                            color: OrbitColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: OrbitTypography.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrbitSpacing.space20),

            // ── 2. Settings & Account Grouped List ─────────────────────────
            Text(
              'ACCOUNT & PARTNER SETTINGS',
              style: OrbitTypography.labelSmall.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: OrbitSpacing.space8),

            OrbitCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileSettingRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    subtitle: '$name • $_phone',
                    onTap: _showPersonalInfoModal,
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.account_balance_outlined,
                    title: 'Bank & UPI Details',
                    subtitle: '$_upiId • $_bankName',
                    onTap: _showBankDetailsModal,
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.assignment_outlined,
                    title: 'Documents & Verification',
                    subtitle: 'Aadhaar, PAN & Gear Audit (Verified Tier 1)',
                    onTap: _showDocumentsModal,
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Dispatch Sounds',
                    subtitle: _soundAlerts ? 'Sound & Haptic alerts active' : 'Muted',
                    onTap: _showNotificationsModal,
                  ),
                  const Divider(color: OrbitColors.borderSubtle, height: 1),
                  _ProfileSettingRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Partner Support',
                    subtitle: '24/7 Toll-free Desk & WhatsApp Chat',
                    onTap: _showHelpSupportModal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrbitSpacing.space24),

            // ── 3. Danger Zone Log Out ─────────────────────────────────────
            OrbitDangerButton(
              label: 'LOG OUT OF ORBIT',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(partnerAuthProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: OrbitColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
      ),
      title: Text(title, style: OrbitTypography.titleSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: OrbitTypography.bodySmall.copyWith(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: OrbitColors.textMuted, size: 20),
    );
  }
}
