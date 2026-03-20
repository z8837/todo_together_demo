import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Tap extends StatefulWidget {
  const Tap({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.deferToNextFrame = true,
    this.enableRipple = true,
    this.borderRadius,
    this.customBorder,
    this.pressedDuration = const Duration(milliseconds: 80),
    this.pressedColor,
    this.rippleColor,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final bool deferToNextFrame;
  final bool enableRipple;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Duration pressedDuration;
  final Color? pressedColor;
  final Color? rippleColor;

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() {
      _pressed = pressed;
    });
  }

  void _invoke(VoidCallback callback) {
    if (!widget.deferToNextFrame) {
      _setPressed(false);
      callback();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _setPressed(false);
      callback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pressedColor =
        widget.pressedColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final rippleColor =
        widget.rippleColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.10);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      end: _pressed ? pressedColor : Colors.transparent,
                    ),
                    duration: widget.pressedDuration,
                    builder: (context, color, _) {
                      if (widget.customBorder != null) {
                        return DecoratedBox(
                          decoration: ShapeDecoration(
                            color: color,
                            shape: widget.customBorder!,
                          ),
                        );
                      }
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: widget.borderRadius,
                        ),
                      );
                    },
                  ),
                ),
              ),
              InkResponse(
                containedInkWell: true,
                splashFactory: InkRipple.splashFactory,
                highlightColor: Colors.transparent,
                splashColor: widget.enableRipple
                    ? rippleColor
                    : Colors.transparent,
                onTapDown: (_) => _setPressed(true),
                onTapCancel: () => _setPressed(false),
                onTap: () => _invoke(widget.onTap),
                onLongPress: widget.onLongPress == null
                    ? null
                    : () => _invoke(widget.onLongPress!),
                borderRadius: widget.customBorder == null
                    ? widget.borderRadius
                    : null,
                customBorder: widget.customBorder,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
