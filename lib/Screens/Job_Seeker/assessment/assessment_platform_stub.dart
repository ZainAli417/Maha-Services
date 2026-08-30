import 'package:flutter/services.dart';

/// Buzzes the device.
///
/// On Android and iOS this is the engine's own haptic channel. Desktop has no
/// vibration motor, so this is a no-op there — the screen never relies on it
/// alone, and always shows the answer in colour as well.
void vibrate(int milliseconds) {
  if (milliseconds >= 120) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.lightImpact();
  }
}

/// Asks the browser to confirm before the tab is closed. Native builds have no
/// equivalent — the in-app back button is already blocked — so this does
/// nothing here.
void setExitGuard(bool enabled) {}
