// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamConfigModel _$ExamConfigModelFromJson(Map<String, dynamic> json) =>
    ExamConfigModel(
      name: json['name'] as String,
      questionCount: (json['questionCount'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      passScore: (json['passScore'] as num).toInt(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      randomOrder: json['randomOrder'] as bool? ?? true,
      antiCheat: json['antiCheat'] as bool? ?? true,
    );

Map<String, dynamic> _$ExamConfigModelToJson(ExamConfigModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'questionCount': instance.questionCount,
      'duration': instance.duration,
      'passScore': instance.passScore,
      'categories': instance.categories,
      'randomOrder': instance.randomOrder,
      'antiCheat': instance.antiCheat,
    };

ExamRecordModel _$ExamRecordModelFromJson(Map<String, dynamic> json) =>
    ExamRecordModel(
      id: json['id'] as String,
      config: ExamConfigModel.fromJson(json['config'] as Map<String, dynamic>),
      questionIds: (json['questionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => UserAnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      duration: (json['duration'] as num?)?.toInt(),
      score: (json['score'] as num).toInt(),
      passed: json['passed'] as bool,
      correctCount: (json['correctCount'] as num).toInt(),
      totalCount: (json['totalCount'] as num).toInt(),
    );

Map<String, dynamic> _$ExamRecordModelToJson(ExamRecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'config': instance.config.toJson(),
      'questionIds': instance.questionIds,
      'answers': instance.answers.map((e) => e.toJson()).toList(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'duration': instance.duration,
      'score': instance.score,
      'passed': instance.passed,
      'correctCount': instance.correctCount,
      'totalCount': instance.totalCount,
    };
