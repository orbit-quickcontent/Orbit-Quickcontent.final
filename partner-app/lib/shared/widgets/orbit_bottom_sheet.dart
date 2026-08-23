import 'package:flutter/material.dart';
import '../../core/theme/orbit_theme.dart';

/// Standard Modal Bottom Sheet for Partner App
class OrbitBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  const OrbitBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    OrbitMotion.lightTap();
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => OrbitBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: OrbitSpacing.space24,
        right: OrbitSpacing.space24,
        top: OrbitSpacing.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + OrbitSpacing.space24,
      ),
      decoration: const BoxDecoration(
        color: OrbitColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(OrbitRadius.r32)),
        border: Border(
          top: BorderSide(color: OrbitColors.borderMedium, width: 1),
          left: BorderSide(color: OrbitColors.borderSubtle, width: 1),
          right: BorderSide(color: OrbitColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: const BoxDecoration(
                color: OrbitColors.textDisabled,
                borderRadius: OrbitRadius.roundedFull,
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: OrbitSpacing.space20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title!, style: OrbitTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: OrbitColors.textMuted),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space24),
          ] else ...[
            const SizedBox(height: OrbitSpacing.space16),
          ],
          child,
        ],
      ),
    );
  }
}
