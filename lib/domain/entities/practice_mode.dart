import 'package:json_annotation/json_annotation.dart';

/// Practice Mode Enum
/// Defines different practice modes for the quiz application
enum PracticeMode {
  /// Sequential practice - go through questions in order
  @JsonValue('sequential')
  sequential,

  /// Random practice - shuffle questions
  @JsonValue('random')
  random,

  /// Focus on weak categories - practice areas with low accuracy
  @JsonValue('weakCategories')
  weakCategories,

  /// Practice wrong book - redo questions from wrong book
  @JsonValue('wrongBook')
  wrongBook,
}

/// Practice Mode Extensions
extension PracticeModeExtension on PracticeMode {
  /// Get display name for the mode
  String get displayName {
    switch (this) {
      case PracticeMode.sequential:
        return '系统刷题';
      case PracticeMode.random:
        return '随机练习';
      case PracticeMode.weakCategories:
        return '针对弱项';
      case PracticeMode.wrongBook:
        return '错题重练';
    }
  }

  /// Get description for the mode
  String get description {
    switch (this) {
      case PracticeMode.sequential:
        return '按顺序练习所有题目';
      case PracticeMode.random:
        return '随机抽取题目进行练习';
      case PracticeMode.weakCategories:
        return '重点练习错误率高的分类';
      case PracticeMode.wrongBook:
        return '专门练习错题本中的题目';
    }
  }

  /// Get icon for the mode
  String get iconName {
    switch (this) {
      case PracticeMode.sequential:
        return 'format_list_numbered';
      case PracticeMode.random:
        return 'shuffle';
      case PracticeMode.weakCategories:
        return 'trending_down';
      case PracticeMode.wrongBook:
        return 'bookmark';
    }
  }
}
