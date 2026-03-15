import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/question_summary.dart';
import '../../domain/entities/question_filter.dart';
import '../../data/models/question.dart';
import '../../data/models/wrong_question.dart';
import '../../data/datasources/local/question_local_datasource.dart';
import '../../data/datasources/local/hive_service.dart';
import '../providers/question_provider.dart';
import '../providers/wrong_book_provider.dart';
import '../providers/config_provider.dart';

part 'practice_swipe_provider.g.dart';

/// Question Status Enum
enum QuestionStatus {
  /// Question not yet answered
  unanswered,

  /// Question answered correctly
  correct,

  /// Question answered incorrectly
  wrong,
}

/// Practice Swipe State
/// Manages state for card-based practice mode
@sealed
class PracticeSwipeState {
  /// List of question summaries (lightweight)
  final List<QuestionSummary> summaries;

  /// Cache of full question details (lazy loaded)
  final Map<String, Question> questionCache;

  /// Current question index
  final int currentIndex;

  /// Total number of questions (for progress display)
  final int totalCount;

  /// Indices of answered questions
  final Set<int> answeredIndices;

  /// User answers by index
  final Map<int, String> userAnswers;

  /// Currently selected answer (not yet submitted)
  final String? selectedAnswer;

  /// Whether to show result for current question
  final bool showResult;

  /// Whether there are more questions to load
  final bool hasMore;

  /// Whether currently loading initial data
  final bool isLoading;

  /// Whether loading more questions
  final bool isLoadingMore;

  /// Error message if any
  final String? error;

  /// Whether current question is bookmarked
  final bool isBookmarked;

  /// Current filter applied
  final QuestionFilter? currentFilter;

  /// Current category
  final String? category;

  const PracticeSwipeState({
    this.summaries = const [],
    this.questionCache = const {},
    this.currentIndex = 0,
    this.totalCount = 0,
    this.answeredIndices = const {},
    this.userAnswers = const {},
    this.selectedAnswer,
    this.showResult = false,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.isBookmarked = false,
    this.currentFilter,
    this.category,
  });

  /// Get number of answered questions
  int get answeredCount => answeredIndices.length;

  /// Get progress ratio (0.0 to 1.0)
  double get progress => totalCount > 0 ? (currentIndex + 1) / totalCount : 0;

  /// Get current summary
  QuestionSummary? get currentSummary {
    if (currentIndex >= 0 && currentIndex < summaries.length) {
      return summaries[currentIndex];
    }
    return null;
  }

  /// Get current question (from cache or null)
  Question? get currentQuestion {
    final summary = currentSummary;
    if (summary == null) return null;
    return questionCache[summary.id];
  }

  /// Check if current question has been answered
  bool get isCurrentAnswered => answeredIndices.contains(currentIndex);

  PracticeSwipeState copyWith({
    List<QuestionSummary>? summaries,
    Map<String, Question>? questionCache,
    int? currentIndex,
    int? totalCount,
    Set<int>? answeredIndices,
    Map<int, String>? userAnswers,
    String? selectedAnswer,
    bool? showResult,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? isBookmarked,
    QuestionFilter? currentFilter,
    String? category,
    // Use nullable to allow setting to null
    Object? selectedAnswerNull,
    Object? errorNull,
    Object? currentFilterNull,
    Object? categoryNull,
  }) {
    return PracticeSwipeState(
      summaries: summaries ?? this.summaries,
      questionCache: questionCache ?? this.questionCache,
      currentIndex: currentIndex ?? this.currentIndex,
      totalCount: totalCount ?? this.totalCount,
      answeredIndices: answeredIndices ?? this.answeredIndices,
      userAnswers: userAnswers ?? this.userAnswers,
      selectedAnswer: selectedAnswerNull == null
          ? (selectedAnswer ?? this.selectedAnswer)
          : null as String?,
      showResult: showResult ?? this.showResult,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: errorNull == null ? (error ?? this.error) : null as String?,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      currentFilter: currentFilterNull == null
          ? (currentFilter ?? this.currentFilter)
          : null as QuestionFilter?,
      category: categoryNull == null ? (category ?? this.category) : null as String?,
    );
  }
}

/// Practice Swipe Provider
/// Manages card-based practice mode with pagination and lazy loading
@riverpod
class PracticeSwipe extends _$PracticeSwipe {
  // Batch size for loading questions
  static const int _batchSize = 20;

  // Current offset for pagination
  int _currentOffset = 0;

  // Preload radius (number of questions to preload ahead/behind)
  static const int _preloadRadius = 3;

  @override
  PracticeSwipeState build() {
    return const PracticeSwipeState();
  }

