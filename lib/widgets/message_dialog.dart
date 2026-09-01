import 'package:flutter/material.dart';

import '../utils/constants.dart';

const _brandDark = Color(0xFF0A4FA8);

enum MessageDialogType { success, error, info }

/// A branded, must-acknowledge dialog for flow-outcome messages (e.g. "Account
/// not found", "Password reset successfully.") that are too easy to miss as a
/// [SnackBar]. Visually matches [showConfirmDialog].
///
/// When [secondaryButtonLabel] is omitted, the dialog can only be dismissed
/// via the single primary button (`barrierDismissible: false`), so callers
/// can safely `await` it before navigating. When [secondaryButtonLabel] is
/// provided, the dialog also gets a dismiss-only action (and becomes
/// barrier-dismissible) so users aren't forced down the primary path — the
/// returned future resolves `true` if the primary button was tapped, `false`
/// if the user dismissed it instead.
Future<bool> showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  MessageDialogType type = MessageDialogType.info,
  String buttonLabel = 'OK',
  String? secondaryButtonLabel,
}) async {
  Color color;
  IconData icon;
  switch (type) {
    case MessageDialogType.success:
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle_outline_rounded;
      break;
    case MessageDialogType.error:
      color = Colors.red;
      icon = Icons.error_outline_rounded;
      break;
    case MessageDialogType.info:
      color = kPrimaryColor;
      icon = Icons.info_outline_rounded;
      break;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: secondaryButtonLabel != null,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2233), letterSpacing: -0.2),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (secondaryButtonLabel != null)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(secondaryButtonLabel, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600])),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
