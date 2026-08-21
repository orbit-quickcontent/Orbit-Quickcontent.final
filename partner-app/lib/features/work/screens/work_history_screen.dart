import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';

class WorkHistoryScreen extends ConsumerStatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  ConsumerState<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends ConsumerState<WorkHistoryScreen> {
  List<Map<String, dynamic>> _completedJobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = ['Today', 'This Week', 'This Month', 'All'];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await partnerApiClient.get('/partner/history');
      final jobs = List<Map<String, dynamic>>.from(res.data['jobs'] ?? []);
      if (mounted) {
        setState(() {
          _completedJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        backgroundColor: OrbitColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/work'),
        ),
        title: Text(
          'PAST SHOOTS & JOBS',
          style: OrbitTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Period Filter Chips ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: OrbitColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? OrbitColors.primary : OrbitColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? OrbitColors.primary : OrbitColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: OrbitTypography.labelSmall.copyWith(
                              color: isSelected ? Colors.white : OrbitColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(color: OrbitColors.borderSubtle, height: 1),

            // ── Jobs List / Rows ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: OrbitLoadingCard(height: 100))
                  : _completedJobs.isEmpty
                      ? const OrbitEmptyState(
                          icon: Icons.history_rounded,
                          title: 'No shoot history yet',
                          description: 'When you accept and complete shoot bookings, they will be listed here with payout receipts.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: OrbitColors.primary,
                          backgroundColor: OrbitColors.surfaceElevated,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _completedJobs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final job = _completedJobs[index];
                              final clientName = job['user']?['name'] ?? job['clientName'] ?? 'Client Shoot';
                              final dateStr = job['completedAt'] != null || job['createdAt'] != null
                                  ? '22 Aug • 7:45 PM'
                                  : 'Recent Shoot';
                              final payout = job['partnerSalary'] ?? job['earning'] ?? 500;
                              final status = (job['status'] as String? ?? 'COMPLETED').toUpperCase();

                              return OrbitCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                onTap: () => _showJobDetails(context, job),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: OrbitColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.videocam_outlined, size: 20, color: OrbitColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            style: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(dateStr, style: OrbitTypography.bodySmall.copyWith(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹$payout',
                                          style: OrbitTypography.titleMedium.copyWith(
                                            color: OrbitColors.success,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        OrbitStatusPill.fromStatus(status),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> job) {
    final clientName = job['user']?['name'] ?? job['clientName'] ?? 'Orbit Client';
    final payout = job['partnerSalary'] ?? job['earning'] ?? 500;
    final address = job['address'] ?? 'Client Location';

    showModalBottomSheet(
      context: context,
      backgroundColor: OrbitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: OrbitColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(clientName, style: OrbitTypography.headingMedium),
            const SizedBox(height: 4),
            Text(address, style: OrbitTypography.bodySmall),
            const SizedBox(height: 20),
            const Divider(color: OrbitColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Partner Salary Credit', style: OrbitTypography.bodyMedium),
                Text('₹$payout', style: OrbitTypography.titleLarge.copyWith(color: OrbitColors.success, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
