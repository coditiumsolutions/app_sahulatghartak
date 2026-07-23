import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/service_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/category_provider.dart';
import 'providers/client_address_provider.dart';
import 'providers/customer_service_request_provider.dart';
import 'providers/provider_bookings_provider.dart';
import 'providers/provider_dashboard_provider.dart';
import 'providers/provider_document_provider.dart';
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
import 'screens/categories_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/service_providers_screen.dart';
import 'screens/service_request_form_screen.dart';
import 'screens/service_requests_screen.dart';
import 'screens/subcategories_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/bookings_list_screen.dart';
import 'screens/provider/chat/chat_list_screen.dart';
import 'screens/provider/dashboard/online_status_screen.dart';
import 'screens/provider/documents/documents_screen.dart';
import 'screens/provider/jobs/job_history_screen.dart';
import 'screens/provider/profile/edit_profile_screen.dart';
import 'screens/provider/profile/verification_documents_screen.dart';
import 'screens/provider/requests/my_quotes_screen.dart';
import 'screens/provider/reviews/reviews_screen.dart';
import 'screens/provider/notifications/notifications_screen.dart';
import 'screens/provider/schedule/availability_schedule_screen.dart';
import 'screens/provider/services/services_offered_screen.dart';
import 'screens/provider/settings/settings_screen.dart';
import 'screens/provider/support/support_center_screen.dart';
import 'screens/provider/wallet/wallet_screen.dart';
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
  const SahulatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProviderDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProviderBookingsProvider()),
        ChangeNotifierProvider(create: (_) => ClientAddressProvider()),
        ChangeNotifierProvider(create: (_) => CustomerServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => ProviderDocumentProvider()),
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
          CategoriesScreen.routeName: (_) => const CategoriesScreen(),
          ServiceDetailScreen.routeName: (_) => const ServiceDetailScreen(),
          ServiceProvidersScreen.routeName: (_) => const ServiceProvidersScreen(),
          SubCategoriesScreen.routeName: (_) => const SubCategoriesScreen(),
          ServiceRequestFormScreen.routeName: (_) => const ServiceRequestFormScreen(),
          ServiceRequestsScreen.routeName: (_) => const ServiceRequestsScreen(),
          BookingScreen.routeName: (_) => const BookingScreen(),
          BookingsListScreen.routeName: (_) => const BookingsListScreen(),
          OnlineStatusScreen.routeName: (_) => const OnlineStatusScreen(),
          MyQuotesScreen.routeName: (_) => const MyQuotesScreen(),
          JobHistoryScreen.routeName: (_) => const JobHistoryScreen(),
          WalletScreen.routeName: (_) => const WalletScreen(),
          ReviewsScreen.routeName: (_) => const ReviewsScreen(),
          NotificationsScreen.routeName: (_) => const NotificationsScreen(),
          ChatListScreen.routeName: (_) => const ChatListScreen(),
          AvailabilityScheduleScreen.routeName: (_) => const AvailabilityScheduleScreen(),
          ServicesOfferedScreen.routeName: (_) => const ServicesOfferedScreen(),
          DocumentsScreen.routeName: (_) => const DocumentsScreen(),
          SupportCenterScreen.routeName: (_) => const SupportCenterScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          EditProfileScreen.routeName: (_) => const EditProfileScreen(),
          VerificationDocumentsScreen.routeName: (_) => const VerificationDocumentsScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
