import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/question_summary.dart';

part 'question_summary.g.dart';

/// Question Summary Model
/// JSON serializable model for QuestionSummary entity
@JsonSerializable()
class QuestionSummaryModel {
  final String id;
  final String category;
  final String type;
  final int? difficulty;
  final String? title;
  final bool hasAnswered;
  final bool isCorrect;
  final int wrongCount;
  final DateTime? lastAnsweredAt;
  final int? totalAttempts;
  final bool inWrongBook;

  const QuestionSummaryModel({
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

  /// Convert from Question entity to summary
  factory QuestionSummaryModel.fromQuestion(Map<String, dynamic> questionJson) {
    // Extract basic info
    final id = questionJson['id'] as String? ?? '';
    final category = questionJson['category'] as String? ?? 'Other';
    final type = questionJson['type'] as String? ?? 'single';
    final difficulty = questionJson['difficulty'] as int?;
    final questionText = questionJson['question'] as String? ?? '';

    // Create truncated title (first 30 chars)
    final title = questionText.length > 30
        ? '${questionText.substring(0, 30)}...'
        : questionText;

    return QuestionSummaryModel(
      id: id,
      category: category,
      type: type,
      difficulty: difficulty,
      title: title,
      hasAnswered: false,
      isCorrect: false,
      wrongCount: 0,
      inWrongBook: false,
    );
  }

  /// Convert to entity
  QuestionSummary toEntity() {
    return QuestionSummary(
      id: id,
      category: category,
      type: type,
      difficulty: difficulty,
      title: title,
      hasAnswered: hasAnswered,
      isCorrect: isCorrect,
      wrongCount: wrongCount,
      lastAnsweredAt: lastAnsweredAt,
      totalAttempts: totalAttempts,
      inWrongBook: inWrongBook,
    );
  }

  /// Convert from entity
  factory QuestionSummaryModel.fromEntity(QuestionSummary entity) {
    return QuestionSummaryModel(
      id: entity.id,
      category: entity.category,
      type: entity.type,
      difficulty: entity.difficulty,
      title: entity.title,
      hasAnswered: entity.hasAnswered,
      isCorrect: entity.isCorrect,
      wrongCount: entity.wrongCount,
      lastAnsweredAt: entity.lastAnsweredAt,
      totalAttempts: entity.totalAttempts,
      inWrongBook: entity.inWrongBook,
    );
  }

  factory QuestionSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionSummaryModelToJson(this);
}
