import '../entities/question.dart';
import '../repositories/question_repository.dart';

/// Get Wrong Questions Use Case
/// Retrieves wrong questions with filtering options
class GetWrongQuestionsUseCase {
  final QuestionRepository _repository;

  GetWrongQuestionsUseCase(this._repository);

  /// Execute the use case
  Future<GetWrongQuestionsResult> execute(GetWrongQuestionsParams params) async {
    try {
      final allWrongQuestions = await _repository.getWrongQuestions();

      // Filter based on params
      final filtered = <WrongQuestion>[];

      for (final wq in allWrongQuestions) {
        // Filter by mastered status
        if (params.masteredOnly != null) {
          if (params.masteredOnly! && !wq.mastered) continue;
          if (!params.masteredOnly! && wq.mastered) continue;
        }

        // Filter by needs review
        if (params.needsReviewOnly && !wq.needsReview()) continue;

        // Filter by question type (using originalType for Chinese display names)
        // Map Chinese display names to type values
        if (params.category != null) {
          final matchFound = _matchesCategoryOrType(wq.question, params.category!);
          if (!matchFound) continue;
        }

        filtered.add(wq);
      }

      // Sort by last review date (oldest first)
      filtered.sort((a, b) => a.lastReviewAt.compareTo(b.lastReviewAt));

      // Apply offset and limit
      final offset = params.offset > 0 && params.offset < filtered.length
          ? params.offset
          : 0;
      final hasMore = params.limit != null && params.limit! > 0
          ? (offset + params.limit!) < filtered.length
          : false;

      final result = params.limit != null && params.limit! > 0
          ? filtered.skip(offset).take(params.limit!).toList()
          : (offset > 0 ? filtered.skip(offset).toList() : filtered);

      return GetWrongQuestionsResult.success(
        questions: result,
        totalCount: allWrongQuestions.length,
        needsReviewCount: allWrongQuestions.where((wq) => wq.needsReview()).length,
        hasMore: hasMore,
      );
    } catch (e) {
      return GetWrongQuestionsResult.error(e.toString());
    }
  }

  /// Check if question matches the category/type filter
  /// Handles both Chinese display names and English type values
  bool _matchesCategoryOrType(Question question, String filter) {
    // Map short Chinese names to full names and type values
    final Map<String, List<String>> typeMappings = {
      '单选': ['单选题', 'single'],
      '多选': ['多选题', 'multiple'],
      '判断': ['判断题', '对错题', 'judge'],
      '填空': ['填空题', '解答题', 'essay'],
    };

    // Get the possible match values for this filter
    final possibleMatches = typeMappings[filter] ?? [filter];

    // Check originalType first (Chinese display name)
    if (question.originalType != null) {
      for (final match in possibleMatches) {
        if (question.originalType!.contains(match)) {
          return true;
        }
      }
    }

    // Check type value (English)
    if (possibleMatches.contains(question.type)) {
      return true;
    }

    // Also check category list for backward compatibility
    if (question.category.any((cat) => possibleMatches.any((match) => cat.contains(match)))) {
      return true;
    }

    return false;
  }
}

/// Get Wrong Questions Parameters
class GetWrongQuestionsParams {
  final bool? masteredOnly;
  final bool needsReviewOnly;
  final String? category;
  final int? limit;
  final int offset;

  const GetWrongQuestionsParams({
    this.masteredOnly,
    this.needsReviewOnly = false,
    this.category,
    this.limit,
    this.offset = 0,
  });
}

/// Get Wrong Questions Result
class GetWrongQuestionsResult {
  final bool success;
  final List<WrongQuestion>? questions;
  final int? totalCount;
  final int? needsReviewCount;
  final bool hasMore;
  final String? error;

  const GetWrongQuestionsResult._({
    required this.success,
    this.questions,
    this.totalCount,
    this.needsReviewCount,
    this.hasMore = false,
    this.error,
  });

  factory GetWrongQuestionsResult.success({
    required List<WrongQuestion> questions,
    required int totalCount,
    required int needsReviewCount,
    bool hasMore = false,
  }) {
    return GetWrongQuestionsResult._(
      success: true,
      questions: questions,
      totalCount: totalCount,
      needsReviewCount: needsReviewCount,
      hasMore: hasMore,
    );
  }

  factory GetWrongQuestionsResult.error(String error) {
    return GetWrongQuestionsResult._(
      success: false,
      error: error,
    );
  }
}

/// Mark Wrong Question as Mastered Use Case
class MarkAsMasteredUseCase {
  final QuestionRepository _repository;

  MarkAsMasteredUseCase(this._repository);

  /// Execute the use case
  Future<MarkAsMasteredResult> execute(String wrongQuestionId) async {
    try {
      await _repository.markAsMastered(wrongQuestionId);
      return MarkAsMasteredResult.success();
    } catch (e) {
      return MarkAsMasteredResult.error(e.toString());
    }
  }
}

/// Mark as Mastered Result
class MarkAsMasteredResult {
  final bool success;
  final String? error;

  const MarkAsMasteredResult._({required this.success, this.error});

  factory MarkAsMasteredResult.success() {
    return const MarkAsMasteredResult._(success: true);
  }

  factory MarkAsMasteredResult.error(String error) {
    return MarkAsMasteredResult._(success: false, error: error);
  }
}

/// Add Review Attempt Use Case
/// Records a review attempt for a wrong question
class AddReviewAttemptUseCase {
  final QuestionRepository _repository;

  AddReviewAttemptUseCase(this._repository);

  /// Execute the use case
  Future<AddReviewAttemptResult> execute(AddReviewAttemptParams params) async {
    try {
      await _repository.addReviewAttempt(
        wrongQuestionId: params.wrongQuestionId,
        wasCorrect: params.wasCorrect,
      );
      return AddReviewAttemptResult.success();
    } catch (e) {
      return AddReviewAttemptResult.error(e.toString());
    }
  }
}

/// Add Review Attempt Parameters
class AddReviewAttemptParams {
  final String wrongQuestionId;
  final bool wasCorrect;

  const AddReviewAttemptParams({
    required this.wrongQuestionId,
    required this.wasCorrect,
  });
}

/// Add Review Attempt Result
class AddReviewAttemptResult {
  final bool success;
  final String? error;

  const AddReviewAttemptResult._({required this.success, this.error});

  factory AddReviewAttemptResult.success() {
    return const AddReviewAttemptResult._(success: true);
  }

  factory AddReviewAttemptResult.error(String error) {
    return AddReviewAttemptResult._(success: false, error: error);
  }
}

/// Remove Wrong Question Use Case
class RemoveWrongQuestionUseCase {
  final QuestionRepository _repository;

  RemoveWrongQuestionUseCase(this._repository);

  /// Execute the use case
  Future<RemoveWrongQuestionResult> execute(String wrongQuestionId) async {
    try {
      await _repository.removeWrongQuestion(wrongQuestionId);
      return RemoveWrongQuestionResult.success();
    } catch (e) {
      return RemoveWrongQuestionResult.error(e.toString());
    }
  }
}

/// Remove Wrong Question Result
class RemoveWrongQuestionResult {
  final bool success;
  final String? error;

  const RemoveWrongQuestionResult._({required this.success, this.error});

  factory RemoveWrongQuestionResult.success() {
    return const RemoveWrongQuestionResult._(success: true);
  }

  factory RemoveWrongQuestionResult.error(String error) {
    return RemoveWrongQuestionResult._(success: false, error: error);
  }
}
