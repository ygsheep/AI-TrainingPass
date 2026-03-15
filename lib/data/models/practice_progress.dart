import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/question_filter.dart';

part 'practice_progress.g.dart';

/// Extension on QuestionFilter for serialization
extension QuestionFilterExtension on QuestionFilter {
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'type': type,
      'difficulty': difficulty,
      'answerStatus': answerStatus?.name,
      'inWrongBook': inWrongBook,
      'searchKeyword': searchKeyword,
    };
  }

  static QuestionFilter fromMap(Map<String, dynamic> map) {
    return QuestionFilter(
      category: map['category'] as String?,
      type: map['type'] as String?,
      difficulty: map['difficulty'] as int?,
      answerStatus: map['answerStatus'] != null
          ? AnswerStatus.values.firstWhere(
              (e) => e.name == map['answerStatus'],
              orElse: () => AnswerStatus.all,
            )
          : null,
      inWrongBook: map['inWrongBook'] as bool?,
      searchKeyword: map['searchKeyword'] as String?,
    );
  }
}

/// Practice Progress Model
/// Tracks user's progress in practice mode for resuming later
@JsonSerializable()
class PracticeProgressModel {
  /// Category being practiced (e.g., 'foundation', 'operate', 'all')
  final String category;

  /// Last question index the user was on
  final int lastIndex;

  /// When the practice session was last active
  final DateTime lastPracticeTime;

  /// Filter that was applied during practice (optional)
  final Map<String, dynamic>? filterData;

  const PracticeProgressModel({
    required this.category,
    required this.lastIndex,
    required this.lastPracticeTime,
    this.filterData,
  });

  factory PracticeProgressModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeProgressModelToJson(this);

  /// Convert to QuestionFilter (if filter data exists)
  QuestionFilter? toFilter() {
    if (filterData == null) return null;
    return QuestionFilterExtension.fromMap(filterData!);
  }

  /// Create from filter
  static PracticeProgressModel withFilter({
    required String category,
    required int lastIndex,
    required DateTime lastPracticeTime,
    QuestionFilter? filter,
  }) {
    return PracticeProgressModel(
      category: category,
      lastIndex: lastIndex,
      lastPracticeTime: lastPracticeTime,
      filterData: filter?.toMap(),
    );
  }

  PracticeProgressModel copyWith({
    String? category,
    int? lastIndex,
    DateTime? lastPracticeTime,
    Map<String, dynamic>? filterData,
  }) {
    return PracticeProgressModel(
      category: category ?? this.category,
      lastIndex: lastIndex ?? this.lastIndex,
      lastPracticeTime: lastPracticeTime ?? this.lastPracticeTime,
      filterData: filterData ?? this.filterData,
    );
  }
}
