import 'package:flutter/material.dart';

import '../decorative_glow_circle.dart';

const providerBrandDark = Color(0xFF0A4FA8);
const providerBrandBlue = Color(0xFF016EE3);
const providerBrandAccent = Color(0xFF4FC3F7);

/// Gradient header for provider dashboard tabs, matching the customer
/// side's [PreferredSize] brand header: same gradient and decorative glow
/// circles, with title/subtitle in place of a search field.
class ProviderTabHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? leading;

  const ProviderTabHeader({super.key, required this.title, required this.subtitle, this.trailing, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [providerBrandDark, providerBrandBlue],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x330A4FA8), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: DecorativeGlowCircle(baseSize: 150, color: providerBrandAccent.withValues(alpha: 0.14)),
            ),
            const Positioned(
              bottom: -60,
              left: -30,
              child: DecorativeGlowCircle(baseSize: 130, color: Color.fromRGBO(255, 255, 255, 0.06)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(leading != null ? 12 : 20, 4, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 12)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
