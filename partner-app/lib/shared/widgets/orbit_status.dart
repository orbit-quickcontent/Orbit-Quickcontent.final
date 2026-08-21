import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Semantic Status Pill Component for Partner App
class OrbitStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const OrbitStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory OrbitStatusPill.fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ONLINE':
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'VERIFIED':
      case 'ACTIVE':
        return OrbitStatusPill(
          label: status.replaceAll('_', ' '),
          color: OrbitColors.success,
          icon: Icons.check_circle_outline,
        );
      case 'DISPATCHING':
      case 'PARTNER_OFFERED':
      case 'PARTNER_ASSIGNED':
      case 'EN_ROUTE':
      case 'SHOOTING':
      case 'UPLOADING':
        return OrbitStatusPill(
          label: status.replaceAll('_', ' '),
          color: OrbitColors.secondary,
          icon: Icons.sync,
        );
      case 'PENDING':
      case 'OFFLINE':
        return OrbitStatusPill(
          label: status.replaceAll('_', ' '),
          color: OrbitColors.warning,
          icon: Icons.access_time,
        );
      case 'CANCELLED':
      case 'DECLINED':
      case 'REJECTED':
      default:
        return OrbitStatusPill(
          label: status.replaceAll('_', ' '),
          color: OrbitColors.danger,
          icon: Icons.error_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space12, vertical: OrbitSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: OrbitRadius.roundedFull,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: OrbitSpacing.space4),
          ],
          Text(
            label,
            style: OrbitTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
