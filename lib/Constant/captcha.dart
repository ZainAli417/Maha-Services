// Conditional export: picks stub on mobile, real implementation on web
export 'captcha_stub.dart' if (dart.library.js_interop) 'captcha_webview.dart';
