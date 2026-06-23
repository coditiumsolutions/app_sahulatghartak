import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/service_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/bookings_list_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SahulatApp());
}

class SahulatApp extends StatelessWidget {
  const SahulatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Sahulat Ghar Tak',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
          useMaterial3: true,
        ),
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          CategoriesScreen.routeName: (_) => const CategoriesScreen(),
          ServiceDetailScreen.routeName: (_) => const ServiceDetailScreen(),
          BookingScreen.routeName: (_) => const BookingScreen(),
          BookingsListScreen.routeName: (_) => const BookingsListScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
