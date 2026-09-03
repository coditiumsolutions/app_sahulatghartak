import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/service_requests_screen.dart';
import '../utils/motion.dart';
import 'bottom_nav.dart';

/// Hosts the three primary customer tabs (Home, Requests, Profile) behind a
/// single [Scaffold] and bottom navigation bar, switching between them with
/// a Scale & Cross-Fade transition instead of pushing a new route per tab.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  static const _tabs = <int, Widget>{
    0: HomeScreen(embedded: true),
    1: ServiceRequestsScreen(embedded: true),
    2: ProfileScreen(embedded: true),
  };

  void _onTabSelected(int index) {
    if (index == _selectedIndex || !_tabs.containsKey(index)) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: kMediumAnimDuration,
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _tabs[_selectedIndex]!,
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
