import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orbit_colors.dart';

/// ORBIT Typography System for Partner App
/// Strict operational hierarchy based on Inter with high legibility & tabular figures
class OrbitTypography {
  OrbitTypography._();

  // ── Display / Amounts (28 - 32px) ──────────────────────────────────────────
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: OrbitColors.textPrimary,
    height: 1.15,
  );

  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: OrbitColors.textPrimary,
    height: 1.2,
  );

  // ── Large / Headings (22 - 26px) ───────────────────────────────────────────
  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
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

  // ── Section / Titles (16 - 18px) ───────────────────────────────────────────
  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: OrbitColors.textPrimary,
    height: 1.35,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: OrbitColors.textPrimary,
    height: 1.35,
  );

  static TextStyle titleSmall = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: OrbitColors.textPrimary,
    height: 1.4,
  );

  // ── Body (14 - 16px) ───────────────────────────────────────────────────────
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

  // ── Captions & Labels (12 - 13px) ──────────────────────────────────────────
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
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
    letterSpacing: 1.0,
    color: OrbitColors.textMuted,
  );

  // ── High-Contrast Metric Amounts ───────────────────────────────────────────
  static TextStyle metricValue = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: OrbitColors.textPrimary,
  );
}
