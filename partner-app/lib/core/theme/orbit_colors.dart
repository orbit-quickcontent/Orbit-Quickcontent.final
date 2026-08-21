import 'package:flutter/material.dart';

/// ORBIT Partner App — Dark Operational Design Tokens
/// Psychology-driven operational palette (#0B0D10 / #12161B / #181D23 / #7C5CFF)
class OrbitColors {
  OrbitColors._();

  // Background & Surfaces (Dark operational theme)
  static const Color background = Color(0xFF0B0D10);
  static const Color surface = Color(0xFF12161B);
  static const Color surfaceElevated = Color(0xFF181D23);
  static const Color surfaceHighlight = Color(0xFF222933);
  static const Color surfaceContainerLowest = Color(0xFF07080A);

  // Brand Accent (Electric Orbit Violet — 5-10% interface visual presence)
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryLight = Color(0xFF9B82FF);
  static const Color primaryDark = Color(0xFF6242E6);
  static const Color secondary = Color(0xFF7C5CFF);
  static const Color secondaryDark = Color(0xFF6242E6);
  static const Color cyanAccent = Color(0xFF38BDF8);

  // Semantic Colors (High functional meaning)
  static const Color success = Color(0xFF22C55E);       // Online, accepted, completed, payout
  static const Color successContainer = Color(0xFF052E16);
  static const Color warning = Color(0xFFF59E0B);       // Waiting, pending, countdown
  static const Color warningContainer = Color(0xFF451A03);
  static const Color danger = Color(0xFFEF4444);        // Cancelled, rejected, errors
  static const Color dangerContainer = Color(0xFF450A0A);
  static const Color info = Color(0xFF38BDF8);          // Navigation, location, updates

  // Text & Content Hierarchy
  static const Color textPrimary = Color(0xFFF5F7FA);   // High readability primary text
  static const Color textSecondary = Color(0xFF9AA3AE); // Scannable secondary metadata
  static const Color textMuted = Color(0xFF68717D);     // Supporting context
  static const Color textDisabled = Color(0xFF4B5563);  // Inactive states

  // Crisp Operational Borders
  static const Color borderSubtle = Color(0xFF252B33);   // 1px standard card border
  static const Color borderMedium = Color(0xFF2E3642);   // Active / focused borders
  static const Color borderStrong = Color(0xFF3D4756);   // Prominent dividers
  static const Color borderPrimary = Color(0x667C5CFF);  // 40% primary glow border

  // Gradients (Subtle & purposeful)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF9B82FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF181D23), Color(0xFF12161B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xCC181D23), Color(0x9912161B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
