import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/orbit_colors.dart';
import 'theme/orbit_typography.dart';

export 'theme/orbit_theme.dart';

/// ORBIT Partner App — Operational Dark Design System
class OrbitPartnerTheme {
  OrbitPartnerTheme._();

  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color background = OrbitColors.background;
  static const Color surface = OrbitColors.surface;
  static const Color surfaceLow = OrbitColors.surfaceContainerLowest;
  static const Color surfaceHigh = OrbitColors.surfaceElevated;
  static const Color surfaceBorder = OrbitColors.borderSubtle;
  static const Color surfaceVariant = OrbitColors.surfaceHighlight;

  // ── Brand Accent & Semantics ──────────────────────────────────────────────
  static const Color primary = OrbitColors.primary;
  static const Color primaryDim = OrbitColors.primaryDark;
  static const Color primaryContainer = Color(0xFF1E1838);
  static const Color onPrimary = Colors.white;

  static const Color secondary = OrbitColors.primaryLight;
  static const Color secondaryContainer = Color(0xFF2A204E);
  static const Color onSecondary = Colors.white;

  static const Color tertiary = OrbitColors.info;
  static const Color tertiaryContainer = OrbitColors.surfaceHighlight;

  // ── Text Hierarchy ────────────────────────────────────────────────────────
  static const Color onSurface = OrbitColors.textPrimary;
  static const Color textSecondary = OrbitColors.textSecondary;
  static const Color onSurfaceVariant = OrbitColors.textSecondary;
  static const Color onBackground = OrbitColors.textPrimary;
  static const Color textMuted = OrbitColors.textMuted;

  // ── Status & State ────────────────────────────────────────────────────────
  static const Color error = OrbitColors.danger;
  static const Color online = OrbitColors.success;
  static const Color offline = OrbitColors.textDisabled;
  static const Color warning = OrbitColors.warning;

  // ── Borders & Outlines ────────────────────────────────────────────────────
  static const Color outline = OrbitColors.borderMedium;
  static const Color outlineFaint = OrbitColors.borderSubtle;
  static const Color border = OrbitColors.borderSubtle;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient partnerGradient = OrbitColors.primaryGradient;
  static const LinearGradient purpleGradient = OrbitColors.primaryGradient;

  // ── TextTheme (Inter) ─────────────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: OrbitTypography.displayLarge,
    displayMedium: OrbitTypography.displayMedium,
    headlineLarge: OrbitTypography.headingLarge,
    headlineMedium: OrbitTypography.headingMedium,
    headlineSmall: OrbitTypography.titleLarge,
    titleLarge: OrbitTypography.titleLarge,
    titleMedium: OrbitTypography.titleMedium,
    titleSmall: OrbitTypography.titleSmall,
    bodyLarge: OrbitTypography.bodyLarge,
    bodyMedium: OrbitTypography.bodyMedium,
    bodySmall: OrbitTypography.bodySmall,
    labelLarge: OrbitTypography.labelLarge,
    labelMedium: OrbitTypography.labelMedium,
    labelSmall: OrbitTypography.labelSmall,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFE0D8FF),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFFF0EBFF),
      tertiary: tertiary,
      onTertiary: Colors.black,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
      outline: outline,
      outlineVariant: outlineFaint,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: OrbitTypography.titleLarge,
      iconTheme: const IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: OrbitTypography.bodyMedium.copyWith(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: OrbitTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

/// Glass / elevated card container
class OrbitGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? customBorder;

  const OrbitGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? OrbitColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: customBorder ?? Border.all(color: OrbitColors.borderSubtle, width: 1.0),
      ),
      child: child,
    );
  }
}

/// Gradient text widget
class OrbitGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const OrbitGradientText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => OrbitColors.primaryGradient.createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

/// Status chip
class OrbitStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const OrbitStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Live pulse status dot
class OrbitLivePulseDot extends StatelessWidget {
  final bool isOnline;
  const OrbitLivePulseDot({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? OrbitColors.success : OrbitColors.textDisabled,
        boxShadow: isOnline
            ? [BoxShadow(color: OrbitColors.success.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)]
            : [],
      ),
    );
  }
}
