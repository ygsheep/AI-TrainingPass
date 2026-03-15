/// File Service Stub for conditional imports
/// This file is used as base for platform-specific implementations

// Common classes and types are defined here
// Platform-specific implementations extend or use these

/// Import Result
class ImportResult {
  final bool success;
  final List? questions;
  final String? version;
  final String? name;
  final int? totalQuestions;
  final List<String>? categories;
  final String? errorMessage;

  const ImportResult({
    required this.success,
    this.questions,
    this.version,
    this.name,
    this.totalQuestions,
    this.categories,
    this.errorMessage,
  });

  factory ImportResult.success({
    required List questions,
    required String version,
    required String name,
    required int totalQuestions,
    List<String>? categories,
  }) {
    return ImportResult(
      success: true,
      questions: questions,
      version: version,
      name: name,
      totalQuestions: totalQuestions,
      categories: categories,
    );
  }

  factory ImportResult.error(String message) {
    return ImportResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Question Bank File Info
class QuestionBankFile {
  final String path;
  final String name;
  final String version;
  final int totalQuestions;
  final DateTime createdAt;

  const QuestionBankFile({
    required this.path,
    required this.name,
    required this.version,
    required this.totalQuestions,
    required this.createdAt,
  });

  String get formattedSize => 'Unknown';
}
