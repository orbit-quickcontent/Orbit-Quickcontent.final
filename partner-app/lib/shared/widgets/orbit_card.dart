import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Standard Elevated Card for Partner App
class OrbitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;

  const OrbitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OrbitSpacing.space16),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = OrbitRadius.r20,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? OrbitColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: OrbitColors.borderSubtle, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            OrbitMotion.lightTap();
            onTap!();
          },
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Glassmorphic Card for Partner App
class OrbitGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double blur;
  final double borderRadius;
  final Border? border;

  const OrbitGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OrbitSpacing.space16),
    this.onTap,
    this.blur = 12.0,
    this.borderRadius = OrbitRadius.r20,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: OrbitColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: OrbitColors.borderMedium, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: onTap != null
                ? InkWell(
                    borderRadius: BorderRadius.circular(borderRadius),
                    onTap: () {
                      OrbitMotion.lightTap();
                      onTap!();
                    },
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

/// Metric Card for Partner Dashboard / Earnings
class OrbitMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;

  const OrbitMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitCard(
      padding: const EdgeInsets.all(OrbitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: OrbitTypography.bodySmall),
              Icon(icon, size: 20, color: iconColor ?? OrbitColors.secondary),
            ],
          ),
          const SizedBox(height: OrbitSpacing.space8),
          Text(value, style: OrbitTypography.headingMedium),
          if (subtitle != null) ...[
            const SizedBox(height: OrbitSpacing.space4),
            Text(subtitle!, style: OrbitTypography.labelSmall.copyWith(color: OrbitColors.success)),
          ],
        ],
      ),
    );
  }
}
