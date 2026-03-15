/// Question Repository Implementation
/// Platform-specific implementation is conditionally imported:
/// - IO platforms (Android, iOS, Windows, macOS, Linux): question_repository_io.dart
/// - Web platform: question_repository_web.dart
library;

// Export base (contains QuestionRepositoryBase abstract class)
export 'question_repository_base.dart';

// Use web implementation as default, override with IO on IO platforms
export 'question_repository_web.dart'
    if (dart.library.io) 'question_repository_io.dart';
