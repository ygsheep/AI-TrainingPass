// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAnswerModel _$UserAnswerModelFromJson(Map<String, dynamic> json) =>
    UserAnswerModel(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeSpent: (json['timeSpent'] as num).toInt(),
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );

Map<String, dynamic> _$UserAnswerModelToJson(UserAnswerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'userAnswer': instance.userAnswer,
      'isCorrect': instance.isCorrect,
      'timeSpent': instance.timeSpent,
      'answeredAt': instance.answeredAt.toIso8601String(),
    };
