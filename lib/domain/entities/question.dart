/// Question Entity
/// Domain layer entity for questions
class Question {
  final String id;
  final String source;                  // main/mock/review
  final List<String> category;          // 分类数组（支持多个分类）
  final String type;                    // single/multiple/judge/essay
  final String question;                // 题干
  final List<String>? options;          // 选项文本列表
  final String? answer;                 // 答案
  final String? explanation;            // 解析
  final int? difficulty;                // 难度 1-3
  final String? imageUrl;               // Base64图片数据URI
  final String? originalType;           // 原始中文题型
  final String? originalSource;         // 原始中文来源

  const Question({
    required this.id,
    required this.source,
    required this.category,
    required this.type,
    required this.question,
    this.options,
    this.answer,
    this.explanation,
    this.difficulty,
    this.imageUrl,
    this.originalType,
    this.originalSource,
  });

  /// Get primary category (first one)
  String get primaryCategory => category.isNotEmpty ? category.first : '未分类';

  /// Check if this is a single choice question
  bool get isSingleChoice => type == 'single';

  /// Check if this is a multiple choice question
  bool get isMultipleChoice => type == 'multiple';

  /// Check if this is a true/false question
  bool get isJudge => type == 'judge';

  /// Check if this is a fill-in-the-blank question (deprecated, use isEssay)
  bool get isFill => type == 'fill';

  /// Check if this is an essay question
  bool get isEssay => type == 'essay';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Wrong Question Entity
/// Domain layer entity for wrong questions
class WrongQuestion {
  final String id;
  final String questionId;
  final Question question;
  final List<dynamic> wrongAnswers;
  final bool mastered;
  final int reviewCount;
  final DateTime lastReviewAt;

  const WrongQuestion({
    required this.id,
    required this.questionId,
    required this.question,
    required this.wrongAnswers,
    this.mastered = false,
    this.reviewCount = 0,
    required this.lastReviewAt,
  });

  /// Get the number of times this question was answered wrong
  int get wrongAnswerCount => wrongAnswers.length;

  /// Check if this question needs review based on forgetting curve
  bool needsReview() {
    if (mastered) return false;

    final daysSinceReview = DateTime.now().difference(lastReviewAt).inDays;
    switch (reviewCount) {
      case 0:
        return daysSinceReview >= 1;
      case 1:
        return daysSinceReview >= 3;
      case 2:
        return daysSinceReview >= 7;
      case 3:
        return daysSinceReview >= 14;
      default:
        return daysSinceReview >= 30;
    }
  }
}
