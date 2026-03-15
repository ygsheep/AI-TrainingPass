import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/wrong_question_actions.dart';
import '../../core/extensions/iterable_extensions.dart';
import '../../core/utils/app_logger.dart';
import 'question_provider.dart';

part 'wrong_book_provider.g.dart';

/// Default page size for pagination
const int _defaultPageSize = 30;

/// Wrong Questions State
class WrongBookState {
  final List<WrongQuestion> questions;
  final int totalCount;
  final int needsReviewCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  // Store current filter params for refresh
  final bool? _masteredOnly;
  final bool _needsReviewOnly;
  final String? _category;
  final int _currentPage;

  const WrongBookState({
    this.questions = const [],
    this.totalCount = 0,
    this.needsReviewCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    bool? masteredOnly,
    bool needsReviewOnly = false,
    String? category,
    int currentPage = 0,
  })  : _masteredOnly = masteredOnly,
        _needsReviewOnly = needsReviewOnly,
        _category = category,
        _currentPage = currentPage;

  WrongBookState copyWith({
    List<WrongQuestion>? questions,
    int? totalCount,
    int? needsReviewCount,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? masteredOnly,
    bool? needsReviewOnly,
    String? category,
    int? currentPage,
  }) {
    return WrongBookState(
      questions: questions ?? this.questions,
      totalCount: totalCount ?? this.totalCount,
      needsReviewCount: needsReviewCount ?? this.needsReviewCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      masteredOnly: masteredOnly ?? _masteredOnly,
      needsReviewOnly: needsReviewOnly ?? _needsReviewOnly,
      category: category ?? _category,
      currentPage: currentPage ?? _currentPage,
    );
  }

  /// Get current filter params for internal use
  bool? get masteredOnly => _masteredOnly;
  bool get needsReviewOnly => _needsReviewOnly;
  String? get category => _category;
  int get currentPage => _currentPage;
}

/// Wrong Book State Provider
@riverpod
class WrongBook extends _$WrongBook {
  @override
  WrongBookState build() {
    // Don't call loadWrongQuestions here to avoid circular dependency
    // State will be loaded when first accessed
    return const WrongBookState(isLoading: true);
  }

  /// Load wrong questions with optional filters
  /// This is the initial load, resets pagination
  Future<void> loadWrongQuestions({
    bool? masteredOnly,
    bool needsReviewOnly = false,
    String? category,
    int? limit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(questionRepositoryProvider);
    final useCase = GetWrongQuestionsUseCase(repository);

    final result = await useCase.execute(GetWrongQuestionsParams(
      masteredOnly: masteredOnly,
      needsReviewOnly: needsReviewOnly,
      category: category,
      limit: limit,
      offset: 0,
    ));

    if (!result.success) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
        masteredOnly: masteredOnly,
        needsReviewOnly: needsReviewOnly,
        category: category,
      );
      return;
    }

    state = state.copyWith(
      questions: result.questions ?? [],
      totalCount: result.totalCount ?? 0,
      needsReviewCount: result.needsReviewCount ?? 0,
      isLoading: false,
      hasMore: result.hasMore,
      masteredOnly: masteredOnly,
      needsReviewOnly: needsReviewOnly,
      category: category,
      currentPage: 1,
    );
  }

  /// Load more wrong questions (pagination)
  Future<void> loadMore() async {
    // Prevent loading if already loading or no more data
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    final repository = ref.read(questionRepositoryProvider);
    final useCase = GetWrongQuestionsUseCase(repository);

    final offset = state.questions.length;

    final result = await useCase.execute(GetWrongQuestionsParams(
      masteredOnly: state.masteredOnly,
      needsReviewOnly: state.needsReviewOnly,
      category: state.category,
      limit: _defaultPageSize,
      offset: offset,
    ));

    if (!result.success) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    // Append new questions to existing list
    final newQuestions = <WrongQuestion>[
      ...state.questions,
      ...(result.questions ?? <WrongQuestion>[]),
    ];

    state = state.copyWith(
      questions: newQuestions,
      isLoadingMore: false,
      hasMore: result.hasMore,
      currentPage: state.currentPage + 1,
    );
  }

  /// Load questions that need review
  Future<void> loadNeedsReview({int? limit}) async {
    await loadWrongQuestions(needsReviewOnly: true, limit: limit);
  }

  /// Load mastered questions
  Future<void> loadMastered({int? limit}) async {
    await loadWrongQuestions(masteredOnly: true, limit: limit);
  }

  /// Load questions by category
  Future<void> loadByCategory(String category, {int? limit}) async {
    await loadWrongQuestions(category: category, limit: limit);
  }

  /// Mark question as mastered
  /// Optimistically removes the item from local state without full refresh
  Future<bool> markAsMastered(String wrongQuestionId) async {
    AppLogger.debug('🎯 WrongBookProvider.markAsMastered: id=$wrongQuestionId');
    final repository = ref.read(questionRepositoryProvider);
    final useCase = MarkAsMasteredUseCase(repository);

    // Save original state for rollback
    final originalQuestions = state.questions;
    final originalTotalCount = state.totalCount;

    // Optimistically remove from local state
    final updatedQuestions = state.questions.where((q) => q.id != wrongQuestionId).toList();

    // Update state immediately for better UX
    state = state.copyWith(
      questions: updatedQuestions,
      totalCount: state.totalCount - 1,
    );

    final result = await useCase.execute(wrongQuestionId);
    AppLogger.debug('🎯 MarkAsMasteredUseCase result: success=${result.success}, error=${result.error}');

    if (!result.success) {
      // Revert on failure
      AppLogger.debug('🎯 Mark failed, reverting state...');
      state = state.copyWith(
        questions: originalQuestions,
        totalCount: originalTotalCount,
      );
    }

    return result.success;
  }

  /// Add review attempt
  Future<bool> addReviewAttempt({
    required String wrongQuestionId,
    required bool wasCorrect,
  }) async {
    final repository = ref.read(questionRepositoryProvider);
    final useCase = AddReviewAttemptUseCase(repository);

    final result = await useCase.execute(AddReviewAttemptParams(
      wrongQuestionId: wrongQuestionId,
      wasCorrect: wasCorrect,
    ));

    if (result.success) {
      // Refresh the list
      await loadWrongQuestions();
    }

    return result.success;
  }

  /// Remove question from wrong book
  Future<bool> removeQuestion(String wrongQuestionId) async {
    final repository = ref.read(questionRepositoryProvider);
    final useCase = RemoveWrongQuestionUseCase(repository);

    final result = await useCase.execute(wrongQuestionId);

    if (result.success) {
      // Refresh the list
      await loadWrongQuestions();
    }

    return result.success;
  }

  /// Refresh the list
  Future<void> refresh() async {
    await loadWrongQuestions();
  }
}

/// Single Wrong Question Provider
@riverpod
Future<WrongQuestion?> wrongQuestion(Ref ref, String id) async {
  final repository = ref.read(questionRepositoryProvider);
  final allQuestions = await repository.getWrongQuestions();

  return allQuestions.firstWhereOrNull((wq) => wq.id == id);
}
