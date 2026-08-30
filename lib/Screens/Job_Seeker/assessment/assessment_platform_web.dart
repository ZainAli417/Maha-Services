import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Buzzes the device.
///
/// Flutter's own haptics are close to a no-op on web, so this goes straight to
/// the Vibration API, which Chrome and Firefox support on Android. Desktop
/// browsers have nothing to vibrate and ignore the call — which is why the
/// screen also flashes the answer in colour rather than relying on feel.
void vibrate(int milliseconds) {
  try {
    web.window.navigator.vibrate(milliseconds.toJS);
  } catch (_) {
    // Some browsers throw rather than ignore it; the visual feedback stands
    // on its own, so there is nothing to recover from here.
    HapticFeedback.lightImpact();
  }
}

bool _guardArmed = false;

void _onBeforeUnload(web.Event event) {
  final e = event as web.BeforeUnloadEvent;
  e.preventDefault();
  // Browsers show their own wording and ignore ours, but the string still has
  // to be set for the prompt to appear at all in older engines.
  e.returnValue = 'Your assessment is still running.';
}

/// Warns before the tab is closed mid-test.
///
/// The clock keeps running server-side either way — this is a courtesy, not a
/// control. Anyone determined to leave still can.
void setExitGuard(bool enabled) {
  if (enabled == _guardArmed) return;
  _guardArmed = enabled;
  if (enabled) {
    web.window.addEventListener('beforeunload', _onBeforeUnload.toJS);
  } else {
    web.window.removeEventListener('beforeunload', _onBeforeUnload.toJS);
  }
}
