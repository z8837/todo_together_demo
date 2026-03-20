import 'package:flutter/material.dart';
import 'package:todotogether/core/localization/tr_extension.dart';
import 'package:todotogether/core/ui/app_button_styles.dart';
import 'package:todotogether/core/ui/app_spacing.dart';
import 'package:todotogether/core/ui/app_tokens.dart';

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  Color confirmColor = AppTokens.primary,
  Color cancelColor = AppTokens.textPrimary,
  Color borderColor = AppTokens.divider,
}) async {
  final resolvedConfirmLabel = confirmLabel ?? 'confirm'.tr();
  final resolvedCancelLabel = cancelLabel ?? 'cancel'.tr();
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: AppInsets.screenTop24,
            child: Material(
              color: Colors.transparent,
              child: AppConfirmDialog(
                title: title,
                message: message,
                confirmLabel: resolvedConfirmLabel,
                cancelLabel: resolvedCancelLabel,
                confirmColor: confirmColor,
                cancelColor: cancelColor,
                borderColor: borderColor,
                onConfirm: () => Navigator.of(dialogContext).pop(true),
                onCancel: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    required this.cancelColor,
    required this.borderColor,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final Color cancelColor;
  final Color borderColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.dialog,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppRadii.r22,
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title18),
          AppGap.h6,
          Text(message, style: AppTextStyles.body13),
          AppGap.h16,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: AppButtonStyles.outlined(
                    foreground: cancelColor,
                    border: borderColor,
                    borderRadius: AppRadii.r18,
                  ),
                  onPressed: onCancel,
                  child: Text(cancelLabel),
                ),
              ),
              AppGap.w10,
              Expanded(
                child: OutlinedButton(
                  style: AppButtonStyles.outlined(
                    foreground: confirmColor,
                    border: confirmColor,
                    borderRadius: AppRadii.r18,
                    borderWidth: 0.8,
                  ),
                  onPressed: onConfirm,
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
