import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ORBIT Partner App — Luminous Dark Design System
/// Colors extracted from stitch_professional_ui_ux_replication DESIGN.md
class OrbitPartnerTheme {
  OrbitPartnerTheme._();

  // ── Core Palette (Total Pitch Black OLED Theme) ──────────────────────────
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceLow = Color(0xFF141414);
  static const Color surfaceHigh = Color(0xFF1C1C1C);
  static const Color surfaceBorder = Color(0xFF222222);
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // ── Primary (Neon Green) ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF4BE277);       // #4be277
  static const Color primaryDim = Color(0xFF22C55E);    // #22c55e
  static const Color primaryContainer = Color(0xFF003915);
  static const Color onPrimary = Colors.black;

  // ── Secondary (Purple) ─────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFDDB7FF);    // #ddb7ff
  static const Color secondaryContainer = Color(0xFF6F00BE);
  static const Color onSecondary = Color(0xFF490080);

  // ── Tertiary (Tech Blue) ───────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFAFC7FF);     // #afc7ff
  static const Color tertiaryContainer = Color(0xFF003D88);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E2E1);    // #e5e2e1
  static const Color textSecondary = Color(0xFF94A3B8); // Mid-gray
  static const Color onSurfaceVariant = textSecondary;
  static const Color onBackground = onSurface;

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color online = Color(0xFF10B981);       // Emerald for ONLINE dot
  static const Color offline = Color(0xFF6B7280);

  // ── Border ─────────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF374151);
  static const Color outlineFaint = Color(0xFF1F2937);
  static const Color border = outlineFaint;

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const LinearGradient partnerGradient = LinearGradient(
    colors: [Color(0xFF4BE277), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6F00BE), Color(0xFF9D50FF)],
  );

  // ── TextTheme (Plus Jakarta Sans + Geist) ──────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: onSurface),
    headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface),
    headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
    headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
    titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
    titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
    bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface),
    bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface),
    bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
    // Geist for labels/metadata
    labelLarge: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0.5),
    labelMedium: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 1.0),
    labelSmall: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 1.2),
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
      onPrimaryContainer: Color(0xFF6BFF8F),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFFF0DBFF),
      tertiary: tertiary,
      onTertiary: Color(0xFF002E6A),
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Color(0xFF690005),
      outline: outline,
      outlineVariant: outlineFaint,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface),
      iconTheme: const IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outlineFaint, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0A0A0A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: outlineFaint, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceLow,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Shared Partner Widgets ───────────────────────────────────────────────────

/// Primary action button (white bg, black text — per Luminous Dark spec)
class PartnerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double height;

  const PartnerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color ?? OrbitPartnerTheme.outline),
                foregroundColor: color ?? OrbitPartnerTheme.onSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _child,
            ),
    );
  }

  Widget get _child => isLoading
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
      : Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700));
}

/// Dark card for Partner app
class PartnerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PartnerCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OrbitPartnerTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OrbitPartnerTheme.outlineFaint, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Online status indicator
class OnlineStatusDot extends StatelessWidget {
  final bool isOnline;
  const OnlineStatusDot({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? OrbitPartnerTheme.primary : OrbitPartnerTheme.offline,
        boxShadow: isOnline
            ? [BoxShadow(color: OrbitPartnerTheme.primary.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)]
            : [],
      ),
    );
  }
}
