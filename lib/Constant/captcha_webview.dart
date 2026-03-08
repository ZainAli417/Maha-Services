import 'dart:async'; // Import for Timer
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void registerRecaptchaView(String siteKey) {
  ui_web.platformViewRegistry.registerViewFactory('recaptcha-view', (int viewId) {
    final wrapper = web.HTMLDivElement()
      ..style.width = '304px'
      ..style.height = '78px'
      ..style.display = 'inline-block';

    final captchaDiv = web.HTMLDivElement()
      ..id = 'recaptcha-$viewId';

    wrapper.append(captchaDiv);

    // LOGIC EXTRACTED: define the render function
    void renderCaptcha() {
      final global = globalContext;
      final grecaptcha = global.getProperty('grecaptcha'.toJS);

      if (grecaptcha != null && grecaptcha.isDefinedAndNotNull) {
        final opts = JSObject();
        opts.setProperty('sitekey'.toJS, siteKey.toJS);

        opts.setProperty('callback'.toJS, ((JSString token) {
          final event = web.CustomEvent(
            'captcha-success',
            web.CustomEventInit(detail: token.toDart.toJS),
          );
          web.window.dispatchEvent(event);
        }).toJS);

        opts.setProperty('expired-callback'.toJS, (() {
          final event = web.CustomEvent('captcha-expired');
          web.window.dispatchEvent(event);
        }).toJS);

        (grecaptcha as JSObject).callMethodVarArgs(
          'render'.toJS,
          [captchaDiv, opts],
        );
      }
    }

    // NEW: Polling mechanism
    // Check if grecaptcha is ready. If not, retry every 100ms for 10 seconds.
    final global = globalContext;
    final grecaptcha = global.getProperty('grecaptcha'.toJS);

    if (grecaptcha != null && grecaptcha.isDefinedAndNotNull) {
      renderCaptcha();
    } else {
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        final retryGlobal = globalContext;
        final retryGrecaptcha = retryGlobal.getProperty('grecaptcha'.toJS);

        if (retryGrecaptcha != null && retryGrecaptcha.isDefinedAndNotNull) {
          renderCaptcha();
          timer.cancel(); // Stop checking once found
        } else if (timer.tick > 100) {
          timer.cancel(); // Stop checking after ~10 seconds to prevent memory leaks
          print('Error: reCAPTCHA script failed to load.');
        }
      });
    }

    return wrapper;
  });
}