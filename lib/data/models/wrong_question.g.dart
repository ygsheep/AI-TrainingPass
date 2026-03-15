// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WrongQuestionModel _$WrongQuestionModelFromJson(Map<String, dynamic> json) =>
    WrongQuestionModel(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      question:
          QuestionModel.fromJson(json['question'] as Map<String, dynamic>),
      wrongAnswers: (json['wrongAnswers'] as List<dynamic>)
          .map((e) => UserAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mastered: json['mastered'] as bool? ?? false,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lastReviewAt: DateTime.parse(json['lastReviewAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WrongQuestionModelToJson(WrongQuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionId': instance.questionId,
      'question': instance.question,
      'wrongAnswers': instance.wrongAnswers,
      'mastered': instance.mastered,
      'reviewCount': instance.reviewCount,
      'lastReviewAt': instance.lastReviewAt.toIso8601String(),
      'notes': instance.notes,
    };
