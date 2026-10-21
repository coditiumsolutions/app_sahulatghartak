import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../data/repositories/notification_repository.dart';
import '../models/app_config.dart';
import '../utils/deep_link_router.dart';
import '../utils/notification_router.dart';
import '../utils/update_block.dart';
import '../utils/version_compare.dart';
import 'update_required_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/time_format_provider.dart';
import '../utils/breakpoints.dart';
import '../utils/motion.dart';
import '../utils/provider_entry_gate.dart';
import 'home_screen.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authProvider = context.read<AuthProvider>();
    final updateCheck = _checkForUpdate();
    await Future.wait([
      authProvider.tryAutoLogin(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    final update = await updateCheck;
    if (!mounted) return;
    if (update != null && update.$1 == AppUpdateKind.required) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(config: update.$2)));
      return;
    }

    final userId = authProvider.currentUser?.userId;
    if (userId != null) await context.read<TimeFormatProvider>().load(userId);
    if (!mounted) return;

    if (!authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(LandingScreen.routeName);
    } else if (authProvider.role == 'Provider') {
      // Check verification status before landing on the Provider Dashboard -
      // an unverified provider gets routed to the pending-review page instead.
      final target = await resolveProviderEntryRoute(context);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(target);
    } else {
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    }

    // Now that a real screen is up: handle a notification tap that launched
    // the app, then offer an optional update.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await routeColdStartPush();
      await routeColdStartLink();
      final ctx = navigatorKey.currentContext;
      if (update != null &&
          update.$1 == AppUpdateKind.optional &&
          ctx != null &&
          ctx.mounted) {
        // Mark it so a matching non-forced push does not repeat the dialog.
        updateBlock.markPrompted(update.$2.latestVersion);
        showUpdatePrompt(ctx, update.$2);
      }
      updateBlock.setUiReady();
    });
  }

  /// Fails open: any error or slow response just means no update gate.
  Future<(AppUpdateKind, AppConfig)?> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final config = await NotificationRepository()
          .fetchAppConfig(Platform.isIOS ? 'ios' : 'android')
          .timeout(const Duration(seconds: 5));
      return (evaluateUpdate(info.version, config), config);
    } catch (_) {
      return null;
    }
  }

  static const _brandDark = Color(0xFF0A4FA8);
  static const _brandBlue = Color(0xFF016EE3);

  @override
  Widget build(BuildContext context) {
    final logoSize = appLogoSize(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Image.asset('assets/icon/app_icon.png',
                width: logoSize, height: logoSize),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sahulat Ghar Tak',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Quality Services Delivered to Your Doorstep',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.75))),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brandDark, _brandBlue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: prefersReducedMotion(context)
                ? content
                : content
                    .animate()
                    .fade(duration: kSlowAnimDuration, curve: kStandardCurve)
                    .scale(duration: kSlowAnimDuration, curve: kStandardCurve),
          ),
        ),
      ),
    );
  }
}
