import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await apiClient.get('/notifications');
      setState(() { _notifications = List<Map<String, dynamic>>.from(res.data); _isLoading = false; });
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _markAllRead() async {
    await apiClient.patch('/notifications/read-all');
    setState(() { for (var n in _notifications) { n['isRead'] = true; } });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Notifications', style: OrbitClientTheme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: _markAllRead, child: Text('Mark all read', style: TextStyle(color: OrbitClientTheme.primaryFixed, fontSize: 13))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: OrbitClientTheme.primaryFixed))
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (b) => OrbitClientTheme.primaryGradient.createShader(b), child: const Icon(Icons.notifications_none, size: 64, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text('No notifications', style: OrbitClientTheme.textTheme.titleLarge),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    final isRead = n['isRead'] == true;
                    return OrbitGlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: isRead ? null : OrbitClientTheme.primaryGradient, color: isRead ? Colors.transparent : null),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['title'] ?? '', style: OrbitClientTheme.textTheme.titleMedium?.copyWith(fontWeight: isRead ? FontWeight.w400 : FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(n['body'] ?? '', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                        ])),
                      ]),
                    );
                  },
                ),
    );
  }
}
