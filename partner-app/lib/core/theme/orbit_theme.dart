import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'orbit_colors.dart';

export 'orbit_colors.dart';
export 'orbit_typography.dart';
export 'orbit_spacing.dart';
export 'orbit_motion.dart';
export 'orbit_radii.dart';
export 'orbit_shadows.dart';

/// ORBIT Central Theme for Partner App
class OrbitTheme {
  OrbitTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OrbitColors.background,
      primaryColor: OrbitColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: OrbitColors.primary,
        onPrimary: OrbitColors.textPrimary,
        secondary: OrbitColors.secondary,
        onSecondary: Colors.black,
        surface: OrbitColors.surface,
        onSurface: OrbitColors.textPrimary,
        error: OrbitColors.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: OrbitColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: OrbitColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OrbitColors.surface,
        selectedItemColor: OrbitColors.secondary,
        unselectedItemColor: OrbitColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
