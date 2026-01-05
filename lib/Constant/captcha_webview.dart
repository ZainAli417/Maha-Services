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

    // Schedule microtask to access global and render
    Future.microtask(() {
      final global = globalContext;

      // Access grecaptcha from global context using extension
      final grecaptcha = global.getProperty('grecaptcha'.toJS);

      if (grecaptcha != null && grecaptcha.isDefinedAndNotNull) {
        // Create options object
        final opts = JSObject();

        // Set properties using setProperty extension
        opts.setProperty('sitekey'.toJS, siteKey.toJS);

        // Create callback function
        opts.setProperty('callback'.toJS, ((JSString token) {
          // Dispatch custom event with token
          final event = web.CustomEvent(
            'captcha-success',
            web.CustomEventInit(detail: token.toDart.toJS),
          );
          web.window.dispatchEvent(event);
        }).toJS);

        // Create expired callback
        opts.setProperty('expired-callback'.toJS, (() {
          final event = web.CustomEvent('captcha-expired');
          web.window.dispatchEvent(event);
        }).toJS);

        // Call grecaptcha.render(captchaDiv, opts)
        // HTMLDivElement is already a JSAny, no need for .toJS
        (grecaptcha as JSObject).callMethodVarArgs(
          'render'.toJS,
          [captchaDiv, opts],
        );
      }
    });

    return wrapper;
  });
}