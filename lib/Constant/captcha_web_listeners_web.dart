import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../SignUp /signup_provider.dart';

void setupCaptchaListeners(SignupProvider provider) {
  web.window.addEventListener(
    'captcha-success',
    ((web.Event event) {
      try {
        if (event.isA<web.CustomEvent>()) {
          final customEvent = event as web.CustomEvent;
          final detail = customEvent.detail;
          if (detail != null && detail.isDefinedAndNotNull) {
            final token = (detail as JSString).toDart;
            if (token.isNotEmpty) {
              provider.setCaptchaVerified(true, token: token);
            } else {
              provider.setCaptchaVerified(false);
            }
          } else {
            provider.setCaptchaVerified(false);
          }
        }
      } catch (e) {
        provider.setCaptchaVerified(false);
      }
    }).toJS,
  );

  web.window.addEventListener(
    'captcha-expired',
    ((web.Event event) {
      provider.setCaptchaVerified(false);
    }).toJS,
  );
}
