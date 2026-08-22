import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/orbit_map_workspace.dart';
import '../../../analytics/analytics_service.dart';

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
  Timer? _shootTimer;
  int _shootSeconds = 0;

  // Checklist State for Content Creation
  bool _chkLocation = true;
  bool _chkFraming = true;
  bool _chkMainHook = false;
  bool _chkBroll = false;
  bool _chkFinalClip = false;

  // Upload progress state
  double _uploadProgress = 0.0;
  Timer? _uploadTimer;

  static const List<String> _stages = [
    'ACCEPTED',
    'EN_ROUTE',
    'ARRIVED',
    'SHOOTING',
    'UPLOADING',
    'COMPLETED',
  ];

  @override
  void initState() {
    super.initState();
    partnerAnalytics.trackScreenView('partner_active_job');
    _loadJob();
  }

  @override
  void dispose() {
    _shootTimer?.cancel();
    _uploadTimer?.cancel();
    super.dispose();
  }

  void _startShootTimer() {
    _shootTimer?.cancel();
    _shootTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _shootSeconds++);
    });
  }

  Future<void> _loadJob() async {
    try {
      final res = await partnerApiClient.get('/bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data;
          _isLoading = false;
          final currentStatus = (_booking?['status'] as String? ?? '').toUpperCase();
          if (currentStatus == 'SHOOTING' && _shootTimer == null) {
            _startShootTimer();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String action, {Map<String, dynamic>? payload}) async {
    setState(() => _isActionRunning = true);
    OrbitMotion.lightTap();

    try {
      if (action == 'en-route' || action == 'en_route') {
        partnerAnalytics.trackNavigationStarted(bookingId: widget.bookingId);
      } else if (action == 'arrived') {
        partnerAnalytics.trackArrival(bookingId: widget.bookingId);
      } else if (action == 'start-shoot') {
        partnerAnalytics.trackShootStarted(bookingId: widget.bookingId);
        _startShootTimer();
      } else if (action == 'complete-shoot') {
        _shootTimer?.cancel();
        partnerAnalytics.trackShootCompleted(bookingId: widget.bookingId, durationMinutes: (_shootSeconds / 60).ceil());
        _startSimulatedUpload();
      }

      await partnerApiClient.post('/bookings/${widget.bookingId}/$action', data: payload);
      await _loadJob();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update job status. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  void _startSimulatedUpload() {
    setState(() {
      _uploadProgress = 0.1;
    });
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (_uploadProgress < 1.0) {
        if (mounted) {
          setState(() {
            _uploadProgress += 0.12;
            if (_uploadProgress >= 1.0) {
              _uploadProgress = 1.0;
              t.cancel();
            }
          });
        }
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _getStageIndex(String status) {
    final s = status.toUpperCase();
    if (s == 'DISPATCHING' || s == 'PARTNER_ASSIGNED' || s == 'ACCEPTED') return 0;
    if (s == 'EN_ROUTE' || s == 'EN-ROUTE') return 1;
    if (s == 'ARRIVED') return 2;
    if (s == 'SHOOTING') return 3;
    if (s == 'UPLOADING' || s == 'DELIVERED') return 4;
    if (s == 'COMPLETED' || s == 'PAYOUT_COMPLETED') return 5;
    return _stages.indexOf(s).clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0D10),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))),
      );
    }

    final status = (_booking?['status'] as String? ?? 'ACCEPTED').toUpperCase();
    final stageIdx = _getStageIndex(status);
    final isShooting = status == 'SHOOTING';
    final isUploading = status == 'UPLOADING' || _uploadProgress > 0;
    final isCompleted = status == 'COMPLETED' || stageIdx >= 5;

    final clientName = _booking?['client']?['name'] ?? _booking?['user']?['name'] ?? 'Jenny / Alex';
    final locationName = _booking?['locationName'] ?? _booking?['address'] ?? 'The Loft Cafe';
    final pkgName = _booking?['package']?['name'] ?? '1 Reel (30s vertical)';
    final earning = _booking?['partnerSalary'] ?? _booking?['earning'] ?? 500;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: Stack(
        children: [
          // ── 1. Fullscreen Navigation Map Workspace ────────────────────────
          OrbitMapWorkspace(
            isOnline: true,
            isNavigating: stageIdx <= 1,
            destinationAddress: locationName,
          ),

          // ── 2. Top Turn-By-Turn Navigation Banner (When En Route) ─────────
          if (stageIdx <= 1)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15181D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.turn_right_rounded, color: Color(0xFF38BDF8), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('300 ft • Turn Right', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text('Toward $locationName', style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 3. Bottom Progressive Stage Sheet ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF15181D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF252B33), width: 1.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, -6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage 1: EN ROUTE
                  if (stageIdx <= 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Client notified', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(clientName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                                child: const Icon(Icons.call_outlined, color: Colors.white, size: 18),
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                                child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF38BDF8), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(locationName, style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isActionRunning ? null : () => _updateStatus('arrived'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("I'VE ARRIVED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ]

                  // Stage 2: ARRIVED
                  else if (stageIdx == 2) ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24),
                        SizedBox(width: 8),
                        Text("YOU'VE ARRIVED", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$locationName • $pkgName', style: const TextStyle(color: OrbitColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isActionRunning ? null : () => _updateStatus('start-shoot'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.black, size: 22),
                            SizedBox(width: 8),
                            Text("START SHOOT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ]

                  // Stage 3: SHOOTING
                  else if (isShooting) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                            ),
                            const SizedBox(width: 8),
                            const Text('SHOOTING IN PROGRESS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                          ],
                        ),
                        Text(
                          _formatTimer(_shootSeconds),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Shoot Checklist
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2027),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF252B33)),
                      ),
                      child: Column(
                        children: [
                          _buildChecklistRow('Location confirmed', _chkLocation, () => setState(() => _chkLocation = !_chkLocation)),
                          _buildChecklistRow('Vertical framing & 4K 60fps set', _chkFraming, () => setState(() => _chkFraming = !_chkFraming)),
                          _buildChecklistRow('Main subject & hook captured', _chkMainHook, () => setState(() => _chkMainHook = !_chkMainHook)),
                          _buildChecklistRow('Cinematic B-Roll captured', _chkBroll, () => setState(() => _chkBroll = !_chkBroll)),
                          _buildChecklistRow('Final clip & audio synced', _chkFinalClip, () => setState(() => _chkFinalClip = !_chkFinalClip)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isActionRunning ? null : () => _updateStatus('complete-shoot'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("FINISH SHOOT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ]

                  // Stage 4: UPLOADING FOOTAGE
                  else if (isUploading && !isCompleted) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('UPLOAD FOOTAGE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('3 clips • Uploading master footage securely...', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: const Color(0xFF252B33),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_uploadProgress >= 1.0)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _updateStatus('complete'),
                          child: const Text("COMPLETE & CLAIM EARNINGS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                  ]

                  // Stage 5: JOB COMPLETE
                  else ...[
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: Colors.black, size: 36),
                          ),
                          const SizedBox(height: 12),
                          const Text('JOB COMPLETE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('₹$earning added to your wallet', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              onPressed: () => context.go('/work'),
                              child: const Text('BACK TO HOME', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String title, bool isChecked, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isChecked ? const Color(0xFF22C55E) : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isChecked ? Colors.white : Colors.grey.shade400,
                  fontSize: 12.5,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
