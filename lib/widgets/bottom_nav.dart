import 'package:flutter/material.dart';
import '../screens/categories_screen.dart';
import '../screens/bookings_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class AppBottomNavigation extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  const AppBottomNavigation({Key? key, this.currentIndex = 0}) : super(key: key);

  static const _routeNames = [
    HomeScreen.routeName,
    CategoriesScreen.routeName,
    BookingsListScreen.routeName,
    null,
    ProfileScreen.routeName,
  ];

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        if (i == currentIndex) return;
        final routeName = _routeNames[i];
        if (routeName != null) {
          Navigator.of(context).pushNamed(routeName);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Offers'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      backgroundColor: const Color(0xFF0078D4),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    );
  }
}
