import 'package:flutter/material.dart';

import '../ui/app_tokens.dart';

class BearNativeAdCard extends StatelessWidget {
  const BearNativeAdCard({super.key, required this.placement});

  final Object placement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTokens.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTokens.divider, width: 0.6),
      ),
      alignment: Alignment.center,
      child: Text(
        'AD',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTokens.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
