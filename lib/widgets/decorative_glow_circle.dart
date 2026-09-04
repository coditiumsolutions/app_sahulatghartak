import 'package:flutter/material.dart';

/// Translucent decorative circle used in gradient headers. Scales with
/// viewport width (baseline ~390dp, where [size] renders unchanged) so it
/// doesn't stay pinned at a fixed pixel size on wide windows.
class DecorativeGlowCircle extends StatelessWidget {
  final double baseSize;
  final Color color;

  const DecorativeGlowCircle({super.key, required this.baseSize, required this.color});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = (baseSize * width / 390).clamp(baseSize * 0.6, baseSize * 1.8);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
