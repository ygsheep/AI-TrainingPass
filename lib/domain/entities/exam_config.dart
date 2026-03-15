/// Exam Template
/// Defines preset exam configurations
enum ExamTemplate {
  /// Standard exam: 90 minutes, 100 questions
  standard,

  /// Quick exam: 30 minutes, 30 questions
  quick,

  /// Practice exam: 60 minutes, 50 questions
  practice,

  /// Custom user-defined configuration
  custom,
}

/// Exam Configuration
/// Contains all parameters for an exam session
class ExamConfig {
  /// Selected preset template
  final ExamTemplate template;

  /// Question sources to draw from (e.g., ['main', 'mock'])
  final List<String> sources;

  /// Exam duration in minutes
  final int durationMinutes;

  /// Total number of questions
  final int totalQuestions;

  /// Question type allocation
  /// Key: 'single', 'multiple', 'judge'
  /// Value: count of questions for that type
  final Map<String, int> typeAllocation;

  /// Passing score (0-100)
  final int passScore;

  const ExamConfig({
    required this.template,
    required this.sources,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.typeAllocation,
    required this.passScore,
  });

  /// Get number of questions for a specific type
  int getTypeCount(String type) {
    return typeAllocation[type] ?? 0;
  }

  /// Create a copy with modified fields
  ExamConfig copyWith({
    ExamTemplate? template,
    List<String>? sources,
    int? durationMinutes,
    int? totalQuestions,
    Map<String, int>? typeAllocation,
    int? passScore,
  }) {
    return ExamConfig(
      template: template ?? this.template,
      sources: sources ?? this.sources,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      typeAllocation: typeAllocation ?? this.typeAllocation,
      passScore: passScore ?? this.passScore,
    );
  }

  /// Get the standard template configuration (90 min, 100 questions)
  factory ExamConfig.standard() {
    return const ExamConfig(
      template: ExamTemplate.standard,
      sources: ['main'], // Default to main source
      durationMinutes: 90,
      totalQuestions: 100,
      typeAllocation: {
        'single': 60,
        'multiple': 20,
        'judge': 20,
      },
      passScore: 60,
    );
  }

  /// Get the quick template configuration (30 min, 30 questions)
  factory ExamConfig.quick() {
    return const ExamConfig(
      template: ExamTemplate.quick,
      sources: ['main'],
      durationMinutes: 30,
      totalQuestions: 30,
      typeAllocation: {
        'single': 20,
        'multiple': 5,
        'judge': 5,
      },
      passScore: 60,
    );
  }

  /// Get the practice template configuration (60 min, 50 questions)
  factory ExamConfig.practice() {
    return const ExamConfig(
      template: ExamTemplate.practice,
      sources: ['main'],
      durationMinutes: 60,
      totalQuestions: 50,
      typeAllocation: {
        'single': 30,
        'multiple': 10,
        'judge': 10,
      },
      passScore: 60,
    );
  }

  @override
  String toString() {
    return 'ExamConfig(template: $template, sources: $sources, '
        'duration: ${durationMinutes}m, questions: $totalQuestions, '
        'allocation: $typeAllocation, passScore: $passScore)';
  }
}
