import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/motion.dart';

/// Gradient pill-dock bottom navigation for the provider dashboard's 5 tabs,
/// matching the customer side's [AppBottomNavigation] visual language
/// (brand gradient background, glowing pill behind the active icon).
class ProviderBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ProviderBottomNavigation({super.key, required this.currentIndex, required this.onTabSelected});

  static const _icons = [
    Icons.home_rounded,
    Icons.inbox_rounded,
    Icons.work_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.person_rounded,
  ];

  static const _outlineIcons = [
    Icons.home_outlined,
    Icons.inbox_outlined,
    Icons.work_outline_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.person_outline_rounded,
  ];

  static const _labels = ['Home', 'Requests', 'Bookings', 'Wallet', 'Profile'];

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brandBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: _brandDark.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 78,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _icons.length; i++)
                  _ProviderNavItem(
                    icon: _icons[i],
                    outlineIcon: _outlineIcons[i],
                    label: _labels[i],
                    selected: i == currentIndex,
                    accentColor: _brandAccent,
                    onTap: () => onTabSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderNavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ProviderNavItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        splashColor: accentColor.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: kMediumAnimDuration,
                curve: kEmphasizedCurve,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? accentColor.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: kQuickAnimDuration,
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? icon : outlineIcon,
                    key: ValueKey<bool>(selected),
                    color: selected ? accentColor : Colors.white70,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: kQuickAnimDuration,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white54,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
