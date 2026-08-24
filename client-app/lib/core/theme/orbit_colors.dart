import 'package:flutter/material.dart';

/// ORBIT Design System Colors
/// Unified, high-contrast, premium dark theme palette.
class OrbitColors {
  OrbitColors._();

  // Background & Surfaces (Sleek Matte Obsidian & Charcoal Theme)
  static const Color background = Color(0xFF0E1015);
  static const Color surface = Color(0xFF16181F);
  static const Color surfaceElevated = Color(0xFF1B1E26);
  static const Color surfaceHighlight = Color(0xFF232733);
  static const Color surfaceContainerLowest = Color(0xFF090A0D);

  // Accents
  static const Color primary = Color(0xFF7C3AED);       // Vivid Purple
  static const Color primaryLight = Color(0xFF9061F9);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF00D2FF);     // Electric Cyan
  static const Color secondaryDark = Color(0xFF0099B8);
  static const Color cyanAccent = Color(0xFF38BDF8);

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
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF222632);   // Card Borders
  static const Color borderMedium = Color(0xFF2C3242);   // Divider Lines
  static const Color borderStrong = Color(0xFF3B4358);
  static const Color borderPrimary = Color(0x4D7C3AED);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF00D2FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1B1E26), Color(0xFF13151B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xCC16181F), Color(0x99111317)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
