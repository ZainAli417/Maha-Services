import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Touch feedback for the onboarding flow, in one place.
///
/// Every call is safe to make unconditionally: haptics are a no-op on web and
/// desktop, and on mobile the OS honours the user's system-wide touch-feedback
/// setting. Callers therefore never have to guard, which is what keeps the
/// feedback consistent — the moment a widget has to think about platform it
/// tends to skip the call entirely.
///
/// The three levels are a deliberate vocabulary, not a volume dial:
abstract final class Haptics {
  static bool get _enabled =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// A value changed inside a control — a chip toggled, an option picked, a
  /// month tapped. The lightest tick; fires often, so it must stay subtle.
  static void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// A discrete action landed — a step advanced, a row was added, a file
  /// attached. Rarer than [selection] and worth actually feeling.
  static void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  /// A milestone or a refusal — the form submitted, or validation blocked it.
  /// Reserved for moments the candidate must not miss.
  static void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }
}
