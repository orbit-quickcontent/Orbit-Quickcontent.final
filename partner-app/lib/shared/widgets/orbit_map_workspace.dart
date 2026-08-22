import 'package:flutter/material.dart';

class OrbitMapWorkspace extends StatefulWidget {
  final bool isOnline;
  final bool isNavigating;
  final String? destinationAddress;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSafetyPressed;
  final VoidCallback? onRecenterPressed;
  final List<DemandZone>? demandZones;

  const OrbitMapWorkspace({
    super.key,
    required this.isOnline,
    this.isNavigating = false,
    this.destinationAddress,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onSafetyPressed,
    this.onRecenterPressed,
    this.demandZones,
  });

  @override
  State<OrbitMapWorkspace> createState() => _OrbitMapWorkspaceState();
}

class _OrbitMapWorkspaceState extends State<OrbitMapWorkspace> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset _mapOffset = Offset.zero;
  final double _mapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _mapOffset += details.delta;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Dark Styled Operational Map Canvas ──
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return CustomPaint(
                painter: _DarkMapPainter(
                  pulseValue: _pulseController.value,
                  isOnline: widget.isOnline,
                  isNavigating: widget.isNavigating,
                  offset: _mapOffset,
                  scale: _mapScale,
                  demandZones: widget.demandZones ?? _defaultDemandZones,
                ),
              );
            },
          ),

          // ── Floating Safety Shield (Bottom-Left above sheet) ──
          Positioned(
            left: 16,
            bottom: 110,
            child: GestureDetector(
              onTap: widget.onSafetyPressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF15181D),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 20),
                ),
              ),
            ),
          ),

          // ── Floating Speed / GPS Recenter (Bottom-Right) ──
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isNavigating) ...[
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('35', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, height: 1.0)),
                        Text('LIMIT', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mapOffset = Offset.zero;
                    });
                    widget.onRecenterPressed?.call();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15181D),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF252B33), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DemandZone {
  final String label;
  final String surge;
  final double xRatio;
  final double yRatio;
  final Color color;

  const DemandZone({
    required this.label,
    required this.surge,
    required this.xRatio,
    required this.yRatio,
    required this.color,
  });
}

const List<DemandZone> _defaultDemandZones = [
  DemandZone(
    label: '1-2 min',
    surge: '+₹200 Surge',
    xRatio: 0.32,
    yRatio: 0.30,
    color: Color(0xFFE11D48),
  ),
  DemandZone(
    label: '1-4 min',
    surge: '+₹150 High',
    xRatio: 0.76,
    yRatio: 0.34,
    color: Color(0xFFEA580C),
  ),
  DemandZone(
    label: '1-4 min',
    surge: 'Active Shoots',
    xRatio: 0.42,
    yRatio: 0.40,
    color: Color(0xFFF59E0B),
  ),
  DemandZone(
    label: '1-5 min',
    surge: 'Studio Zone',
    xRatio: 0.80,
    yRatio: 0.48,
    color: Color(0xFFF59E0B),
  ),
];

/// Premium Dark Vector Map Canvas Painter
class _DarkMapPainter extends CustomPainter {
  final double pulseValue;
  final bool isOnline;
  final bool isNavigating;
  final Offset offset;
  final double scale;
  final List<DemandZone> demandZones;

