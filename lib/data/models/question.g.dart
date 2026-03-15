// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionOption _$QuestionOptionFromJson(Map<String, dynamic> json) =>
    QuestionOption(
      key: json['key'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$QuestionOptionToJson(QuestionOption instance) =>
    <String, dynamic>{
      'key': instance.key,
      'text': instance.text,
    };

QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    QuestionModel(
      id: json['id'] as String,
      source: json['source'] as String? ?? 'main',
      category:
          (json['category'] as List<dynamic>).map((e) => e as String).toList(),
      type: json['type'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      originalType: json['originalType'] as String?,
      originalSource: json['originalSource'] as String?,
    );

Map<String, dynamic> _$QuestionModelToJson(QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'category': instance.category,
      'type': instance.type,
      'question': instance.question,
      'options': instance.options?.map((e) => e.toJson()).toList(),
      'answer': instance.answer,
      'explanation': instance.explanation,
      'difficulty': instance.difficulty,
      'imageUrl': instance.imageUrl,
      'originalType': instance.originalType,
      'originalSource': instance.originalSource,
    };
