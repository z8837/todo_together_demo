import 'package:flutter/material.dart';

class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({
    super.key,
    required this.size,
    required this.radius,
    required this.initial,
    required this.backgroundColor,
    required this.textStyle,
    this.provider,
    this.badgeSize = 14,
    this.badgePadding = 0,
    this.googleBadgePadding,
    this.googleBorderColor,
    this.appleIconSize = 10,
  });

  final double size;
  final double radius;
  final String initial;
  final Color backgroundColor;
  final TextStyle textStyle;
  final String? provider;
  final double badgeSize;
  final double badgePadding;
  final double? googleBadgePadding;
  final Color? googleBorderColor;
  final double appleIconSize;

  @override
  Widget build(BuildContext context) {
    final normalized = provider?.toLowerCase();
    final isGoogle = normalized?.contains('google') == true;
    final isApple = normalized?.contains('apple') == true;
    final assetPath = _providerAssetPath(normalized);
    final hasBadge = isApple || assetPath != null;
    final effectivePadding = isGoogle
        ? (googleBadgePadding ?? badgePadding)
        : badgePadding;
    final badgeBorderColor = isGoogle ? googleBorderColor : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor,
              child: Text(initial, style: textStyle),
            ),
          ),
          if (hasBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                padding: EdgeInsets.all(effectivePadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: badgeBorderColor != null
                      ? Border.all(color: badgeBorderColor)
                      : null,
                ),
                child: isApple
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.apple,
                            size: appleIconSize,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : ClipOval(
                        child: Image.asset(assetPath!, fit: BoxFit.cover),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String? _providerAssetPath(String? normalized) {
    if (normalized == null) {
      return null;
    }
    if (normalized.contains('google')) {
      return 'assets/image/icon/google.png';
    }
    if (normalized.contains('naver')) {
      return 'assets/image/icon/naver.png';
    }
    if (normalized.contains('kakao')) {
      return 'assets/image/icon/kakao.png';
    }
    return null;
  }
}
