import 'package:json_annotation/json_annotation.dart';
import 'user_answer.dart';

part 'exam_record.g.dart';

/// Exam Configuration Model
/// Defines settings for an exam
@JsonSerializable()
class ExamConfigModel {
  final String name;                    // 考试名称
  final int questionCount;              // 题目数量
  final int duration;                   // 时长(分钟)
  final int passScore;                  // 及格分
  final List<String>? categories;       // 选择的分类
  final bool randomOrder;               // 是否随机排序
  final bool antiCheat;                 // 是否开启防作弊

  const ExamConfigModel({
    required this.name,
    required this.questionCount,
    required this.duration,
    required this.passScore,
    this.categories,
    this.randomOrder = true,
    this.antiCheat = true,
  });

  factory ExamConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ExamConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamConfigModelToJson(this);

  ExamConfigModel copyWith({
    String? name,
    int? questionCount,
    int? duration,
    int? passScore,
    List<String>? categories,
    bool? randomOrder,
    bool? antiCheat,
  }) {
    return ExamConfigModel(
      name: name ?? this.name,
      questionCount: questionCount ?? this.questionCount,
      duration: duration ?? this.duration,
      passScore: passScore ?? this.passScore,
      categories: categories ?? this.categories,
      randomOrder: randomOrder ?? this.randomOrder,
      antiCheat: antiCheat ?? this.antiCheat,
    );
  }
}

/// Exam Record Model
/// Records a completed exam attempt
@JsonSerializable(explicitToJson: true)
class ExamRecordModel {
  final String id;
  final ExamConfigModel config;
  final List<String> questionIds;       // 题目ID列表
  final List<UserAnswerModel> answers;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;                  // 实际用时(秒)
  final int score;                      // 得分
  final bool passed;                    // 是否及格
  final int correctCount;               // 正确数
  final int totalCount;                 // 总题数

  const ExamRecordModel({
    required this.id,
    required this.config,
    required this.questionIds,
    required this.answers,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.score,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
  });

  factory ExamRecordModel.fromJson(Map<String, dynamic> json) =>
      _$ExamRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamRecordModelToJson(this);

  /// Calculate accuracy percentage
  double get accuracy => totalCount > 0
      ? (correctCount / totalCount) * 100
      : 0.0;

  /// Get unanswered count
  int get unansweredCount => totalCount - answers.length;

  /// Check if exam is completed
  bool get isCompleted => endTime != null;

  /// Format duration as readable string
  String get formattedDuration {
    if (duration == null) return '--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes分$seconds秒';
  }

  /// Format date as readable string
  String get formattedDate {
    return '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')} '
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  ExamRecordModel copyWith({
    String? id,
    ExamConfigModel? config,
    List<String>? questionIds,
    List<UserAnswerModel>? answers,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    int? score,
    bool? passed,
    int? correctCount,
    int? totalCount,
  }) {
    return ExamRecordModel(
      id: id ?? this.id,
      config: config ?? this.config,
      questionIds: questionIds ?? this.questionIds,
      answers: answers ?? this.answers,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
