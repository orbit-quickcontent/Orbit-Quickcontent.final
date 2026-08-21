import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/orbit_theme.dart';

/// Shimmer Loading Skeleton Container
class OrbitLoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const OrbitLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = OrbitRadius.r12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: OrbitColors.surfaceElevated,
      highlightColor: OrbitColors.surfaceHighlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: OrbitColors.surfaceElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Loading Card Placeholder
class OrbitLoadingCard extends StatelessWidget {
  final double height;
  const OrbitLoadingCard({super.key, this.height = 120.0});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: OrbitColors.surfaceElevated,
      highlightColor: OrbitColors.surfaceHighlight,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: OrbitSpacing.space16),
        decoration: BoxDecoration(
          color: OrbitColors.surfaceElevated,
          borderRadius: OrbitRadius.rounded20,
          border: Border.all(color: OrbitColors.borderSubtle),
        ),
      ),
    );
  }
}
