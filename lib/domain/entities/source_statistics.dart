/// Source Statistics
/// Provides statistics about questions from a specific source
class SourceStatistics {
  /// Source code (e.g., 'main', 'mock', 'review')
  final String source;

  /// Display name (e.g., '理论题试题', '理论题模拟题')
  final String displayName;

  /// Total number of questions from this source
  final int totalCount;

  /// Question distribution by type
  /// Key: 'single', 'multiple', 'judge', 'essay'
  /// Value: count of questions of that type
  final Map<String, int> typeDistribution;

  /// Optional historical exam statistics for this source
  final ExamHistoryStats? history;

  const SourceStatistics({
    required this.source,
    required this.displayName,
    required this.totalCount,
    required this.typeDistribution,
    this.history,
  });

  /// Get count for a specific question type
  int getTypeCount(String type) {
    return typeDistribution[type] ?? 0;
  }

  /// Create a copy with modified fields
  SourceStatistics copyWith({
    String? source,
    String? displayName,
    int? totalCount,
    Map<String, int>? typeDistribution,
    ExamHistoryStats? history,
  }) {
    return SourceStatistics(
      source: source ?? this.source,
      displayName: displayName ?? this.displayName,
      totalCount: totalCount ?? this.totalCount,
      typeDistribution: typeDistribution ?? this.typeDistribution,
      history: history ?? this.history,
    );
  }

  @override
  String toString() {
    return 'SourceStatistics(source: $source, name: $displayName, '
        'total: $totalCount, types: $typeDistribution)';
  }
}

/// Exam History Statistics
/// Contains historical performance data for exams
class ExamHistoryStats {
  /// Average score across all exams (0-100)
  final double averageScore;

  /// Highest score achieved (0-100)
  final int highestScore;

  /// Pass rate (0.0 to 1.0)
  final double passRate;

  /// Total number of exams taken
  final int examCount;

  const ExamHistoryStats({
    required this.averageScore,
    required this.highestScore,
    required this.passRate,
    required this.examCount,
  });

  /// Get pass rate as percentage (0-100)
  double get passRatePercentage => passRate * 100;

  /// Create a copy with modified fields
  ExamHistoryStats copyWith({
    double? averageScore,
    int? highestScore,
    double? passRate,
    int? examCount,
  }) {
    return ExamHistoryStats(
      averageScore: averageScore ?? this.averageScore,
      highestScore: highestScore ?? this.highestScore,
      passRate: passRate ?? this.passRate,
      examCount: examCount ?? this.examCount,
    );
  }

  /// Create empty stats for sources with no exam history
  factory ExamHistoryStats.empty() {
    return const ExamHistoryStats(
      averageScore: 0.0,
      highestScore: 0,
      passRate: 0.0,
      examCount: 0,
    );
  }

  @override
  String toString() {
    return 'ExamHistoryStats(avg: ${averageScore.toStringAsFixed(1)}, '
        'highest: $highestScore, passRate: ${(passRate * 100).toStringAsFixed(0)}%, '
        'count: $examCount)';
  }
}
