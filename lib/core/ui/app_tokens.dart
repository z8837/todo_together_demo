import 'package:flutter/material.dart';

class AppTokens {
  const AppTokens._();

  static const Color textPrimary = Color(0xFF111111);
  static const Color textStrong = Color(0xFF1F2537);
  static const Color textDeep = Color(0xFF2F3544);
  static const Color textSecondary = Color(0xFF8F8F8F);
  static const Color textBody = Color(0xFF555555);
  static const Color textMuted = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFFB3B7C0);
  static const Color sectionLabel = Color(0xFF9A9A9A);
  static const Color divider = Color(0xFFE6E6E6);
  static const Color iconMuted = Color(0xFFB0B0B0);
  static const Color primary = Color(0xFF3461C5);
  static const Color primarySoft = Color(0xFF83A1E1);
  static const Color primaryAvatar = Color(0xFF9CBDFF);
  static const Color primarySurface = Color(0xFFF1F4FB);
  static const Color upcoming = Color(0xFF7AC1FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF2F2F2);
  static const Color surfaceSoft = Color(0xFFF2F4F7);
  static const Color surfaceMuted = Color(0xFFF8F8F8);
  static const Color surfaceInput = Color(0xFFF6F7F9);
  static const Color surfaceTint = Color(0xFFF6F7FB);
  static const Color surfaceIcon = Color(0xFFF3F3F3);
  static const Color avatarOverflow = Color(0xFFE9EEF5);
  static const Color favoriteAccent = Color(0xFFC59B67);
  static const Color favoriteBackground = Color(0xFFFFF6ED);
  static const Color favoriteBorder = Color(0xFFF3E3D0);
  static const Color warning = Color(0xFFFF7A00);
  static const Color danger = Color(0xFFE05A5A);
  static const Color dividerSoft = Color(0xFFEFEFEF);
  static const Color handle = Color(0xFFE0E0E0);
  static const Color borderSoft = Color(0xFFE2E7F1);
  static const Color borderSubtle = Color(0xFFE6E9EF);
  static const Color borderMuted = Color(0xFFBDBDBD);
  static const Color shadowSoft = Color(0xFFE3E3E3);
  static const Color shadowDark = Color(0xFF515151);
  static const Color success = Color(0xFF44C680);
  static const Color todoCompleted = Color(0xFF6B7280);
  static const Color todoRecurring = Color(0xFF2F6BFF);
  static const Color todoSingle = Color(0xFF1F9D5B);
  static const Color todoCompletedBackground = Color(0xFFE5E7EB);
  static const Color todoRecurringBackground = Color(0xFFEAF1FF);
  static const Color todoSingleBackground = Color(0xFFE9F8F0);
  static const Color todoCompletedConnected = Color(0xFF9498A5);
  static const Color todoRecurringConnected = Color(0xFF5C87EA);
  static const Color todoSingleConnected = Color(0xFF44C680);
  static const Color shadow = Colors.transparent;
}

class AppRadii {
  const AppRadii._();

  static const BorderRadius r16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius r18 = BorderRadius.all(Radius.circular(18));
  static const BorderRadius r22 = BorderRadius.all(Radius.circular(22));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppBorders {
  const AppBorders._();

  static const BorderSide card = BorderSide(
    color: AppTokens.divider,
    width: 0.6,
  );
}

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle title18 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppTokens.textPrimary,
  );

  static const TextStyle title16 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppTokens.textPrimary,
  );

  static const TextStyle body14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTokens.textPrimary,
  );

  static const TextStyle body13 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppTokens.textSecondary,
  );
}
