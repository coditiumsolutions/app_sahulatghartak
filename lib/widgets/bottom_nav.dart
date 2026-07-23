import 'package:flutter/material.dart';
import '../screens/categories_screen.dart';
import '../screens/service_requests_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  /// When provided, tab taps are reported here instead of navigating via
  /// named routes. Used by [MainNavigationShell] to switch tabs in place.
  final ValueChanged<int>? onTabSelected;

  const AppBottomNavigation({Key? key, this.currentIndex = 0, this.onTabSelected}) : super(key: key);

  static const _routeNames = [
    HomeScreen.routeName,
    CategoriesScreen.routeName,
    ServiceRequestsScreen.routeName,
    null,
    ProfileScreen.routeName,
  ];

  static const _icons = [
    Icons.home,
    Icons.grid_view,
    Icons.assignment,
    Icons.local_offer,
    Icons.person,
  ];

  static const _labels = ['Home', 'Categories', 'Requests', 'Offers', 'Profile'];

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _handleTap(BuildContext context, int i) {
    if (i == currentIndex) return;
    if (onTabSelected != null) {
      onTabSelected!(i);
      return;
    }
    final routeName = _routeNames[i];
    if (routeName != null) {
      Navigator.of(context).pushNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _handleTap(context, i),
      items: [
        for (var i = 0; i < _icons.length; i++)
          BottomNavigationBarItem(
            icon: _AnimatedNavIcon(icon: _icons[i], selected: i == currentIndex),
            label: _labels[i],
          ),
      ],
      backgroundColor: const Color(0xFF0078D4),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    );
  }
}

/// Subtly scales the active tab's icon so activation feels tactile.
class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _AnimatedNavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Icon(icon),
    );
  }
}
