import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kPrivacyPolicyUrl = 'https://sahulatghartak.com/privacy-policy';

Future<void> openPrivacyPolicy(BuildContext context) async {
  final uri = Uri.parse(kPrivacyPolicyUrl);
  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Privacy Policy.')));
  }
}