  _DarkMapPainter({
    required this.pulseValue,
    required this.isOnline,
    required this.isNavigating,
    required this.offset,
    required this.scale,
    required this.demandZones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Dark Base Map Land
    final bgPaint = Paint()..color = const Color(0xFF0D1117);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. City Blocks & Landuse geometry
    final blockPaint = Paint()..color = const Color(0xFF131822);
    for (double x = -100 + (offset.dx % 120); x < w + 120; x += 120) {
      for (double y = -100 + (offset.dy % 140); y < h + 140; y += 140) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 10, y + 10, 100, 120), const Radius.circular(10)),
          blockPaint,
        );
      }
    }

    // 3. Grid Road Network
    final roadPaint = Paint()
      ..color = const Color(0xFF1C2430)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = const Color(0xFF171E28)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < h; y += 70) {
      canvas.drawLine(Offset(0, y + (offset.dy % 70)), Offset(w, y + (offset.dy % 70)), minorRoadPaint);
    }
    for (double x = 0; x < w; x += 60) {
      canvas.drawLine(Offset(x + (offset.dx % 60), 0), Offset(x + (offset.dx % 60), h), minorRoadPaint);
    }

    // Diagonal Arterials
    final arterialPath = Path()
      ..moveTo(0, h * 0.2 + offset.dy)
      ..lineTo(w * 0.45 + offset.dx, h * 0.5 + offset.dy)
      ..lineTo(w, h * 0.85 + offset.dy);
    canvas.drawPath(arterialPath, roadPaint);

    final arterialPath2 = Path()
      ..moveTo(w, h * 0.15 + offset.dy)
      ..lineTo(w * 0.45 + offset.dx, h * 0.5 + offset.dy)
      ..lineTo(0, h * 0.75 + offset.dy);
    canvas.drawPath(arterialPath2, roadPaint);

    // 4. Demand Heatmap Rings (When Online)
    if (isOnline) {
      for (final zone in demandZones) {
        final zx = (w * zone.xRatio) + offset.dx;
        final zy = (h * zone.yRatio) + offset.dy;

        // Gradient glow circle
        final heatPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              zone.color.withValues(alpha: 0.28),
              zone.color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(zx, zy), radius: 55));
        canvas.drawCircle(Offset(zx, zy), 55, heatPaint);

        // Surge Badge
        final badgeRRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(zx, zy), width: 78, height: 24),
          const Radius.circular(12),
        );
        canvas.drawRRect(badgeRRect, Paint()..color = zone.color);
        canvas.drawRRect(
          badgeRRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // Badge Text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '︽ ${zone.label}',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(zx - (textPainter.width / 2), zy - (textPainter.height / 2)));
      }
    }

    // 5. Active Route Polyline (When Navigating)
    if (isNavigating) {
      final routePath = Path()
        ..moveTo(w * 0.5 + offset.dx, h * 0.52 + offset.dy)
        ..lineTo(w * 0.5 + offset.dx, h * 0.38 + offset.dy)
        ..lineTo(w * 0.70 + offset.dx, h * 0.38 + offset.dy)
        ..lineTo(w * 0.70 + offset.dx, h * 0.22 + offset.dy);

      // Route Glow Outline
      final routeGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(routePath, routeGlow);

      // Route Solid Line
      final routeSolid = Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(routePath, routeSolid);

      // Destination Pin
      final destX = w * 0.70 + offset.dx;
      final destY = h * 0.22 + offset.dy;
      canvas.drawCircle(Offset(destX, destY), 10, Paint()..color = const Color(0xFFEF4444));
      canvas.drawCircle(Offset(destX, destY), 4, Paint()..color = Colors.white);
    }

    // 6. User / Partner Location Indicator & Pulse
    final userX = (w * 0.5) + offset.dx;
    final userY = (h * 0.52) + offset.dy;

    if (isOnline) {
      // Expanding Radar Pulse Circle
      final pulseRadius = 24.0 + (pulseValue * 32.0);
      final pulseAlpha = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.45;
      final pulsePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset(userX, userY), pulseRadius, pulsePaint);
    }

    // White backing circle
    canvas.drawCircle(
      Offset(userX, userY),
      14,
      Paint()..color = Colors.white,
    );

    // Blue Center Dot with Heading Arrow
    canvas.drawCircle(
      Offset(userX, userY),
      10,
      Paint()..color = const Color(0xFF00E5FF),
    );

    // Heading Pointer
    final arrowPath = Path()
      ..moveTo(userX, userY - 14)
      ..lineTo(userX - 6, userY - 5)
      ..lineTo(userX + 6, userY - 5)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant _DarkMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isOnline != isOnline ||
        oldDelegate.isNavigating != isNavigating ||
        oldDelegate.offset != offset;
  }
}
