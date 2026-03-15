import 'package:json_annotation/json_annotation.dart';

part 'user_answer.g.dart';

/// User Answer Model
/// Records a user's answer to a question
@JsonSerializable()
class UserAnswerModel {
  final String id;
  final String questionId;
  final String userAnswer;              // 用户答案
  final bool isCorrect;
  final int timeSpent;                  // 耗时(秒)
  final DateTime answeredAt;

  const UserAnswerModel({
    required this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory UserAnswerModel.fromJson(Map<String, dynamic> json) =>
      _$UserAnswerModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserAnswerModelToJson(this);

  /// Format time spent as readable string
  String get formattedTime {
    if (timeSpent < 60) {
      return '$timeSpent秒';
    } else if (timeSpent < 3600) {
      final minutes = timeSpent ~/ 60;
      final seconds = timeSpent % 60;
      return '$minutes分$seconds秒';
    } else {
      final hours = timeSpent ~/ 3600;
      final minutes = (timeSpent % 3600) ~/ 60;
      return '$hours小时$minutes分';
    }
  }

  UserAnswerModel copyWith({
    String? id,
    String? questionId,
    String? userAnswer,
    bool? isCorrect,
    int? timeSpent,
    DateTime? answeredAt,
  }) {
    return UserAnswerModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      timeSpent: timeSpent ?? this.timeSpent,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
