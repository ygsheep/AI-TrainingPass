/// Category Statistics Entity
/// Provides statistics for a specific question category
class CategoryStatistics {
  /// Category identifier (e.g., 'foundation', 'operate')
  final String categoryId;

  /// Display name for the category
  final String categoryName;

  /// Total number of questions in this category
  final int totalCount;

  /// Number of questions that have been answered
  final int answeredCount;

  /// Number of correctly answered questions
  final int correctCount;

  const CategoryStatistics({
    required this.categoryId,
    required this.categoryName,
    required this.totalCount,
    required this.answeredCount,
    required this.correctCount,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (answeredCount == 0) return 0.0;
    return (correctCount / answeredCount) * 100;
  }

  /// Calculate completion percentage
  double get completion {
    if (totalCount == 0) return 0.0;
    return (answeredCount / totalCount) * 100;
  }

  /// Number of incorrectly answered questions
  int get wrongCount => answeredCount - correctCount;

  CategoryStatistics copyWith({
    String? categoryId,
    String? categoryName,
    int? totalCount,
    int? answeredCount,
    int? correctCount,
  }) {
    return CategoryStatistics(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      totalCount: totalCount ?? this.totalCount,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  /// Create empty statistics
  static CategoryStatistics empty({
    required String categoryId,
    required String categoryName,
  }) {
    return CategoryStatistics(
      categoryId: categoryId,
      categoryName: categoryName,
      totalCount: 0,
      answeredCount: 0,
      correctCount: 0,
    );
  }

  @override
  String toString() {
    return 'CategoryStatistics(categoryId: $categoryId, categoryName: $categoryName, '
        'totalCount: $totalCount, answeredCount: $answeredCount, correctCount: $correctCount, '
        'accuracy: ${accuracy.toStringAsFixed(1)}%, completion: ${completion.toStringAsFixed(1)}%)';
  }
}
