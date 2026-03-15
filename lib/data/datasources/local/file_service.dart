/// File Service
/// Platform-specific implementation is conditionally imported:
/// - IO platforms (Android, iOS, Windows, macOS, Linux): file_service_io.dart
/// - Web platform: file_service_web.dart
library;

// Export stub (common types like ImportResult, QuestionBankFile)
export 'file_service_stub.dart';

// Use web implementation as default, override with IO on IO platforms
export 'file_service_web.dart'
    if (dart.library.io) 'file_service_io.dart';
