import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF6366F1); // Indigo
const kSecondaryColor = Color(0xFFEC4899); // Pink
const kAccentColor = Color(0xFF14B8A6); // Teal

/// Prominent filled button style for primary profile-page actions.
ButtonStyle kProminentFilledButtonStyle(Color color) => ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

/// Prominent outlined button style for secondary profile-page actions.
ButtonStyle kProminentOutlinedButtonStyle(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      backgroundColor: color.withOpacity(0.06),
      side: BorderSide(color: color, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );

// Local dev server (debug builds) vs. deployed server (release/profile builds).
// The Android emulator can't reach the host machine via "localhost" - it
// needs the special 10.0.2.2 alias instead. Every other target (iOS
// simulator, Windows/macOS/Linux desktop, web) reaches the host via localhost.
final String _devHost =
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

final String kApiBaseUrl = kDebugMode
    ? 'https://$_devHost:7265/api'
    : 'https://sahulatghartak.com/api';

/// Server root (no `/api` suffix) for resolving relative file paths returned
/// by the API, e.g. "uploads/providers/25/profile.jpg".
final String kApiFileBaseUrl = kApiBaseUrl.substring(0, kApiBaseUrl.length - '/api'.length);
