import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 16),
            Text('Sahulat Ghar Tak', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Quality Services Delivered to Your Doorstep', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          ],
        ).animate().fade().scale(),
      ),
    );
  }
}
