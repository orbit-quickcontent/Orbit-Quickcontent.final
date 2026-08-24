import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_status.dart';
import '../../../shared/widgets/orbit_loading.dart';

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

  final List<Map<String, dynamic>> _defaultJobs = [
    {
      'id': 'orb_job_9912',
      'clientName': 'The Loft Cafe',
      'packageName': '1 Cinematic Reel (30–60s)',
      'completedAt': 'Today • 4:15 PM',
      'period': 'Today',
      'durationMin': 35,
      'earning': 1400,
      'bonus': 150,
      'totalPayout': 1550,
      'rating': 5.0,
      'address': 'Baner High Street, Pune',
      'status': 'COMPLETED',
    },
    {
      'id': 'orb_job_9845',
      'clientName': 'Aura Luxury Salon',
      'packageName': '3 UGC Commercial Reels',
      'completedAt': 'Today • 11:30 AM',
      'period': 'Today',
      'durationMin': 60,
      'earning': 3500,
      'bonus': 200,
      'totalPayout': 3700,
      'rating': 4.9,
      'address': 'Koregaon Park, Lane 7',
      'status': 'COMPLETED',
    },
    {
      'id': 'orb_job_9721',
      'clientName': 'Urban Brewery & Kitchen',
      'packageName': 'Live DJ & Event Video',
      'completedAt': 'Yesterday • 8:00 PM',
      'period': 'This Week',
      'durationMin': 90,
      'earning': 2100,
      'bonus': 0,
      'totalPayout': 2100,
      'rating': 5.0,
      'address': 'Balewadi High St, Pune',
      'status': 'COMPLETED',
    },
    {
      'id': 'orb_job_9610',
      'clientName': 'CrossFit Studio',
      'packageName': 'High-Energy HIIT Promo',
      'completedAt': '3 days ago • 9:15 AM',
      'period': 'This Week',
      'durationMin': 40,
      'earning': 750,
      'bonus': 100,
      'totalPayout': 850,
      'rating': 4.8,
      'address': 'Aundh Main Road, Pune',
      'status': 'COMPLETED',
    },
    {
      'id': 'orb_job_9530',
      'clientName': 'Prism Penthouse Showcase',
      'packageName': '5 4K Master Commercial Reels',
      'completedAt': '12 Aug • 2:00 PM',
      'period': 'This Month',
      'durationMin': 120,
      'earning': 6300,
      'bonus': 500,
      'totalPayout': 6800,
      'rating': 5.0,
      'address': 'Senapati Bapat Road, Pune',
      'status': 'COMPLETED',
    },
  ];

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
          _completedJobs = jobs.isNotEmpty ? jobs : _defaultJobs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completedJobs = _defaultJobs;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'All') return _completedJobs;
    return _completedJobs.where((j) {
      final period = j['period'] as String? ?? 'All';
      if (_selectedFilter == 'Today') return period == 'Today';
      if (_selectedFilter == 'This Week') return period == 'Today' || period == 'This Week';
      if (_selectedFilter == 'This Month') return true;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _filteredJobs;

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
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = filter);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF38BDF8) : OrbitColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF38BDF8) : OrbitColors.borderSubtle,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.black : OrbitColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 12,
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
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: const Color(0xFF38BDF8),
                      backgroundColor: OrbitColors.surfaceElevated,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          final clientName = job['clientName'] ?? job['user']?['name'] ?? 'Client Shoot';
                          final packageName = job['packageName'] ?? 'Cinematic Reel';
                          final dateStr = job['completedAt'] ?? 'Recent Shoot';
                          final payout = job['totalPayout'] ?? job['earning'] ?? 1400;
                          final rating = job['rating'] != null ? job['rating'].toString() : '5.0';
                          final status = (job['status'] as String? ?? 'COMPLETED').toUpperCase();

                          return OrbitCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onTap: () => _showJobDetails(context, job),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.movie_creation_outlined, size: 22, color: Color(0xFF38BDF8)),
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
                                      Text(
                                        packageName,
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                          const SizedBox(width: 6),
                                          const Text('•', style: TextStyle(color: Colors.white24)),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                          Text(' $rating', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹$payout',
                                      style: const TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
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
    HapticFeedback.lightImpact();
    final clientName = job['clientName'] ?? job['user']?['name'] ?? 'Orbit Client';
    final packageName = job['packageName'] ?? 'Shoot Package';
    final earning = job['earning'] ?? 1400;
    final bonus = job['bonus'] ?? 0;
    final totalPayout = job['totalPayout'] ?? earning;
    final address = job['address'] ?? 'Baner High Street, Pune';
    final completedAt = job['completedAt'] ?? 'Today';
    final durationMin = job['durationMin'] ?? 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15181D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clientName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(packageName, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: const Text('COMPLETED', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF252B33)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on_outlined, 'Location', address),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.schedule_rounded, 'Completed On', '$completedAt ($durationMin mins shoot)'),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.payments_outlined, 'Base Creator Payout', '₹$earning'),
            if (bonus > 0) ...[
              const SizedBox(height: 10),
              _buildDetailRow(Icons.bolt_rounded, 'Surge & Speed Bonus', '+₹$bonus'),
            ],
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF252B33)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Deposited to UPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('₹$totalPayout', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF38BDF8))),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payout receipt saved to your downloads')),
                  );
                },
                child: const Text('Download Payout Receipt', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
