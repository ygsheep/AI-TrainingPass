/// Hive Service
/// Platform-specific implementation is conditionally imported:
/// - IO platforms (Android, iOS, Windows, macOS, Linux): hive_service_io.dart
/// - Web platform: hive_service_web.dart
library;

// Use web implementation as default, override with IO on IO platforms
export 'hive_service_web.dart'
    if (dart.library.io) 'hive_service_io.dart';
