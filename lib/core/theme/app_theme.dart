import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFF6F1E8);
  static const shell = Color(0xFFFBF8F2);
  static const surface = Color(0xFFFFFCF7);
  static const surfaceStrong = Color(0xFF183049);
  static const surfaceMuted = Color(0xFFEAE3D7);
  static const border = Color(0xFFD9CDBB);
  static const ink = Color(0xFF12263A);
  static const inkSoft = Color(0xFF586574);
  static const accent = Color(0xFFD87644);
  static const accentSoft = Color(0xFFF2C9AE);
  static const olive = Color(0xFF7A8D54);
  static const teal = Color(0xFF2D6A73);
  static const plum = Color(0xFF6C557A);
  static const danger = Color(0xFFB74E3D);
  static const success = Color(0xFF2C7A52);
  static const warning = Color(0xFFB07B24);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      selectedColor: AppColors.ink,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surfaceMuted,
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.shell,
      indicatorColor: AppColors.accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkSoft,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.accentSoft,
      selectedIconTheme: IconThemeData(color: AppColors.ink),
      unselectedIconTheme: IconThemeData(color: AppColors.inkSoft),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border),
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(
        color: AppColors.ink,
        fontSize: 38,
        fontWeight: FontWeight.w900,
        height: 0.96,
        letterSpacing: -1.2,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.8,
      ),
      headlineSmall: const TextStyle(
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      bodySmall: const TextStyle(
        color: AppColors.inkSoft,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    ),
  );
}
