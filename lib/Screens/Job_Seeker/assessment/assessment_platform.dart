// Platform bits the assessment screen needs that Flutter does not abstract.
//
// Kept behind a conditional export so the screen itself stays platform-free:
// on Android the vibration goes through the engine, on web through the
// browser's own API, and neither file has to know the other exists.
export 'assessment_platform_stub.dart'
    if (dart.library.js_interop) 'assessment_platform_web.dart';
