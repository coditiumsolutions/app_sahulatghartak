import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../widgets/message_dialog.dart';

/// Gate for actions that require an account (e.g. submitting a service
/// request). Guests can browse freely per App Store Guideline 5.1.1, but are
/// asked to log in only when they try to do something that needs one.
/// Returns true when the user is already logged in; otherwise shows a
/// dialog and routes to [LoginScreen], returning false so callers can bail
/// out of the action that triggered the check.
Future<bool> ensureLoggedIn(
  BuildContext context, {
  String message = 'Please log in or create an account to request a service.',
}) async {
  if (context.read<AuthProvider>().isLoggedIn) return true;

  final wantsToLogIn = await showMessageDialog(
    context,
    title: 'Login Required',
    message: message,
    type: MessageDialogType.info,
    buttonLabel: 'Log In',
    secondaryButtonLabel: 'Keep Browsing',
  );
  if (!wantsToLogIn) return false;
  if (!context.mounted) return false;
  Navigator.of(context).pushNamed(LoginScreen.routeName);
  return false;
}
