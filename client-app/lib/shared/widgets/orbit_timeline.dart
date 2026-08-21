import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Visual Booking Step Timeline Component
class OrbitBookingTimeline extends StatelessWidget {
  final String currentStatus;

  const OrbitBookingTimeline({super.key, required this.currentStatus});

  static const List<Map<String, String>> steps = [
    {'key': 'PAID', 'label': 'Booked'},
    {'key': 'PARTNER_ASSIGNED', 'label': 'Creator Found'},
    {'key': 'EN_ROUTE', 'label': 'On the Way'},
    {'key': 'ARRIVED', 'label': 'Arrived'},
    {'key': 'SHOOTING', 'label': 'Shooting'},
    {'key': 'EDITING', 'label': 'Editing'},
    {'key': 'DELIVERED', 'label': 'Ready'},
  ];

  int _getCurrentStepIndex() {
    switch (currentStatus.toUpperCase()) {
      case 'PENDING_PAYMENT':
        return -1;
      case 'PAID':
      case 'DISPATCHING':
      case 'PARTNER_OFFERED':
        return 0;
      case 'PARTNER_ASSIGNED':
        return 1;
      case 'EN_ROUTE':
        return 2;
      case 'ARRIVED':
        return 3;
      case 'SHOOTING':
        return 4;
      case 'UPLOADING':
      case 'EDITING':
        return 5;
      case 'DELIVERED':
      case 'COMPLETED':
        return 6;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentStepIndex();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Node & Connector
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? OrbitColors.success
                        : isCurrent
                            ? OrbitColors.secondary
                            : OrbitColors.surfaceHighlight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: OrbitColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : isCurrent
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Text(
                                '${index + 1}',
                                style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.textMuted),
                              ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: isCompleted ? OrbitColors.success : OrbitColors.borderSubtle,
                  ),
              ],
            ),
            const SizedBox(width: OrbitSpacing.space16),

            // Step Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  step['label']!,
                  style: isCurrent
                      ? OrbitTypography.titleSmall.copyWith(
                          color: OrbitColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        )
                      : isCompleted
                          ? OrbitTypography.bodyMedium.copyWith(color: OrbitColors.textSecondary)
                          : OrbitTypography.bodyMedium.copyWith(color: OrbitColors.textMuted),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
