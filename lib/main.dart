import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/category_provider.dart';
import 'providers/service_catalog_provider.dart';
import 'providers/client_address_provider.dart';
import 'providers/customer_service_request_provider.dart';
import 'providers/provider_bookings_provider.dart';
import 'providers/provider_dashboard_provider.dart';
import 'providers/provider_document_provider.dart';
import 'providers/provider_wallet_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/customer_registration_screen.dart';
import 'screens/provider_registration_screen.dart';
import 'screens/provider_document_upload_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/main_navigation_shell.dart';
import 'screens/service_detail_screen.dart';
import 'screens/service_providers_screen.dart';
import 'screens/service_request_form_screen.dart';
import 'screens/service_requests_screen.dart';
import 'screens/subcategories_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/provider/notifications/notifications_screen.dart';
import 'screens/provider/profile/edit_profile_screen.dart';
import 'screens/provider/profile/verification_documents_screen.dart';
import 'utils/constants.dart';
import 'utils/dev_http_overrides.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }
  runApp(const SahulatApp());
}

class SahulatApp extends StatelessWidget {
  const SahulatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ServiceCatalogProvider()),
        ChangeNotifierProvider(create: (_) => ProviderDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProviderBookingsProvider()),
        ChangeNotifierProvider(create: (_) => ClientAddressProvider()),
        ChangeNotifierProvider(create: (_) => CustomerServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => ProviderDocumentProvider()),
        ChangeNotifierProvider(create: (_) => ProviderWalletProvider()),
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
          LandingScreen.routeName: (_) => const LandingScreen(),
          CustomerRegistrationScreen.routeName: (_) => const CustomerRegistrationScreen(),
          ProviderRegistrationScreen.routeName: (_) => const ProviderRegistrationScreen(),
          ProviderDocumentUploadScreen.routeName: (_) => const ProviderDocumentUploadScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          OtpVerificationScreen.routeName: (_) => const OtpVerificationScreen(),
          ProviderDashboardScreen.routeName: (_) => const ProviderDashboardScreen(),
          HomeScreen.routeName: (_) => const MainNavigationShell(),
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          AddAddressScreen.routeName: (_) => const AddAddressScreen(),
          ServiceDetailScreen.routeName: (_) => const ServiceDetailScreen(),
          ServiceProvidersScreen.routeName: (_) => const ServiceProvidersScreen(),
          SubCategoriesScreen.routeName: (_) => const SubCategoriesScreen(),
          ServiceRequestFormScreen.routeName: (_) => const ServiceRequestFormScreen(),
          ServiceRequestsScreen.routeName: (_) => const ServiceRequestsScreen(),
          BookingScreen.routeName: (_) => const BookingScreen(),
          EditProfileScreen.routeName: (_) => const EditProfileScreen(),
          VerificationDocumentsScreen.routeName: (_) => const VerificationDocumentsScreen(),
          NotificationsScreen.routeName: (_) => const NotificationsScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
