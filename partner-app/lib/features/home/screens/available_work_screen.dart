import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../auth/providers/partner_auth_provider.dart';

const String _kSocketUrl = String.fromEnvironment('SOCKET_URL', defaultValue: 'http://10.0.2.2:5000');

class AvailableWorkScreen extends ConsumerStatefulWidget {
  const AvailableWorkScreen({super.key});

  @override
  ConsumerState<AvailableWorkScreen> createState() => _AvailableWorkScreenState();
}

class _AvailableWorkScreenState extends ConsumerState<AvailableWorkScreen> {
  bool _isOnline = false;
  List<Map<String, dynamic>> _dispatches = [];
  bool _isLoading = true;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _fetchDispatches();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'orbit_partner_token');
    _socket = io.io(_kSocketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());
    _socket!.connect();
    // Listen for real-time dispatch offers
    _socket!.on('booking:offered', (data) {
      if (mounted && data is Map) {
        context.push('/incoming', extra: Map<String, dynamic>.from(data));
      }
    });
    // Refresh list on any booking state change
    _socket!.on('booking:status-update', (_) => _fetchDispatches());
  }

  Future<void> _loadStatus() async {
    try {
      final res = await partnerApiClient.get('/partner/profile');
      if (mounted) {
        setState(() {
          _isOnline = res.data['isOnline'] ?? false;
        });
        ref.read(partnerAuthProvider.notifier).setOnlineStatus(_isOnline);
      }
    } catch (_) {}
  }

  Future<void> _fetchDispatches() async {
    try {
      final res = await partnerApiClient.get('/partner/dispatches/pending');
      if (mounted) {
        setState(() {
          _dispatches = List<Map<String, dynamic>>.from(res.data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    ref.read(partnerAuthProvider.notifier).setOnlineStatus(value);
    try {
      await partnerApiClient.patch('/partner/status', data: {'isOnline': value});
    } catch (_) {
      setState(() => _isOnline = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitPartnerTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            OnlineStatusDot(isOnline: _isOnline),
            const SizedBox(width: 8),
            Text(_isOnline ? 'Online & Available' : 'Offline', style: OrbitPartnerTheme.textTheme.titleMedium),
          ],
        ),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeColor: OrbitPartnerTheme.primary,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDispatches,
        color: OrbitPartnerTheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isOnline ? OrbitPartnerTheme.primary.withOpacity(0.08) : OrbitPartnerTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? OrbitPartnerTheme.primary.withOpacity(0.3) : OrbitPartnerTheme.outlineFaint,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.radar : Icons.power_settings_new,
                    color: _isOnline ? OrbitPartnerTheme.primary : OrbitPartnerTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isOnline
                          ? 'You are active in the dispatch pool. New bookings nearby will appear automatically.'
                          : 'You are currently offline. Toggle online to receive shoot opportunities.',
                      style: OrbitPartnerTheme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('AVAILABLE SHOOT OFFERS', style: OrbitPartnerTheme.textTheme.labelSmall),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: OrbitPartnerTheme.primary)))
            else if (_dispatches.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OrbitPartnerTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OrbitPartnerTheme.outlineFaint),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: OrbitPartnerTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text('No Work Available Right Now', style: OrbitPartnerTheme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Stay online. We will notify you immediately when a client nearby requests a shoot.',
                      style: OrbitPartnerTheme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._dispatches.map((d) {
                final booking = d['booking'] ?? {};
                final pkg = booking['package'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OrbitPartnerTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OrbitPartnerTheme.primary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pkg['name'] ?? 'Shoot Request', style: OrbitPartnerTheme.textTheme.titleMedium),
                          Text('₹500 Payout', style: TextStyle(color: OrbitPartnerTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(booking['address'] ?? 'Location pending', style: OrbitPartnerTheme.textTheme.bodySmall),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await partnerApiClient.post('/bookings/${booking['id']}/decline');
                                _fetchDispatches();
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final router = GoRouter.of(context);
                                await partnerApiClient.post('/bookings/${booking['id']}/accept');
                                if (mounted) router.push('/job/${booking['id']}');
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: OrbitPartnerTheme.primary, foregroundColor: Colors.black),
                              child: const Text('Accept Shoot'),
                            ),
                          ),
                        ],
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
