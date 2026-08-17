import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  int _selectedPersonaIndex = 0;
  bool _isAvatarMode = true;

  final List<Map<String, dynamic>> _personas = [
    {'name': 'Creator', 'icon': Icons.movie_creation_outlined, 'color': Color(0xFF00F0FF)},
    {'name': 'Professional', 'icon': Icons.business_center_outlined, 'color': Color(0xFF94A3B8)},
    {'name': 'Artist', 'icon': Icons.palette_outlined, 'color': Color(0xFF94A3B8)},
    {'name': 'Explorer', 'icon': Icons.explore_outlined, 'color': Color(0xFF94A3B8)},
    {'name': 'Visionary', 'icon': Icons.auto_awesome_outlined, 'color': Color(0xFF94A3B8)},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await apiClient.post('/auth/send-otp', data: {
        'email': email,
        'name': name,
        'phone': phone.isNotEmpty ? '+91$phone' : null,
        'persona': _personas[_selectedPersonaIndex]['name'],
      });

      if (!mounted) return;
      if (res.data['success'] == true) {
        context.push('/otp', extra: email);
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to send verification code');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data['message'] ?? e.response?.data['error'] ?? 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  @override
  Widget build(BuildContext context) {
    final selectedPersona = _personas[_selectedPersonaIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header: Logo + Account Pill ──────────────────────────────
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFFA056FF)],
                      ),
                    ),
                    child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ORBIT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF164E63)),
                  color: const Color(0xFF083344).withValues(alpha: 0.3),
                ),
                child: const Text(
                  'Client Account',
                  style: TextStyle(
                    color: Color(0xFF22D3EE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Hero Section ───────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Join the ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                    TextSpan(
                      text: 'Orbit',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in or create your account to get started',
                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 13),
              ),

              const SizedBox(height: 20),

              // ── Social Login Grid ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                          SizedBox(width: 4),
                          Text('Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.apple, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text('Apple', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Divider: OR EMAIL ──────────────────────────────────────────
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFF27272A))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR EMAIL',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF27272A))),
                ],
              ),

              const SizedBox(height: 20),

              // ── Profile Picture & Persona Section ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF18181B)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CHOOSE YOUR PROFILE PICTURE',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar Preview Circle
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF27272A), width: 3),
                        color: const Color(0xFF18181B),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00F0FF).withValues(alpha: 0.3),
                            const Color(0xFFA056FF).withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Icon(
                        selectedPersona['icon'] as IconData,
                        size: 44,
                        color: const Color(0xFF00F0FF),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Toggle Switch (Avatar / Photo)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isAvatarMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isAvatarMode ? const Color(0xFF3F3F46) : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.face, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Avatar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isAvatarMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isAvatarMode ? const Color(0xFF3F3F46) : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.photo_camera_outlined, size: 14, color: Color(0xFF71717A)),
                                  SizedBox(width: 4),
                                  Text('Photo', style: TextStyle(color: Color(0xFF71717A), fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Persona Grid (5 items)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_personas.length, (index) {
                          final p = _personas[index];
                          final isSelected = index == _selectedPersonaIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPersonaIndex = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF18181B) : const Color(0xFF09090B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF27272A),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.15) : const Color(0xFF18181B),
                                    ),
                                    child: Icon(
                                      p['icon'] as IconData,
                                      size: 18,
                                      color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF71717A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p['name'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF71717A),
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Form Fields Card ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF18181B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    const Text(
                      'FULL NAME *',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF111111),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00F0FF))),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Email Address
                    const Text(
                      'EMAIL ADDRESS *',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
                        prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF71717A), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF111111),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00F0FF))),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone
                    const Text(
                      'PHONE',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Text('+91', style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.w600, fontSize: 14)),
                          Container(margin: const EdgeInsets.symmetric(horizontal: 10), height: 20, width: 1, color: const Color(0xFF27272A)),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: '10-digit mobile number',
                                hintStyle: TextStyle(color: Color(0xFF71717A), fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('India mobile numbers only', style: TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                        Text('0/10', style: TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF93000A).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB4AB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFFB4AB), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Continue Action Button ─────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _sendOtp,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF6E208C)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.mail_outline, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Continue to Verify Email',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                'You will need to verify your email before continuing.',
                style: TextStyle(color: Color(0xFF60A5FA), fontSize: 11),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
