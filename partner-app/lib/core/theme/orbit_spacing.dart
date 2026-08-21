import 'package:flutter/material.dart';

/// ORBIT Spacing & Radius Tokens
class OrbitSpacing {
  OrbitSpacing._();

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Touch Target Minimums (Fitts's Law)
  static const double minTouchTarget = 48.0;
  static const double primaryCtaHeight = 56.0;
  static const double floatingCtaHeight = 60.0;
}

/// ORBIT Radius Tokens
class OrbitRadius {
  OrbitRadius._();

  static const double r12 = 12.0; // Small controls, pills
  static const double r16 = 16.0; // Standard cards, inputs
  static const double r20 = 20.0; // Large cards, modal items
  static const double r24 = 24.0; // Major containers
  static const double r32 = 32.0; // Bottom sheets
  static const double rFull = 999.0; // Circular buttons, badges

  static const BorderRadius rounded12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius rounded16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius rounded20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius rounded24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius rounded32 = BorderRadius.all(Radius.circular(r32));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(rFull));
}
