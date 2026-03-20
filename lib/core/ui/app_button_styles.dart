import 'package:flutter/material.dart';
import 'package:todotogether/core/ui/app_spacing.dart';
import 'package:todotogether/core/ui/app_tokens.dart';

class AppButtonStyles {
  const AppButtonStyles._();

  static ButtonStyle outlined({
    Color foreground = AppTokens.textPrimary,
    Color border = AppTokens.divider,
    EdgeInsetsGeometry padding = AppInsets.v12,
    BorderRadius borderRadius = AppRadii.r18,
    double borderWidth = 0.6,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: border, width: borderWidth),
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }

  static ButtonStyle filled({
    Color background = AppTokens.surface,
    Color foreground = AppTokens.textPrimary,
    EdgeInsetsGeometry padding = AppInsets.v12,
    BorderRadius borderRadius = AppRadii.r18,
    BorderSide border = AppBorders.card,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      padding: padding,
      shape: RoundedRectangleBorder(borderRadius: borderRadius, side: border),
    );
  }
}
