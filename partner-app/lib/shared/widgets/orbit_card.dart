import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Standard Operational Card for Partner App
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
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? OrbitColors.surface,
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

/// Metric Card for Operational Dashboard & Earnings
class OrbitMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;

  const OrbitMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.valueColor,
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
              Text(
                title.toUpperCase(),
                style: OrbitTypography.labelSmall.copyWith(
                  color: OrbitColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 18, color: iconColor ?? OrbitColors.primary),
            ],
          ),
          const SizedBox(height: OrbitSpacing.space8),
          Text(
            value,
            style: OrbitTypography.metricValue.copyWith(
              color: valueColor ?? OrbitColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: OrbitSpacing.space4),
            Text(
              subtitle!,
              style: OrbitTypography.bodySmall.copyWith(
                fontSize: 12,
                color: OrbitColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
