/// Question Summary Entity
/// Lightweight representation of a question for list display
/// Contains only essential information without full question content
class QuestionSummary {
  /// Unique identifier
  final String id;

  /// Question category (e.g., "Java", "Python")
  final String category;

  /// Question type (single, multiple, judge, fill)
  final String type;

  /// Difficulty level (1=easy, 2=medium, 3=hard)
  final int? difficulty;

  /// Brief description of the question (first 30 chars)
  final String? title;

  /// Whether the user has answered this question
  final bool hasAnswered;

  /// Whether the last answer was correct
  final bool isCorrect;

  /// Number of times answered incorrectly
  final int wrongCount;

  /// Last time this question was answered
  final DateTime? lastAnsweredAt;

  /// Total number of attempts
  final int? totalAttempts;

  /// Whether this question is in the wrong book
  final bool inWrongBook;

  const QuestionSummary({
    required this.id,
    required this.category,
    required this.type,
    this.difficulty,
    this.title,
    this.hasAnswered = false,
    this.isCorrect = false,
    this.wrongCount = 0,
    this.lastAnsweredAt,
    this.totalAttempts,
    this.inWrongBook = false,
  });

  /// Copy with method for immutability
  QuestionSummary copyWith({
    String? id,
    String? category,
    String? type,
    int? difficulty,
    String? title,
    bool? hasAnswered,
    bool? isCorrect,
    int? wrongCount,
    DateTime? lastAnsweredAt,
    int? totalAttempts,
    bool? inWrongBook,
  }) {
    return QuestionSummary(
      id: id ?? this.id,
      category: category ?? this.category,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      title: title ?? this.title,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      isCorrect: isCorrect ?? this.isCorrect,
      wrongCount: wrongCount ?? this.wrongCount,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      inWrongBook: inWrongBook ?? this.inWrongBook,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
