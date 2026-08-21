import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ORBIT Motion & Haptics System for Partner App
class OrbitMotion {
  OrbitMotion._();

  // Durations
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration button = Duration(milliseconds: 200);
  static const Duration transition = Duration(milliseconds: 260);
  static const Duration bottomSheet = Duration(milliseconds: 320);
  static const Duration success = Duration(milliseconds: 500);

  // Easing Curves (iOS-style Natural Curves)
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutQuad;
  static const Curve exit = Curves.easeInQuad;
  static const Curve spring = Curves.easeOutCubic;

  // Haptic Feedback Utilities
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  static void selectionChanged() {
    HapticFeedback.selectionClick();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void successHaptic() {
    HapticFeedback.heavyImpact();
  }

  static void errorHaptic() {
    HapticFeedback.vibrate();
  }
}
