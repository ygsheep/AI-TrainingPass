/// Question Filter
/// Used for filtering questions by various criteria
class QuestionFilter {
  /// Filter by category (e.g., "Java", "Python")
  final String? category;

  /// Filter by question type (single, multiple, judge, fill)
  final String? type;

  /// Filter by difficulty level (1=easy, 2=medium, 3=hard)
  final int? difficulty;

  /// Filter by answer status
  final AnswerStatus? answerStatus;

  /// Filter by wrong book membership
  final bool? inWrongBook;

  /// Search keyword (searches in question content)
  final String? searchKeyword;

  const QuestionFilter({
    this.category,
    this.type,
    this.difficulty,
    this.answerStatus,
    this.inWrongBook,
    this.searchKeyword,
  });

  /// Create a copy with modified fields
  QuestionFilter copyWith({
    String? category,
    String? type,
    int? difficulty,
    AnswerStatus? answerStatus,
    bool? inWrongBook,
    String? searchKeyword,
    // Use nullable bool to allow setting to null
    Object? categoryNull,
    Object? typeNull,
    Object? difficultyNull,
    Object? answerStatusNull,
    Object? inWrongBookNull,
    Object? searchKeywordNull,
  }) {
    return QuestionFilter(
      category: categoryNull == null ? category : null as String?,
      type: typeNull == null ? type : null as String?,
      difficulty: difficultyNull == null ? difficulty : null as int?,
      answerStatus: answerStatusNull == null ? answerStatus : null as AnswerStatus?,
      inWrongBook: inWrongBookNull == null ? inWrongBook : null as bool?,
      searchKeyword: searchKeywordNull == null ? searchKeyword : null as String?,
    );
  }

  /// Check if filter has any active filters
  bool get hasFilters =>
      category != null ||
      type != null ||
      difficulty != null ||
      answerStatus != null ||
      inWrongBook != null ||
      searchKeyword != null;

  /// Create empty filter
  static const empty = QuestionFilter();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          type == other.type &&
          difficulty == other.difficulty &&
          answerStatus == other.answerStatus &&
          inWrongBook == other.inWrongBook &&
          searchKeyword == other.searchKeyword;

  @override
  int get hashCode =>
      category.hashCode ^
      type.hashCode ^
      difficulty.hashCode ^
      answerStatus.hashCode ^
      inWrongBook.hashCode ^
      searchKeyword.hashCode;
}

/// Answer Status Enum
enum AnswerStatus {
  /// Question has not been answered
  notAnswered,

  /// Question was answered correctly
  correct,

  /// Question was answered incorrectly
  wrong,

  /// Show all questions regardless of status
  all,
}
