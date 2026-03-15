import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/question_summary.dart';
import '../../domain/entities/question_filter.dart';
import '../../domain/entities/practice_mode.dart';
import '../../domain/repositories/question_repository.dart';
import '../../domain/utils/answer_checker.dart';
import '../../core/constants/app_config.dart';
import 'question_provider.dart';

part 'practice_session_provider.g.dart';

/// Practice Session State
@sealed
class PracticeSessionState {
  /// Practice mode
  final PracticeMode? mode;

  /// Question summaries for this session
  final List<QuestionSummary> questionSummaries;

  /// Cache of loaded questions (id -> Question)
  final Map<String, Question> questionCache;

  /// Current question index
  final int currentIndex;

  /// Current question summary
  final QuestionSummary? currentSummary;

  /// Total questions in session
  final int totalQuestions;

  /// User answers (index -> answer)
  final Map<int, String> answers;

  /// Set of answered question indices
  final Set<int> answeredQuestions;

  /// Show result (answer submitted)
  final bool showResult;

  /// Whether currently loading
  final bool isLoading;

  /// Error message if any
  final String? error;

  const PracticeSessionState({
    this.mode,
    this.questionSummaries = const [],
    this.questionCache = const {},
    this.currentIndex = 0,
    this.currentSummary,
    this.totalQuestions = 0,
    this.answers = const {},
    this.answeredQuestions = const {},
    this.showResult = false,
    this.isLoading = false,
    this.error,
  });

