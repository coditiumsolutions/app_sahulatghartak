import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Icon button on a translucent frosted-glass circle (blurred backdrop, 20%
/// white fill, thin white rim). For controls that sit on the brand gradient
/// headers, where a bare white icon gets lost.
class FrostedIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final EdgeInsetsGeometry margin;
  final double size;

  const FrostedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.margin = const EdgeInsets.symmetric(horizontal: 6),
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: size,
      height: size,
      child: Center(child: icon),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);

    return Padding(
      padding: margin,
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: CircleBorder(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: button,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted back arrow. Pops the current route unless [onPressed] is given.
class FrostedBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const FrostedBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FrostedIconButton(
      tooltip: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
    );
  }
}

/// Frosted-glass rounded surface (pill or button) for text/status controls on
/// gradients and photos. [tint] colours the glass (white by default).
class FrostedSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color tint;
  final double tintOpacity;
  final EdgeInsetsGeometry padding;

  const FrostedSurface({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = 20,
    this.tint = Colors.white,
    this.tintOpacity = 0.2,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: tint.withValues(alpha: tintOpacity),
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
