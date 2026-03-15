// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigModel _$AppConfigModelFromJson(Map<String, dynamic> json) =>
    AppConfigModel(
      appName: json['appName'] as String,
      appVersion: json['appVersion'] as String,
      questionBankVersion: json['questionBankVersion'] as String,
      updateUrl: json['updateUrl'] as String?,
      lastUpdateCheck: json['lastUpdateCheck'] == null
          ? null
          : DateTime.parse(json['lastUpdateCheck'] as String),
      defaultExamDuration: (json['defaultExamDuration'] as num?)?.toInt() ?? 60,
      defaultPassScore: (json['defaultPassScore'] as num?)?.toInt() ?? 60,
      examQuestionCount: (json['examQuestionCount'] as num?)?.toInt() ?? 100,
      enableOnlineUpdate: json['enableOnlineUpdate'] as bool? ?? true,
    );

Map<String, dynamic> _$AppConfigModelToJson(AppConfigModel instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'appVersion': instance.appVersion,
      'questionBankVersion': instance.questionBankVersion,
      'updateUrl': instance.updateUrl,
      'lastUpdateCheck': instance.lastUpdateCheck?.toIso8601String(),
      'defaultExamDuration': instance.defaultExamDuration,
      'defaultPassScore': instance.defaultPassScore,
      'examQuestionCount': instance.examQuestionCount,
      'enableOnlineUpdate': instance.enableOnlineUpdate,
    };

UserSettingsModel _$UserSettingsModelFromJson(Map<String, dynamic> json) =>
    UserSettingsModel(
      autoSubmit: json['autoSubmit'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'system',
      showExplanations: json['showExplanations'] as bool? ?? true,
      showTimer: json['showTimer'] as bool? ?? true,
      textSize: (json['textSize'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$UserSettingsModelToJson(UserSettingsModel instance) =>
    <String, dynamic>{
      'autoSubmit': instance.autoSubmit,
      'themeMode': instance.themeMode,
      'showExplanations': instance.showExplanations,
      'showTimer': instance.showTimer,
      'textSize': instance.textSize,
    };

StudyProgressModel _$StudyProgressModelFromJson(Map<String, dynamic> json) =>
    StudyProgressModel(
      totalAnswered: (json['totalAnswered'] as num).toInt(),
      correctCount: (json['correctCount'] as num).toInt(),
      wrongCount: (json['wrongCount'] as num).toInt(),
      studyDays: (json['studyDays'] as num).toInt(),
      lastStudyDate: DateTime.parse(json['lastStudyDate'] as String),
      categoryProgress: (json['categoryProgress'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, CategoryProgress.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$StudyProgressModelToJson(StudyProgressModel instance) =>
    <String, dynamic>{
      'totalAnswered': instance.totalAnswered,
      'correctCount': instance.correctCount,
      'wrongCount': instance.wrongCount,
      'studyDays': instance.studyDays,
      'lastStudyDate': instance.lastStudyDate.toIso8601String(),
      'categoryProgress': instance.categoryProgress,
    };

CategoryProgress _$CategoryProgressFromJson(Map<String, dynamic> json) =>
    CategoryProgress(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      total: (json['total'] as num).toInt(),
      answered: (json['answered'] as num).toInt(),
      correct: (json['correct'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryProgressToJson(CategoryProgress instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'total': instance.total,
      'answered': instance.answered,
      'correct': instance.correct,
    };
