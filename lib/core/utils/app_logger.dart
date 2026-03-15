import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Application Logger
/// Provides unified logging with color-coded output and level control
class AppLogger {
  AppLogger._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
      noBoxingByDefault: false,
    ),
    filter: ProductionFilter(),
  );

  /// Debug level - detailed information for debugging
  static void d(String message) => _logger.d(message);

  /// Info level - general information
  static void i(String message) => _logger.i(message);

  /// Warning level - warning messages
  static void w(String message) => _logger.w(message);

  /// Error level - error messages
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message);
    }
  }

  /// Trace level - very detailed tracing
  static void t(String message) => _logger.t(message);

  /// Fatal error - critical errors
  static void fatal(String message) => _logger.f(message);

  /// Debug print for backward compatibility
  /// Uses debugPrint to avoid blocking main thread
  static void debug(String message) => debugPrint(message);
}

/// Production Filter
/// Disables logging in release mode
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    var shouldLog = event.level.index >= Level.debug.index;

    // In release mode, only show warnings and errors
    if (kReleaseMode) {
      shouldLog = event.level.index >= Level.warning.index;
    }

    return shouldLog;
  }
}
