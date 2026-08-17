import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class ActiveJobScreen extends StatefulWidget {
  final String bookingId;
  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final res = await partnerApiClient.get('/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String action) async {
    setState(() => _isActionRunning = true);
    try {
      await partnerApiClient.post('/bookings/${widget.bookingId}/$action');
      await _loadJob();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: OrbitPartnerTheme.background,
        appBar: AppBar(title: const Text('Active Job'), backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator(color: OrbitPartnerTheme.primary)),
      );
    }

    final status = _booking?['status'] ?? '';
    final pkg = _booking?['package'] ?? {};

    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      appBar: AppBar(
        title: Text(pkg['name'] ?? 'Active Shoot'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: OrbitPartnerTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OrbitPartnerTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('STATUS', style: OrbitPartnerTheme.textTheme.labelSmall),
                    Text('₹500 Payout', style: TextStyle(color: OrbitPartnerTheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(status.replaceAll('_', ' '), style: OrbitPartnerTheme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                const Divider(color: OrbitPartnerTheme.outlineFaint),
                const SizedBox(height: 12),
                Text('CLIENT LOCATION', style: OrbitPartnerTheme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(_booking?['address'] ?? 'No address provided', style: OrbitPartnerTheme.textTheme.bodyMedium),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Workflow based on state
          if (status == 'PARTNER_ASSIGNED') ...[
            PartnerButton(
              label: 'Start Navigating to Client',
              color: OrbitPartnerTheme.primary,
              isLoading: _isActionRunning,
              onPressed: () => _updateStatus('en-route'),
            ),
            const SizedBox(height: 12),
            Text(
              'Navigate to the client location then confirm arrival',
              style: OrbitPartnerTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ] else if (status == 'EN_ROUTE') ...[
            PartnerButton(
              label: 'I Have Arrived at Location',
              color: OrbitPartnerTheme.primary,
              isLoading: _isActionRunning,
              onPressed: () => _updateStatus('arrived'),
            ),
          ] else if (status == 'ARRIVED') ...[
            PartnerButton(
              label: 'Start Video Shoot',
              color: OrbitPartnerTheme.primary,
              isLoading: _isActionRunning,
              onPressed: () => _updateStatus('start-shoot'),
            ),
          ] else if (status == 'SHOOTING') ...[
            PartnerButton(
              label: 'Complete Shoot & Start Upload',
              color: OrbitPartnerTheme.primary,
              isLoading: _isActionRunning,
              onPressed: () => _updateStatus('complete-shoot'),
            ),
          ] else if (status == 'UPLOADING') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OrbitPartnerTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: OrbitPartnerTheme.primary),
                  const SizedBox(height: 16),
                  Text('Uploading Footage to Cloud...', style: OrbitPartnerTheme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Keep the app open until transfer completes.', style: OrbitPartnerTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ] else if (status == 'SYNCED' || status == 'EDITING' || status == 'DELIVERED') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OrbitPartnerTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: OrbitPartnerTheme.primary, size: 48),
                  const SizedBox(height: 12),
                  Text('Shoot Completed!', style: OrbitPartnerTheme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Footage sent to editing team. ₹500 credited on delivery.', style: OrbitPartnerTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
