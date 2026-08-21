import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Primary Dominant Action Button (Von Restorff & Fitts's Law compliant)
class OrbitPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final Gradient? gradient;

  const OrbitPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = OrbitSpacing.primaryCtaHeight,
    this.gradient,
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
          gradient: isEnabled ? (gradient ?? OrbitColors.primaryGradient) : null,
          color: isEnabled ? null : OrbitColors.surfaceHighlight,
          borderRadius: OrbitRadius.roundedFull,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: OrbitColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: OrbitRadius.roundedFull,
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
                          Icon(icon, size: 20, color: isEnabled ? Colors.white : OrbitColors.textDisabled),
                          const SizedBox(width: OrbitSpacing.space8),
                        ],
                        Text(
                          label,
                          style: OrbitTypography.titleSmall.copyWith(
                            color: isEnabled ? Colors.white : OrbitColors.textDisabled,
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

/// Secondary Outlined / Subtle Action Button
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
          borderRadius: OrbitRadius.roundedFull,
          border: Border.all(color: OrbitColors.borderMedium, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: OrbitRadius.roundedFull,
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
