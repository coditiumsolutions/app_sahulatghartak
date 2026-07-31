import 'package:flutter/material.dart';
import '../screens/service_requests_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  /// When provided, tab taps are reported here instead of navigating via
  /// named routes. Used by [MainNavigationShell] to switch tabs in place.
  final ValueChanged<int>? onTabSelected;

  const AppBottomNavigation({super.key, this.currentIndex = 0, this.onTabSelected});

  static const _routeNames = [
    HomeScreen.routeName,
    ServiceRequestsScreen.routeName,
    ProfileScreen.routeName,
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.receipt_long_rounded,
    Icons.person_rounded,
  ];

  static const _outlineIcons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline_rounded,
  ];

  static const _labels = ['Home', 'Requests', 'Profile'];

  @override
  Size get preferredSize => const Size.fromHeight(78);

  void _handleTap(BuildContext context, int i) {
    if (i == currentIndex) return;
    if (onTabSelected != null) {
      onTabSelected!(i);
      return;
    }
    final routeName = _routeNames[i];
    Navigator.of(context).pushNamed(routeName);
  }

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);
  static const _brandAccent = Color(0xFF4FC3F7);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                _NavItem(
                  icon: _icons[i],
                  outlineIcon: _outlineIcons[i],
                  label: _labels[i],
                  selected: i == currentIndex,
                  accentColor: _brandAccent,
                  onTap: () => _handleTap(context, i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single dock item: a pill that expands and glows behind the icon when
/// active, with the icon swapping between outline/filled variants.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? icon : outlineIcon,
                    key: ValueKey<bool>(selected),
                    color: selected ? accentColor : Colors.white70,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white54,
                  letterSpacing: 0.2,
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
