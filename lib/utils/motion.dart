import 'package:flutter/material.dart';

/// Shared timing/curve constants for the app's implicit UI animations
/// (selection pills, tab indicators, icon/label swaps, expand-collapse).
/// Keeping these in one place stops animation speeds drifting out of sync
/// as individual widgets get tweaked over time. Route transitions are
/// intentionally not covered here — those use Flutter's platform-default
/// (Cupertino slide on iOS, Material on Android) via plain
/// [Navigator.push]/[Navigator.pushNamed], with no custom override.
const kQuickAnimDuration = Duration(milliseconds: 180);
const kMediumAnimDuration = Duration(milliseconds: 260);
const kSlowAnimDuration = Duration(milliseconds: 320);

const kStandardCurve = Curves.easeOut;
const kEmphasizedCurve = Curves.easeOutCubic;
