/// Exam Statistics Entity
/// Domain layer entity for exam statistics
class ExamStatistics {
  final int totalExams;                // 总考试次数
  final int passedExams;               // 及格次数
  final int totalQuestionsAttempted;   // 总答题数
  final int totalCorrectAnswers;       // 总正确数
  final double averageAccuracy;        // 平均正确率
  final double averageScore;           // 平均分
  final int bestScore;                 // 最高分
  final int worstScore;                // 最低分
  final int currentStreak;             // 当前连续及格次数
  final int bestStreak;                // 最佳连续及格次数
  final Map<String, CategoryStats> categoryStats;

  const ExamStatistics({
    required this.totalExams,
    required this.passedExams,
    required this.totalQuestionsAttempted,
    required this.totalCorrectAnswers,
    required this.averageAccuracy,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.categoryStats,
  });

  /// Get pass rate percentage
  double get passRate => totalExams > 0
      ? (passedExams / totalExams) * 100
      : 0.0;

  /// Calculate overall grade
  String get grade {
    if (averageScore >= 90) return 'A';
    if (averageScore >= 80) return 'B';
    if (averageScore >= 70) return 'C';
    if (averageScore >= 60) return 'D';
    return 'F';
  }
}

/// Category Statistics
/// Statistics for a specific question category
class CategoryStats {
  final String categoryId;
  final String categoryName;
  final int totalAttempts;            // 该分类总尝试次数
  final int correctAnswers;            // 正确次数
  final double accuracy;               // 正确率
  final int lastExamScore;             // 最近一次该分类的得分

  const CategoryStats({
    required this.categoryId,
    required this.categoryName,
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracy,
    required this.lastExamScore,
  });
}
