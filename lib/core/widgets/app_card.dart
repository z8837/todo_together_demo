import 'package:flutter/material.dart';
import 'package:todotogether/core/ui/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor = AppTokens.surface,
    this.borderRadius = AppRadii.r18,
    this.borderSide = AppBorders.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final BorderSide borderSide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: borderSide,
    );
    if (onTap != null) {
      return Material(
        color: backgroundColor,
        shape: shape,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      );
    }
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.fromBorderSide(borderSide),
      ),
      child: child,
    );
  }
}
