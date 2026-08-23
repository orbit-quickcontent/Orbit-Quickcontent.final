import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Primary Dominant Action Button for Partner App
class OrbitPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const OrbitPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = OrbitSpacing.primaryCtaHeight,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: double.infinity, minHeight: OrbitSpacing.minTouchTarget),
        decoration: BoxDecoration(
          color: isEnabled ? (backgroundColor ?? OrbitColors.primary) : OrbitColors.surfaceHighlight,
          borderRadius: OrbitRadii.largeBorder,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: (backgroundColor ?? OrbitColors.primary).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: OrbitRadii.largeBorder,
            onTap: isEnabled
                ? () {
                    OrbitMotion.lightTap();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: textColor ?? Colors.white),
                          const SizedBox(width: OrbitSpacing.space8),
                        ],
                        Text(
                          label,
                          style: OrbitTypography.titleSmall.copyWith(
                            color: isEnabled ? (textColor ?? Colors.white) : OrbitColors.textDisabled,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accept Booking Button (Dominant Operational Green)
class OrbitAcceptButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const OrbitAcceptButton({
    super.key,
    this.label = 'ACCEPT BOOKING',
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.check_circle_outline_rounded,
    this.height = OrbitSpacing.primaryCtaHeight,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitPrimaryButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      height: height,
      backgroundColor: OrbitColors.success,
      textColor: Colors.black,
    );
  }
}

/// Secondary Outlined / Muted Action Button for Partner App
class OrbitSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? textColor;

  const OrbitSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = OrbitSpacing.primaryCtaHeight,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: double.infinity, minHeight: OrbitSpacing.minTouchTarget),
        decoration: BoxDecoration(
          color: OrbitColors.surfaceElevated,
          borderRadius: OrbitRadii.largeBorder,
          border: Border.all(color: OrbitColors.borderSubtle, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: OrbitRadii.largeBorder,
            onTap: isEnabled
                ? () {
                    OrbitMotion.lightTap();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor ?? OrbitColors.textSecondary),
                    const SizedBox(width: OrbitSpacing.space8),
                  ],
                  Text(
                    label,
                    style: OrbitTypography.titleSmall.copyWith(
                      color: textColor ?? OrbitColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Danger / Decline Action Button (Subtle Red Outline)
class OrbitDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const OrbitDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = OrbitSpacing.primaryCtaHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: double.infinity, minHeight: OrbitSpacing.minTouchTarget),
        decoration: BoxDecoration(
          color: OrbitColors.danger.withValues(alpha: 0.08),
          borderRadius: OrbitRadii.largeBorder,
          border: Border.all(color: OrbitColors.danger.withValues(alpha: 0.25), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: OrbitRadii.largeBorder,
            onTap: onPressed != null
                ? () {
                    OrbitMotion.lightTap();
                    onPressed!();
                  }
                : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: OrbitColors.danger),
                    const SizedBox(width: OrbitSpacing.space8),
                  ],
                  Text(
                    label,
                    style: OrbitTypography.titleSmall.copyWith(
                      color: OrbitColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
