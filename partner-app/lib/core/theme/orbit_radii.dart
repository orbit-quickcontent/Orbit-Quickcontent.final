import 'package:flutter/material.dart';

/// ORBIT Partner App — Radii Tokens
/// Standardized rounded corners to prevent ad-hoc border radii.
class OrbitRadii {
  OrbitRadii._();

  // Micro elements (tags, badges)
  static const Radius micro = Radius.circular(4);
  static const BorderRadius microBorder = BorderRadius.all(micro);

  // Small elements (small buttons, inputs)
  static const Radius small = Radius.circular(8);
  static const BorderRadius smallBorder = BorderRadius.all(small);

  // Medium elements (standard buttons, inner cards)
  static const Radius medium = Radius.circular(12);
  static const BorderRadius mediumBorder = BorderRadius.all(medium);

  // Large elements (standard cards)
  static const Radius large = Radius.circular(16);
  static const BorderRadius largeBorder = BorderRadius.all(large);

  // Extra large elements (hero cards, main bottom sheets)
  static const Radius xLarge = Radius.circular(24);
  static const BorderRadius xLargeBorder = BorderRadius.all(xLarge);

  // Pill shapes
  static const Radius pill = Radius.circular(999);
  static const BorderRadius pillBorder = BorderRadius.all(pill);
}