  /// Load initial batch of questions
  Future<void> loadInitialBatch({
    required String? category,
    QuestionFilter? filter,
    int pageSize = _batchSize,
  }) async {
    // Reset state for fresh load (also clears questionCache)
    _currentOffset = 0;
    state = const PracticeSwipeState();

    // Merge category into filter - keep English type as-is
    final mergedFilter = filter != null
        ? QuestionFilter(
            category: category,
            type: filter.type,  // Keep English type
            difficulty: filter.difficulty,
            answerStatus: filter.answerStatus,
            inWrongBook: filter.inWrongBook,
            searchKeyword: filter.searchKeyword,
          )
        : (category != null ? QuestionFilter(category: category) : null);

    state = state.copyWith(
      isLoading: true,
      error: null,
      category: category,
      currentFilter: mergedFilter,
    );

    try {
      final repository = ref.read(questionRepositoryProvider);

      // Get total count
      final totalCount = await repository.getQuestionCount(filter: mergedFilter);

      // Load first batch of summaries
      final summaries = await repository.getQuestionSummaries(
        offset: 0,
        limit: pageSize,
        filter: mergedFilter,
      );

      _currentOffset = pageSize;

      state = state.copyWith(
        summaries: summaries,
        totalCount: totalCount,
        hasMore: pageSize < totalCount,
        isLoading: false,
      );

      // Preload first few questions
      await _preloadQuestions(0, _preloadRadius);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load next batch of questions
  Future<void> loadNextBatch() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = ref.read(questionRepositoryProvider);

      final newSummaries = await repository.getQuestionSummaries(
        offset: _currentOffset,
        limit: _batchSize,
        filter: state.currentFilter,
      );

      _currentOffset += _batchSize;

      state = state.copyWith(
        summaries: [...state.summaries, ...newSummaries],
        hasMore: newSummaries.length == _batchSize,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Handle page change
  Future<void> onPageChanged(int index) async {
    if (index < 0 || index >= state.summaries.length) return;

    // Submit pending answer before changing page
    // This handles the case when autoSubmit is disabled
    if (state.selectedAnswer != null && !state.answeredIndices.contains(state.currentIndex)) {
      await submitAnswer();
    }

    // Check if the new page has been answered
    final hasAnswered = state.answeredIndices.contains(index);
    final userAnswer = state.userAnswers[index];

    // CRITICAL: Immediately clear selectedAnswer to prevent carry-over to next question
    // This must happen before any async operations
    state = state.copyWith(
      currentIndex: index,
      selectedAnswerNull: Object(),  // Clear selectedAnswer (use Object() not null)
      showResult: hasAnswered,
    );

    // Preload questions around current position
    await _preloadQuestions(index, _preloadRadius);

    // Check if near end and need to load more
    if (index >= state.summaries.length - 5 && state.hasMore) {
      loadNextBatch();
    }

    // Check bookmark status for current question
    await _updateBookmarkStatus();
  }

  /// Update bookmark status for current question
  Future<void> _updateBookmarkStatus() async {
    final question = state.currentQuestion;
    if (question == null) return;

    final repository = ref.read(questionRepositoryProvider);
    final wrongQuestions = await repository.getWrongQuestions();
    final isInWrongBook = wrongQuestions.any((wq) => wq.questionId == question.id);

    state = state.copyWith(isBookmarked: isInWrongBook);
  }

  /// Select an answer for current question
  /// For single choice and judge: auto-submit based on user settings
  /// For multiple choice and essay: just update selection, require manual submit
  Future<void> selectAnswer(String answer) async {
    final question = state.currentQuestion;
    if (question == null) return;

    // For multiple choice and essay questions, only update selection (don't auto-submit)
    if (question.isMultipleChoice || question.isEssay) {
      if (state.selectedAnswer == answer) return; // No change
      state = state.copyWith(selectedAnswer: answer);
      return;
    }

    // For single choice and judge questions: check autoSubmit setting
    if (state.selectedAnswer == answer) return; // Already selected this answer
    state = state.copyWith(selectedAnswer: answer);

    // Get user settings to check if auto-submit is enabled
    final userSettings = ref.read(userSettingsProvider).settings;
    final autoSubmit = userSettings?.autoSubmit ?? true; // Default to true if null

    if (autoSubmit) {
      await submitAnswer();
    }
    // If autoSubmit is disabled, the answer is just stored but not submitted
    // User can still swipe or navigate, and the answer will be submitted when they
    // move to next question or when they manually tap submit
  }

  /// Submit answer for current question
  Future<void> submitAnswer() async {
    if (state.selectedAnswer == null) return;

    final summary = state.currentSummary;
    if (summary == null) return;

    final question = state.questionCache[summary.id];
    if (question == null) return;

    // Check if answer is correct
    final isCorrect = _checkAnswer(question, state.selectedAnswer!);

    // Update state FIRST to show result immediately
    final newAnsweredIndices = Set<int>.from(state.answeredIndices)..add(state.currentIndex);
    final newUserAnswers = Map<int, String>.from(state.userAnswers);
    newUserAnswers[state.currentIndex] = state.selectedAnswer!;

    state = state.copyWith(
      answeredIndices: newAnsweredIndices,
      userAnswers: newUserAnswers,
      showResult: true,
    );

    // Save to repository in background
    _saveAnswerInBackground(question, isCorrect);
  }

  /// Save answer and update wrong book in background
  Future<void> _saveAnswerInBackground(Question question, bool isCorrect) async {
    try {
      final repository = ref.read(questionRepositoryProvider);
      await repository.submitAnswer(
        questionId: question.id,
        userAnswer: state.selectedAnswer!,
        isCorrect: isCorrect,
        timeSpent: 0, // TODO: implement timing
      );

      // If answer was wrong, refresh wrong book asynchronously (don't block UI)
      if (!isCorrect) {
        Future.microtask(() {
          ref.read(wrongBookProvider.notifier).loadWrongQuestions();
        });
      }
    } catch (e) {
      // Silent fail - result already shown to user
    }
  }

  /// Toggle bookmark for current question (add/remove from wrong book)
  Future<void> toggleBookmark() async {
    final question = state.currentQuestion;
    if (question == null) return;

    final repository = ref.read(questionRepositoryProvider);

    // Check if question is already in wrong book
    final wrongQuestions = await repository.getWrongQuestions();
    final isInWrongBook = wrongQuestions.any((wq) => wq.questionId == question.id);

    if (isInWrongBook) {
      // Remove from wrong book
      await repository.removeWrongQuestion(question.id);
      state = state.copyWith(isBookmarked: false);
    } else {
      // Add to wrong book manually (even if answered correctly)
      // Need to get the QuestionModel to add to wrong book
      final questionModel = await _getQuestionModel(question.id);
      if (questionModel != null) {
        // Create a wrong question entry
        final wrongQuestion = WrongQuestionModel(
          id: const Uuid().v4(),
          questionId: question.id,
          question: questionModel,
          wrongAnswers: [], // Empty since user manually added it
          lastReviewAt: DateTime.now(),
          mastered: false,
          reviewCount: 0,
        );

        // Add to wrong book using datasource
        final hiveService = HiveService();
        final datasource = QuestionLocalDatasource(hiveService: hiveService);
        await datasource.addWrongQuestion(wrongQuestion);

        // Refresh wrong book provider
        ref.read(wrongBookProvider.notifier).loadWrongQuestions();
      }

      state = state.copyWith(isBookmarked: true);
    }
  }

  /// Get question model by ID for wrong book operations
  Future<QuestionModel?> _getQuestionModel(String id) async {
    final repository = ref.read(questionRepositoryProvider);
    final question = await repository.getQuestionById(id);

    if (question == null) return null;

    // Convert domain Question to QuestionModel
    return QuestionModel(
      id: question.id,
      source: question.source,
      category: question.category,
      type: question.type,
      question: question.question,
      options: question.options?.asMap().entries.map((entry) {
        final key = String.fromCharCode(65 + entry.key);
        return QuestionOption(key: key, text: entry.value);
      }).toList(),
      answer: question.answer,
      explanation: question.explanation,
      difficulty: question.difficulty,
      imageUrl: question.imageUrl,
      originalType: question.originalType,
      originalSource: question.originalSource,
    );
  }

  /// Apply filter and reload
  Future<void> applyFilter(QuestionFilter filter) async {
    // Reset state
    state = const PracticeSwipeState();
    _currentOffset = 0;

    // Reload with new filter
    await loadInitialBatch(
      category: state.category,
      filter: filter,
    );
  }

  /// Clear filter and reload
  Future<void> clearFilter() async {
    await applyFilter(const QuestionFilter());
  }

  /// Load random batch of questions for random practice mode
  /// This bypasses pagination and loads a fixed number of random questions
  Future<void> loadRandomBatch({
    required int count,
    required List<String> types, // ['single', 'multiple', 'judge']
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final repository = ref.read(questionRepositoryProvider);

      // Get random questions with specified types
      final randomQuestions = await repository.getRandomQuestionsWithFilter(
        count: count,
        types: types,
      );

      // Convert to summaries
      final summaries = randomQuestions.map((q) => QuestionSummary(
        id: q.id,
        category: q.primaryCategory,
        type: q.type,
        difficulty: q.difficulty,
        title: q.question.length > 30
            ? '${q.question.substring(0, 30)}...'
            : q.question,
        hasAnswered: false,
        isCorrect: false,
        wrongCount: 0,
        inWrongBook: false,
      )).toList();

      // Preload all questions into cache
      final questionCache = <String, Question>{};
      for (final question in randomQuestions) {
        questionCache[question.id] = question;
      }

      state = state.copyWith(
        summaries: summaries,
        questionCache: questionCache,
        totalCount: summaries.length,
        hasMore: false, // Random mode has no pagination
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save current progress
  Future<void> saveProgress() async {
    // TODO: Implement progress saving using datasource
  }

  /// Get status of a question by index
  QuestionStatus getQuestionStatus(int index) {
    if (!state.answeredIndices.contains(index)) {
      return QuestionStatus.unanswered;
    }

    final summary = index >= 0 && index < state.summaries.length
        ? state.summaries[index]
        : null;
    if (summary == null) return QuestionStatus.unanswered;

    final question = state.questionCache[summary.id];
    if (question == null) return QuestionStatus.unanswered;

    final userAnswer = state.userAnswers[index];
    if (userAnswer == null) return QuestionStatus.unanswered;

    final isCorrect = _checkAnswer(question, userAnswer);
    return isCorrect ? QuestionStatus.correct : QuestionStatus.wrong;
  }

  /// Get all question statuses
  List<QuestionStatus> getAllQuestionStatuses() {
    return List.generate(
      state.summaries.length,
      (index) => getQuestionStatus(index),
    );
  }

  // ========== Private Methods ==========

  /// Preload questions around center index
  Future<void> _preloadQuestions(int centerIndex, int radius) async {
    final repository = ref.read(questionRepositoryProvider);
    final newCache = Map<String, Question>.from(state.questionCache);

    // Load questions within radius
    for (int i = centerIndex - radius; i <= centerIndex + radius; i++) {
      if (i < 0 || i >= state.summaries.length) continue;

      final summary = state.summaries[i];
      if (newCache.containsKey(summary.id)) continue;

      try {
        final question = await repository.getQuestionById(summary.id);
        if (question != null) {
          newCache[summary.id] = question;
        }
      } catch (e) {
        // Silent fail - will retry on next access
      }
    }

    if (newCache.length != state.questionCache.length) {
      state = state.copyWith(questionCache: newCache);
    }
  }

  /// Check if user answer is correct
  bool _checkAnswer(Question question, String userAnswer) {
    if (question.isSingleChoice || question.isFill) {
      return userAnswer == question.answer;
    }

    if (question.isMultipleChoice) {
      // Use | separator (consistent with UI and data layer)
      final userAnswers = userAnswer.split('|')..sort();
      final correctAnswers = question.answer?.split('|') ?? []..sort();
      return _listsEqual(userAnswers, correctAnswers);
    }

    if (question.isJudge) {
      return userAnswer.toLowerCase() == question.answer?.toLowerCase();
    }

    if (question.isEssay) {
      // Essay type: use keyword matching (simplified version)
      if (question.answer == null || question.answer!.isEmpty) return false;
      final correctAnswer = question.answer!.toLowerCase();
      final userAnswerLower = userAnswer.toLowerCase();

      // Extract keywords from correct answer (2+ character words)
      final keywords = correctAnswer
          .replaceAll(RegExp(r'[；;。、,．．\(\)（）\[\]【】]'), ' ')
          .split(' ')
          .where((w) => w.trim().length >= 2)
          .toSet();

      if (keywords.isEmpty) return false;

      // Count matched keywords
      int matchedCount = 0;
      for (final keyword in keywords) {
        if (userAnswerLower.contains(keyword)) {
          matchedCount++;
        }
      }

      // Require at least 50% keyword match
      return matchedCount / keywords.length >= 0.5;
    }

    return false;
  }

  /// Compare two string lists for equality
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.every((item) => b.contains(item));
  }
}

/// Provider for accessing current question
@riverpod
Question? currentQuestion(CurrentQuestionRef ref) {
  final swipeState = ref.watch(practiceSwipeProvider);
  return swipeState.currentQuestion;
}

/// Provider for accessing current summary
@riverpod
QuestionSummary? currentSummary(CurrentSummaryRef ref) {
  final swipeState = ref.watch(practiceSwipeProvider);
  return swipeState.currentSummary;
}
