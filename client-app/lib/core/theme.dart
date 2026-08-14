import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ORBIT Client App — Kinetic Noir Design System
/// Colors extracted from stitch_universal_app_creator DESIGN.md
class OrbitClientTheme {
  OrbitClientTheme._();

  // ── Core Palette ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surface = Color(0xFF201F1F);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color surfaceHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF393939);

  // ── Primary (Cyan/Blue) ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFFA5E7FF);      // #a5e7ff
  static const Color primaryContainer = Color(0xFF00D2FF); // #00d2ff
  static const Color primaryFixed = Color(0xFF47D6FF);   // surface-tint / accent
  static const Color onPrimary = Color(0xFF003543);
  static const Color onPrimaryContainer = Color(0xFF00566A);

  // ── Secondary (Purple) ──────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFEDB1FF);    // #edb1ff
  static const Color secondaryContainer = Color(0xFF6E208C);
  static const Color onSecondary = Color(0xFF520070);
  static const Color onSecondaryContainer = Color(0xFFE498FF);

  // ── Text Colors ─────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFBBC9CF);
  static const Color outline = Color(0xFF859399);
  static const Color outlineVariant = Color(0xFF3C494E);

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF4ADE80);

  // ── Gradient: The signature Blue → Purple gradient ─────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C2FF), Color(0xFF9D50FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF00C2FF), Color(0xFF9D50FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x2000C2FF), Color(0x209D50FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Typography ──────────────────────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    // Display — Montserrat ExtraBold 32px
    displayLarge: GoogleFonts.montserrat(
      fontSize: 32, fontWeight: FontWeight.w800,
      color: onSurface, letterSpacing: -0.64, height: 1.2,
    ),
    // Headline — Montserrat Bold 24px
    headlineLarge: GoogleFonts.montserrat(
      fontSize: 24, fontWeight: FontWeight.w700,
      color: onSurface, height: 1.3,
    ),
    headlineMedium: GoogleFonts.montserrat(
      fontSize: 20, fontWeight: FontWeight.w700,
      color: onSurface, height: 1.3,
    ),
    headlineSmall: GoogleFonts.montserrat(
      fontSize: 16, fontWeight: FontWeight.w700,
      color: onSurface, height: 1.3,
    ),
    // Title — Plus Jakarta Sans SemiBold
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: onSurface, height: 1.5,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16, fontWeight: FontWeight.w600,
      color: onSurface, height: 1.5,
    ),
    // Body — Plus Jakarta Sans
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: onSurface, height: 1.6,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: onSurface, height: 1.5,
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: onSurfaceVariant, height: 1.4,
    ),
    // Label — Space Grotesk Bold (for metadata, tags)
    labelLarge: GoogleFonts.spaceGrotesk(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: onSurface, letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.spaceGrotesk(
      fontSize: 12, fontWeight: FontWeight.w700,
      color: onSurfaceVariant, letterSpacing: 1.2,
    ),
    labelSmall: GoogleFonts.spaceGrotesk(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: onSurfaceVariant, letterSpacing: 1.2,
    ),
  );

  // ── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryFixed,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Color(0xFF690005),
      outline: outline,
      outlineVariant: outlineVariant,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20, fontWeight: FontWeight.w700, color: onSurface,
      ),
      iconTheme: const IconThemeData(color: onSurface),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: primaryFixed,
      unselectedItemColor: outline,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryFixed, width: 1.5),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14, color: outline, fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outlineVariant, width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: outlineVariant, thickness: 0.5),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHighest,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

/// Gradient CTA button — The signature Blue→Purple button
class OrbitGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;

  const OrbitGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(colors: [Color(0xFF3A3A3A), Color(0xFF3A3A3A)])
              : OrbitClientTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed == null
              ? []
              : [BoxShadow(color: const Color(0xFF00C2FF).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Glass card — Dark glassmorphic card with subtle border
class OrbitGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const OrbitGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OrbitClientTheme.surfaceContainerLow.withOpacity(0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
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
      shaderCallback: (bounds) => OrbitClientTheme.primaryGradient.createShader(bounds),
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
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.8,
        ),
      ),
    );
  }
}
