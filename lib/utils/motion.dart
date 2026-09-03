import 'package:flutter/material.dart';

/// Shared timing/curve constants for the app's implicit UI animations
/// (selection pills, tab indicators, icon/label swaps, expand-collapse).
/// Keeping these in one place stops animation speeds drifting out of sync
/// as individual widgets get tweaked over time.
///
/// Card -> detail navigation uses a Material container-transform
/// ([OpenContainer] from package:animations), not the platform-default route
/// transition — see `main_category_card.dart`, `service_requests_screen.dart`,
/// `jobs_tab.dart`, and `rejected_requests_screen.dart`. A `Hero`
/// shared-element transition was tried on these same flows and rejected: it
/// read as competing with the container-transform rather than complementing
/// it. Don't re-propose `Hero` here without new information — see
/// docs/animation-audit.md §8.5.
const kQuickAnimDuration = Duration(milliseconds: 180);
const kMediumAnimDuration = Duration(milliseconds: 260);
const kSlowAnimDuration = Duration(milliseconds: 320);

const kStandardCurve = Curves.easeOut;
const kEmphasizedCurve = Curves.easeOutCubic;

/// True when the platform's reduce-motion accessibility setting is on.
/// Decorative animations should check this and fall back to an instant
/// (`Duration.zero`) state change, or skip the animation outright when there
/// is no state to preserve (e.g. a one-shot intro).
bool prefersReducedMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);
