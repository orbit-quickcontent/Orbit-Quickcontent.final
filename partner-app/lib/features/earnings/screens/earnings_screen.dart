import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../analytics/analytics_service.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  int _todayTotal = 2450;
  final int _netFare = 2000;
  final int _promotions = 350;
  final int _tips = 100;
  final String _onlineTime = '2 h 53 m';
  int _completedTrips = 6;
  int _selectedDayIndex = 0; // Mon

  final List<Map<String, dynamic>> _weekDays = [
    {'day': 'Mon', 'date': '29', 'amount': 2450, 'ratio': 0.95},
    {'day': 'Tue', 'date': '30', 'amount': 0, 'ratio': 0.0},
    {'day': 'Wed', 'date': '31', 'amount': 0, 'ratio': 0.0},
    {'day': 'Thu', 'date': '1', 'amount': 1600, 'ratio': 0.65},
    {'day': 'Fri', 'date': '2', 'amount': 0, 'ratio': 0.0},
    {'day': 'Sat', 'date': '3', 'amount': 0, 'ratio': 0.0},
    {'day': 'Sun', 'date': '4', 'amount': 0, 'ratio': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_earnings_dashboard');
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final res = await partnerApiClient.get('/partner/earnings/summary');
      if (mounted && res.data != null) {
        setState(() {
          final t = res.data['todayEarnings'];
          if (t != null && t is int && t > 0) _todayTotal = t;
          final c = res.data['completedToday'];
          if (c != null && c is int && c > 0) _completedTrips = c;
        });
      }
    } catch (_) {}
  }

  void _showWithdrawModal() {
    OrbitMotion.lightTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Instant Payout Withdrawal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2027),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF252B33)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Withdrawable Balance', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹$_todayTotal', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Instant IMPS / UPI', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Transfer to verified UPI ID: utkarsh@okhdfcbank', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₹$_todayTotal payout initiated to your bank account via instant IMPS.'),
                      backgroundColor: const Color(0xFF22C55E),
                    ),
                  );
                },
                child: const Text('Confirm Instant Transfer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D10),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left_rounded, color: Colors.white70),
            SizedBox(width: 4),
            Text('This Week', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF38BDF8)),
            onPressed: _showWithdrawModal,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Top Headline Earnings Amount ($64.62 / ₹2,450) ───────────────
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(color: Color(0xFF22C55E), fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$_todayTotal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Net Earnings • Mon, 29 Aug',
                    style: TextStyle(color: OrbitColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Weekly Interactive Bar Chart ─────────────────────────────────
            Container(
              height: 170,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF15181D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF252B33)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_weekDays.length, (idx) {
                        final d = _weekDays[idx];
                        final ratio = (d['ratio'] as num).toDouble();
                        final isSel = idx == _selectedDayIndex;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDayIndex = idx),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 26,
                                height: (100 * ratio).clamp(4.0, 100.0),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF3B82F6)
                                      : (ratio > 0 ? const Color(0xFF1E3A5F) : const Color(0xFF1F242D)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                d['date']!,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF38BDF8) : Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                d['day']!,
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF38BDF8) : Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats Row (Online, Trips, Points) ────────────────────────────
            const Text(
              'Stats',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF15181D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF252B33)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Online', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_onlineTime, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF252B33)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shoots', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('$_completedTrips', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF252B33)),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rating', style: TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                      SizedBox(height: 4),
                      Text('4.9 ★', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Itemized Financial Breakdown ─────────────────────────────────
            const Text(
              'Breakdown',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF15181D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF252B33)),
              ),
              child: Column(
                children: [
                  _buildBreakdownRow('Net Fare / Base Shoots', '₹$_netFare'),
                  const Divider(color: Color(0xFF252B33), height: 24),
                  _buildBreakdownRow('Promotions & Surge', '₹$_promotions'),
                  const Divider(color: Color(0xFF252B33), height: 24),
                  _buildBreakdownRow('Client Tips', '₹$_tips'),
                  const Divider(color: Color(0xFF38BDF8), height: 24, thickness: 1.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Earnings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      Text('₹$_todayTotal', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Instant Withdrawal Action Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _showWithdrawModal,
                icon: const Icon(Icons.payments_outlined, color: Colors.black),
                label: const Text(
                  'WITHDRAW TO BANK / UPI',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
