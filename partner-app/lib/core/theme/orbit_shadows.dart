import 'package:flutter/material.dart';

/// ORBIT Partner App — Shadow Tokens
/// Standardized shadows for creating hierarchy and elevation against the dark background.
class OrbitShadows {
  OrbitShadows._();

  // Subtle floating elements (cards)
  static final List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // Medium elevation (bottom sheets, primary actions)
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Strong elevation (overlays that MUST command attention)
  static final List<BoxShadow> strong = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      blurRadius: 24,
      spreadRadius: 4,
      offset: const Offset(0, 8),
    ),
  ];

  // Primary glow (GO button, active states)
  static final List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFF7C5CFF).withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // Success glow (Online button)
  static final List<BoxShadow> successGlow = [
    BoxShadow(
      color: const Color(0xFF22C55E).withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}
