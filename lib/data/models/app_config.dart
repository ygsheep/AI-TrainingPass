import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

/// App Configuration Model
/// Main app configuration that can be customized per deployment
@JsonSerializable()
class AppConfigModel {
  final String appName;                 // 应用名称
  final String appVersion;              // 应用版本
  final String questionBankVersion;     // 题库版本
  final String? updateUrl;              // 题库更新URL
  final DateTime? lastUpdateCheck;      // 上次更新检查时间
  final int defaultExamDuration;        // 默认考试时长(分钟)
  final int defaultPassScore;           // 默认及格分
  final int examQuestionCount;          // 默认考试题目数量
  final bool enableOnlineUpdate;        // 是否启用在线更新

  const AppConfigModel({
    required this.appName,
    required this.appVersion,
    required this.questionBankVersion,
    this.updateUrl,
    this.lastUpdateCheck,
    this.defaultExamDuration = 60,
    this.defaultPassScore = 60,
    this.examQuestionCount = 100,
    this.enableOnlineUpdate = true,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigModelToJson(this);

  AppConfigModel copyWith({
    String? appName,
    String? appVersion,
    String? questionBankVersion,
    String? updateUrl,
    DateTime? lastUpdateCheck,
    int? defaultExamDuration,
    int? defaultPassScore,
    int? examQuestionCount,
    bool? enableOnlineUpdate,
  }) {
    return AppConfigModel(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      questionBankVersion: questionBankVersion ?? this.questionBankVersion,
      updateUrl: updateUrl ?? this.updateUrl,
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      defaultExamDuration: defaultExamDuration ?? this.defaultExamDuration,
      defaultPassScore: defaultPassScore ?? this.defaultPassScore,
      examQuestionCount: examQuestionCount ?? this.examQuestionCount,
      enableOnlineUpdate: enableOnlineUpdate ?? this.enableOnlineUpdate,
    );
  }

  /// Create default config
  static AppConfigModel createDefault() {
    return const AppConfigModel(
      appName: 'TrainingPass',
      appVersion: '1.0.0',
      questionBankVersion: '1.0.0',
      defaultExamDuration: 60,
      defaultPassScore: 60,
      examQuestionCount: 100,
      enableOnlineUpdate: false,
    );
  }
}

/// User Settings Model
/// User-specific preferences
@JsonSerializable()
class UserSettingsModel {
  final bool autoSubmit;                // 自动提交
  final String themeMode;               // 主题模式 light/dark/system
  final bool showExplanations;          // 显示解析
  final bool showTimer;                 // 显示计时器
  final int textSize;                   // 字体大小 (小/中/大)

  const UserSettingsModel({
    this.autoSubmit = true,
    this.themeMode = 'system',
    this.showExplanations = true,
    this.showTimer = true,
    this.textSize = 1,  // 0: 小, 1: 中, 2: 大
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsModelToJson(this);

  UserSettingsModel copyWith({
    bool? autoSubmit,
    String? themeMode,
    bool? showExplanations,
    bool? showTimer,
    int? textSize,
  }) {
    return UserSettingsModel(
      autoSubmit: autoSubmit ?? this.autoSubmit,
      themeMode: themeMode ?? this.themeMode,
      showExplanations: showExplanations ?? this.showExplanations,
      showTimer: showTimer ?? this.showTimer,
      textSize: textSize ?? this.textSize,
    );
  }

  /// Create default settings
  static UserSettingsModel createDefault() {
    return const UserSettingsModel();
  }
}

/// Study Progress Model
/// Tracks user's overall learning progress
@JsonSerializable()
class StudyProgressModel {
  final int totalAnswered;              // 总答题数
  final int correctCount;               // 正确数
  final int wrongCount;                 // 错误数
  final int studyDays;                  // 学习天数
  final DateTime lastStudyDate;         // 最后学习日期
  final Map<String, CategoryProgress> categoryProgress;

  const StudyProgressModel({
    required this.totalAnswered,
    required this.correctCount,
    required this.wrongCount,
    required this.studyDays,
    required this.lastStudyDate,
    required this.categoryProgress,
  });

  factory StudyProgressModel.fromJson(Map<String, dynamic> json) =>
      _$StudyProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudyProgressModelToJson(this);

  /// Get accuracy percentage
  double get accuracy => totalAnswered > 0
      ? (correctCount / totalAnswered) * 100
      : 0.0;

  StudyProgressModel copyWith({
    int? totalAnswered,
    int? correctCount,
    int? wrongCount,
    int? studyDays,
    DateTime? lastStudyDate,
    Map<String, CategoryProgress>? categoryProgress,
  }) {
    return StudyProgressModel(
      totalAnswered: totalAnswered ?? this.totalAnswered,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      studyDays: studyDays ?? this.studyDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      categoryProgress: categoryProgress ?? this.categoryProgress,
    );
  }

  /// Create empty progress
  static StudyProgressModel createEmpty() {
    return StudyProgressModel(
      totalAnswered: 0,
      correctCount: 0,
      wrongCount: 0,
      studyDays: 0,
      lastStudyDate: DateTime.now(),
      categoryProgress: {},
    );
  }
}

/// Category Progress
/// Progress tracking for a specific question category
@JsonSerializable()
class CategoryProgress {
  final String categoryId;
  final String categoryName;
  final int total;                     // 该分类总题数
  final int answered;                  // 已答题数
  final int correct;                   // 正确数

  const CategoryProgress({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.answered,
    required this.correct,
  });

  factory CategoryProgress.fromJson(Map<String, dynamic> json) =>
      _$CategoryProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryProgressToJson(this);

  /// Get accuracy percentage for this category
  double get accuracy => answered > 0
      ? (correct / answered) * 100
      : 0.0;

  /// Get completion percentage
  double get completion => total > 0
      ? (answered / total) * 100
      : 0.0;

  CategoryProgress copyWith({
    String? categoryId,
    String? categoryName,
    int? total,
    int? answered,
    int? correct,
  }) {
    return CategoryProgress(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      total: total ?? this.total,
      answered: answered ?? this.answered,
      correct: correct ?? this.correct,
    );
  }
}
