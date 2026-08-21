import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orbit_colors.dart';

/// ORBIT Typography System
/// High legibility, large touch typography without tiny text for critical information.
class OrbitTypography {
  OrbitTypography._();

  // Display (32 - 40)
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: OrbitColors.textPrimary,
    height: 1.15,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: OrbitColors.textPrimary,
    height: 1.2,
  );

  // Heading (24 - 28)
  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: OrbitColors.textPrimary,
    height: 1.25,
  );

  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: OrbitColors.textPrimary,
    height: 1.3,
  );

  // Title (18 - 20)
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: OrbitColors.textPrimary,
    height: 1.35,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: OrbitColors.textPrimary,
    height: 1.35,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: OrbitColors.textPrimary,
    height: 1.4,
  );

  // Body (14 - 16)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: OrbitColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: OrbitColors.textSecondary,
    height: 1.45,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: OrbitColors.textMuted,
    height: 1.4,
  );

  // Caption / Label (11 - 13)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: OrbitColors.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: OrbitColors.textSecondary,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: OrbitColors.textMuted,
  );
}
