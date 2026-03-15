/// Download Utility
/// Platform-specific implementation for triggering file downloads
library;

// Default stub (will be overridden by platform-specific implementations)
export 'download_util_stub.dart'
    if (dart.library.html) 'download_util_web.dart'
    if (dart.library.io) 'download_util_io.dart';
