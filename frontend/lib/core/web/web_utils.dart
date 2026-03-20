/// Conditional export:
///   • On Flutter web  → web_utils_web.dart  (dart:html available)
///   • On other targets → web_utils_stub.dart (no-ops)
export 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart';
