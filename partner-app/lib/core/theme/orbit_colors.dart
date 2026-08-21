import 'package:flutter/material.dart';

/// ORBIT Design System Colors
class OrbitColors {
  OrbitColors._();

  // Background & Surfaces
  static const Color background = Color(0xFF08090D);
  static const Color surface = Color(0xFF11131A);
  static const Color surfaceElevated = Color(0xFF181B24);
  static const Color surfaceHighlight = Color(0xFF222634);
  static const Color surfaceContainerLowest = Color(0xFF040507);

  // Accents
  static const Color primary = Color(0xFF7C3AED);       // Vivid Purple
  static const Color primaryLight = Color(0xFF9061F9);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF00D9FF);     // Neon Cyan
  static const Color secondaryDark = Color(0xFF0099B8);
  static const Color cyanAccent = Color(0xFF00F0FF);

  // Semantic
  static const Color success = Color(0xFF22C55E);       // Vibrant Green
  static const Color successContainer = Color(0xFF052E16);
  static const Color warning = Color(0xFFF59E0B);       // Warm Amber
  static const Color warningContainer = Color(0xFF451A03);
  static const Color danger = Color(0xFFEF4444);        // Crisp Red
  static const Color dangerContainer = Color(0xFF450A0A);
  static const Color info = Color(0xFF3B82F6);          // Electric Blue

  // Text & Icons
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF52525B);

  // Borders & Dividers (White at 8-12% opacity)
  static const Color borderSubtle = Color(0x14FFFFFF);   // ~8%
  static const Color borderMedium = Color(0x1FFFFFFF);   // ~12%
  static const Color borderStrong = Color(0x33FFFFFF);   // ~20%
  static const Color borderPrimary = Color(0x4D7C3AED);  // ~30% primary

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF00D9FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF181B24), Color(0xFF11131A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x22181B24), Color(0x1111131A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
