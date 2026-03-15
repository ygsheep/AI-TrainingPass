// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeProgressModel _$PracticeProgressModelFromJson(
        Map<String, dynamic> json) =>
    PracticeProgressModel(
      category: json['category'] as String,
      lastIndex: (json['lastIndex'] as num).toInt(),
      lastPracticeTime: DateTime.parse(json['lastPracticeTime'] as String),
      filterData: json['filterData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PracticeProgressModelToJson(
        PracticeProgressModel instance) =>
    <String, dynamic>{
      'category': instance.category,
      'lastIndex': instance.lastIndex,
      'lastPracticeTime': instance.lastPracticeTime.toIso8601String(),
      'filterData': instance.filterData,
    };
