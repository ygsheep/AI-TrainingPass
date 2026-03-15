import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'question.dart';
import 'user_answer.dart';

part 'wrong_question.g.dart';

/// Wrong Question Model
/// Represents a question the user answered incorrectly
@JsonSerializable()
class WrongQuestionModel {
  final String id;
  final String questionId;
  final QuestionModel question;
  final List<UserAnswerModel> wrongAnswers;
  final bool mastered;                  // 是否已掌握
  final int reviewCount;                // 复习次数
  final DateTime lastReviewAt;
  final String? notes;                  // 用户笔记

  const WrongQuestionModel({
    required this.id,
    required this.questionId,
    required this.question,
    required this.wrongAnswers,
    this.mastered = false,
    this.reviewCount = 0,
    required this.lastReviewAt,
    this.notes,
  });

  factory WrongQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$WrongQuestionModelFromJson(json);

  /// Custom toJson that properly serializes nested QuestionModel
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'question': question.toJson(),  // ← This is the key fix!
      'wrongAnswers': wrongAnswers.map((e) => e.toJson()).toList(),
      'mastered': mastered,
      'reviewCount': reviewCount,
      'lastReviewAt': lastReviewAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Get the number of times this question was answered wrong
  int get wrongAnswerCount => wrongAnswers.length;

  /// Check if this question needs review based on forgetting curve
  bool needsReview() {
    if (mastered) return false;

    final daysSinceReview = DateTime.now().difference(lastReviewAt).inDays;

    // Review schedule based on count
    switch (reviewCount) {
      case 0:
        return daysSinceReview >= 1;      // Review after 1 day
      case 1:
        return daysSinceReview >= 3;      // Review after 3 days
      case 2:
        return daysSinceReview >= 7;      // Review after 1 week
      case 3:
        return daysSinceReview >= 14;     // Review after 2 weeks
      default:
        return daysSinceReview >= 30;     // Review after 1 month
    }
  }

  /// Mark as mastered
  WrongQuestionModel markAsMastered() {
    return copyWith(mastered: true);
  }

  /// Add a review attempt
  WrongQuestionModel addReview({required bool wasCorrect}) {
    return copyWith(
      reviewCount: reviewCount + 1,
      lastReviewAt: DateTime.now(),
      mastered: wasCorrect && reviewCount >= 2,
    );
  }

  WrongQuestionModel copyWith({
    String? id,
    String? questionId,
    QuestionModel? question,
    List<UserAnswerModel>? wrongAnswers,
    bool? mastered,
    int? reviewCount,
    DateTime? lastReviewAt,
    String? notes,
  }) {
    return WrongQuestionModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      question: question ?? this.question,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      mastered: mastered ?? this.mastered,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      notes: notes ?? this.notes,
    );
  }
}
