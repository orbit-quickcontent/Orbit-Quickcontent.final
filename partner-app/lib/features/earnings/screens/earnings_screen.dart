import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final wRes = await partnerApiClient.get('/wallet');
      final tRes = await partnerApiClient.get('/wallet/transactions');
      if (mounted) {
        setState(() {
          _wallet = wRes.data;
          _transactions = List<Map<String, dynamic>>.from(tRes.data['transactions'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _wallet?['available'] ?? 0;
    final totalEarned = _wallet?['totalEarned'] ?? 0;

    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      appBar: AppBar(
        title: const Text('Earnings & Wallet'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: OrbitPartnerTheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F291E), Color(0xFF0A1410)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE BALANCE', style: OrbitPartnerTheme.textTheme.labelSmall?.copyWith(color: OrbitPartnerTheme.primary)),
                  const SizedBox(height: 8),
                  Text('₹$available', style: OrbitPartnerTheme.textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 38)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Total Lifetime Earned: ', style: OrbitPartnerTheme.textTheme.bodySmall),
                      Text('₹$totalEarned', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('RECENT PAYOUTS & TRANSACTIONS', style: OrbitPartnerTheme.textTheme.labelSmall),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: OrbitPartnerTheme.primary)))
            else if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OrbitPartnerTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OrbitPartnerTheme.outlineFaint),
                ),
                child: Text('No transactions yet. Complete your first shoot!', style: OrbitPartnerTheme.textTheme.bodySmall),
              )
            else
              ..._transactions.map((t) {
                final isCredit = t['type'] == 'CREDIT';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OrbitPartnerTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OrbitPartnerTheme.outlineFaint),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isCredit ? OrbitPartnerTheme.primary : OrbitPartnerTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['description'] ?? 'Booking Payout', style: OrbitPartnerTheme.textTheme.titleMedium),
                            Text(t['createdAt']?.toString().substring(0, 10) ?? '', style: OrbitPartnerTheme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(
                        '${isCredit ? '+' : '-'}₹${t['amount']}',
                        style: TextStyle(
                          color: isCredit ? OrbitPartnerTheme.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
