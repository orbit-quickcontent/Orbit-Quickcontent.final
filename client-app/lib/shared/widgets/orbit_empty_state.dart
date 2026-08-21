import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';
import 'orbit_button.dart';

/// Zero-State Component (Clear explanation + Actionable next step)
class OrbitEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const OrbitEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrbitSpacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: OrbitColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: OrbitColors.borderMedium, width: 1),
              ),
              child: Icon(icon, size: 36, color: OrbitColors.secondary),
            ),
            const SizedBox(height: OrbitSpacing.space24),
            Text(
              title,
              style: OrbitTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OrbitSpacing.space8),
            Text(
              description,
              style: OrbitTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: OrbitSpacing.space32),
              SizedBox(
                width: 220,
                child: OrbitPrimaryButton(
                  label: ctaLabel!,
                  onPressed: onCtaPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Component
class OrbitErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onRetry;

  const OrbitErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.description = 'We encountered an error loading this data. Please try again.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrbitSpacing.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: OrbitColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: OrbitColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 36, color: OrbitColors.danger),
            ),
            const SizedBox(height: OrbitSpacing.space20),
            Text(title, style: OrbitTypography.headingMedium, textAlign: TextAlign.center),
            const SizedBox(height: OrbitSpacing.space8),
            Text(description, style: OrbitTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: OrbitSpacing.space24),
            SizedBox(
              width: 180,
              child: OrbitSecondaryButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
