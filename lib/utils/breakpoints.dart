import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Cap applied to primary scrollable content columns so they don't stretch
/// edge-to-edge on tablets/desktop windows.
const double kContentMaxWidth = 840;

/// Cap applied to floating/overlay panels (e.g. search suggestions), smaller
/// than [kContentMaxWidth] since these don't need to match a full page column.
const double kOverlayMaxWidth = 560;

/// Natural size of the app-icon logo shown on the landing and splash screens.
const double kAppLogoSize = 168;

/// Fraction of window width the logo shrinks to on narrow viewports.
const double kAppLogoMaxWidthFraction = 0.4;

/// Shared by `landing_screen.dart` and `splash_screen.dart`, which render the
/// same asset at the same size.
double appLogoSize(BuildContext context) =>
    math.min(kAppLogoSize, MediaQuery.sizeOf(context).width * kAppLogoMaxWidthFraction);
