import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/bookings_list_screen.dart';
import '../screens/service_detail_screen.dart';

class AppBottomNavigation extends StatefulWidget implements PreferredSizeWidget {
  const AppBottomNavigation({Key? key}) : super(key: key);

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  int _index = 0;

  final _pages = [
    const HomeScreen(),
    const CategoriesScreen(),
    const BookingsListScreen(),
    const Scaffold(body: Center(child: Text('Offers'))),
    const Scaffold(body: Center(child: Text('Profile'))),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
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