  /// Copy with method
  PracticeSessionState copyWith({
    PracticeMode? mode,
    List<QuestionSummary>? questionSummaries,
    Map<String, Question>? questionCache,
    int? currentIndex,
    QuestionSummary? currentSummary,
    int? totalQuestions,
    Map<int, String>? answers,
    Set<int>? answeredQuestions,
    bool? showResult,
    bool? isLoading,
    String? error,
    // Use nullable bool to allow setting to null
    Object? modeNull,
  }) {
    return PracticeSessionState(
      mode: modeNull == null ? mode : null as PracticeMode?,
      questionSummaries: questionSummaries ?? this.questionSummaries,
      questionCache: questionCache ?? this.questionCache,
      currentIndex: currentIndex ?? this.currentIndex,
      currentSummary: currentSummary ?? this.currentSummary,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answers: answers ?? this.answers,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      showResult: showResult ?? this.showResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get current question from cache or null
  Question? get currentQuestion {
    return currentSummary != null ? questionCache[currentSummary!.id] : null;
  }

  /// Check if current question has answer
  bool get hasCurrentAnswer {
    return answers.containsKey(currentIndex);
  }

  /// Check if can go to previous question
  bool get hasPrevious => currentIndex > 0;

  /// Check if can go to next question
  bool get hasNext => currentIndex < totalQuestions - 1;

  /// Count of answered questions
  int get answeredCount => answeredQuestions.length;

  /// Progress (0.0 to 1.0)
  double get progress =>
      totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0;
}

/// Practice Session Provider
/// Manages practice session, current question, answers, and caching
@riverpod
class PracticeSession extends _$PracticeSession {
  @override
  PracticeSessionState build() {
    return const PracticeSessionState();
  }

  /// Start a new practice session
  Future<void> startSession({
    required PracticeMode mode,
    String? category,
    int? questionCount,
  }) async {
    state = state.copyWith(
      mode: mode,
      isLoading: true,
      questionSummaries: [],
      questionCache: {},
      currentIndex: 0,
      answers: {},
      answeredQuestions: {},
    );

    try {
      final repository = ref.read(questionRepositoryProvider);
      List<QuestionSummary> summaries;

      switch (mode) {
        case PracticeMode.sequential:
          // Load all or filtered by category
          summaries = await repository.getQuestionSummaries(
            filter: category != null
                ? QuestionFilter(category: category)
                : null,
          );
          break;

        case PracticeMode.random:
          // Load all and shuffle, then take count
          final all = await repository.getQuestionSummaries();
          all.shuffle();
          summaries = all.take(questionCount ?? AppConfig.defaultPracticeQuestionCount).toList();
          break;

        case PracticeMode.weakCategories:
          // TODO: Implement weak categories logic
          // For now, fall back to random
          final all = await repository.getQuestionSummaries();
          summaries = all.take(questionCount ?? 20).toList();
          break;

        case PracticeMode.wrongBook:
          // Load only wrong book questions
          summaries = await repository.getQuestionSummaries(
            filter: QuestionFilter(inWrongBook: true),
          );
          break;
      }

      if (summaries.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No questions found',
        );
        return;
      }

      state = state.copyWith(
        questionSummaries: summaries,
        totalQuestions: summaries.length,
        isLoading: false,
      );

      // Select first question
      selectQuestion(0);

      // Preload first few questions
      _preloadQuestions(_getPreloadIndices(0));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Select a question by index (lazy load if not cached)
  Future<void> selectQuestion(int index) async {
    if (index < 0 || index >= state.questionSummaries.length) return;

    final summary = state.questionSummaries[index];

    // Update current selection
    state = state.copyWith(
      currentIndex: index,
      currentSummary: summary,
      showResult: false,
    );

    // Load question if not cached
    if (!state.questionCache.containsKey(summary.id)) {
      await _loadQuestion(summary.id);
    }

    // Preload surrounding questions
    _preloadQuestions(_getPreloadIndices(index));
  }

  /// Submit answer for current question
  Future<void> submitAnswer(String answer, {int timeSpent = 0}) async {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    // Check answer
    final isCorrect = AnswerChecker.checkAnswer(currentQuestion, answer);

    // Save to repository
    try {
      final repository = ref.read(questionRepositoryProvider);
      await repository.submitAnswer(
        questionId: currentQuestion.id,
        userAnswer: answer,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
      );
    } catch (e) {
      // Continue even if save fails
    }

    // Update local state
    final newAnswers = Map<int, String>.from(state.answers);
    final newAnswered = Set<int>.from(state.answeredQuestions);
    newAnswers[state.currentIndex] = answer;
    newAnswered.add(state.currentIndex);

    state = state.copyWith(
      answers: newAnswers,
      answeredQuestions: newAnswered,
      showResult: true,
    );
  }

  /// Go to next question
  Future<void> nextQuestion() async {
    if (state.hasNext) {
      await selectQuestion(state.currentIndex + 1);
    }
  }

  /// Go to previous question
  Future<void> previousQuestion() async {
    if (state.hasPrevious) {
      await selectQuestion(state.currentIndex - 1);
    }
  }

  /// Jump to specific question
  Future<void> jumpToQuestion(int index) async {
    if (index >= 0 && index < state.totalQuestions) {
      await selectQuestion(index);
    }
  }

  /// End current session
  void endSession() {
    state = const PracticeSessionState();
  }

  /// Load a single question into cache
  Future<void> _loadQuestion(String id) async {
    try {
      final repository = ref.read(questionRepositoryProvider);
      final question = await repository.getQuestionById(id);

      if (question != null) {
        final newCache = Map<String, Question>.from(state.questionCache);
        newCache[id] = question;
        state = state.copyWith(questionCache: newCache);
      }
    } catch (e) {
      // Silently fail, will retry on next access
    }
  }

  /// Preload multiple questions
  Future<void> _preloadQuestions(List<int> indices) async {
    final repository = ref.read(questionRepositoryProvider);
    final newCache = Map<String, Question>.from(state.questionCache);

    for (final index in indices) {
      if (index >= 0 && index < state.questionSummaries.length) {
        final summary = state.questionSummaries[index];
        if (!state.questionCache.containsKey(summary.id)) {
          try {
            final question = await repository.getQuestionById(summary.id);
            if (question != null) {
              newCache[question.id] = question;
            }
          } catch (e) {
            // Silently fail for individual questions
          }
        }
      }
    }

    state = state.copyWith(questionCache: newCache);
  }

  /// Get indices to preload (surrounding current)
  List<int> _getPreloadIndices(int currentIndex) {
    final indices = <int>[];

    // Add next few questions
    for (int i = 1; i <= AppConfig.preloadQuestionCount; i++) {
      if (currentIndex + i < state.questionSummaries.length) {
        indices.add(currentIndex + i);
      }
    }

    // Add previous few questions
    for (int i = 1; i <= AppConfig.preloadQuestionCount; i++) {
      if (currentIndex - i >= 0) {
        indices.add(currentIndex - i);
      }
    }

    return indices;
  }
}
