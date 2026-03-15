// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionSummaryModel _$QuestionSummaryModelFromJson(
        Map<String, dynamic> json) =>
    QuestionSummaryModel(
      id: json['id'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      difficulty: (json['difficulty'] as num?)?.toInt(),
      title: json['title'] as String?,
      hasAnswered: json['hasAnswered'] as bool? ?? false,
      isCorrect: json['isCorrect'] as bool? ?? false,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      lastAnsweredAt: json['lastAnsweredAt'] == null
          ? null
          : DateTime.parse(json['lastAnsweredAt'] as String),
      totalAttempts: (json['totalAttempts'] as num?)?.toInt(),
      inWrongBook: json['inWrongBook'] as bool? ?? false,
    );

Map<String, dynamic> _$QuestionSummaryModelToJson(
        QuestionSummaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'type': instance.type,
      'difficulty': instance.difficulty,
      'title': instance.title,
      'hasAnswered': instance.hasAnswered,
      'isCorrect': instance.isCorrect,
      'wrongCount': instance.wrongCount,
      'lastAnsweredAt': instance.lastAnsweredAt?.toIso8601String(),
      'totalAttempts': instance.totalAttempts,
      'inWrongBook': instance.inWrongBook,
    };
