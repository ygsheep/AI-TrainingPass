import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/exam_statistics.dart';
import '../../domain/usecases/start_exam.dart';
import '../../domain/usecases/submit_exam.dart';
import '../../domain/usecases/get_exam_history.dart';
import '../../domain/utils/answer_checker.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/exam_record.dart';
import '../../data/models/user_answer.dart';
import 'question_provider.dart';

part 'exam_provider.g.dart';

/// Exam State
class ExamState {
  final List<Question> questions;
  final int currentIndex;
  final List<UserAnswerModel> answers;
  final DateTime startTime;
  final int duration; // in minutes
  final int passScore;
  final bool isCompleted;
  final bool isSubmitting;
  final String? error;
  final List<String> sources; // Added for new exam flow
  final Map<String, int> typeAllocation; // Added for new exam flow

  const ExamState({
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const [],
    required this.startTime,
    this.duration = 90,
    this.passScore = 60,
    this.isCompleted = false,
    this.isSubmitting = false,
    this.error,
    this.sources = const [], // Added
    this.typeAllocation = const {}, // Added
  });

  /// Get current question
  Question? get currentQuestion {
    if (currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  /// Get progress (0.0 to 1.0)
  double get progress {
    if (questions.isEmpty) return 0.0;
    return currentIndex / questions.length;
  }

  /// Get answered count
  int get answeredCount => answers.length;

  /// Get total count
  int get totalCount => questions.length;

  /// Check if current question is answered
  bool get isCurrentQuestionAnswered {
    if (currentIndex >= questions.length) return false;
    final questionId = questions[currentIndex].id;
    return answers.any((a) => a.questionId == questionId);
  }

  /// Get answer for current question
  UserAnswerModel? get currentAnswer {
    if (currentIndex >= questions.length) return null;
    final questionId = questions[currentIndex].id;
    try {
      return answers.firstWhere((a) => a.questionId == questionId);
    } catch (_) {
      return null;
    }
  }

  ExamState copyWith({
    List<Question>? questions,
    int? currentIndex,
    List<UserAnswerModel>? answers,
    DateTime? startTime,
    int? duration,
    int? passScore,
    bool? isCompleted,
    bool? isSubmitting,
    String? error,
    List<String>? sources,
    Map<String, int>? typeAllocation,
  }) {
    return ExamState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      passScore: passScore ?? this.passScore,
      isCompleted: isCompleted ?? this.isCompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
      sources: sources ?? this.sources,
      typeAllocation: typeAllocation ?? this.typeAllocation,
    );
  }
}

/// Active Exam State Provider
@riverpod
class ActiveExam extends _$ActiveExam {
  @override
  ExamState? build() {
    // Keep state alive even when no listeners are attached
    // This ensures the exam state persists during navigation from setup to exam page
    ref.keepAlive();
    // No active exam by default
    return null;
  }

  /// Start a new exam with pre-generated questions (from exam setup)
  Future<bool> startExamWithConfig({
    required List<String> questionIds,
    required int duration,
    required int passScore,
    List<String>? sources,
    Map<String, int>? typeAllocation,
  }) async {
    AppLogger.debug('📚 startExamWithConfig: duration=$duration, passScore=$passScore, questions=${questionIds.length}');
    AppLogger.debug('📚 ActiveExam state before: ${state != null ? "EXISTS (${state!.questions.length} questions)" : "NULL"}');

    final repository = ref.read(questionRepositoryProvider);
    final useCase = StartExamUseCase(repository);

    final result = await useCase.execute(StartExamParams(
      questionIds: questionIds,
    ));

    if (!result.success) {
      AppLogger.debug('❌ startExamWithConfig failed: ${result.error}');
      return false;
    }

    AppLogger.debug('📚 Creating ExamState: duration=$duration, passScore=$passScore, loadedQuestions=${result.questions!.length}');

    final examState = ExamState(
      questions: result.questions!,
      startTime: DateTime.now(),
      duration: duration,
      passScore: passScore,
      sources: sources ?? [],
      typeAllocation: typeAllocation ?? {},
    );

    state = examState;

    AppLogger.debug('✅ ExamState created with duration=${examState.duration}, questions=${examState.questions.length}');
    AppLogger.debug('📚 ActiveExam state after: ${state != null ? "EXISTS (${state!.questions.length} questions)" : "NULL"}');

    return true;
  }

  /// Start a new exam (legacy method)
  Future<bool> startExam({
    List<String>? categoryIds,
    List<String>? questionIds,
    int? questionCount,
  }) async {
    final repository = ref.read(questionRepositoryProvider);
    final useCase = StartExamUseCase(repository);

    final result = await useCase.execute(StartExamParams(
      categoryIds: categoryIds,
      questionIds: questionIds,
      questionCount: questionCount,
    ));

    if (!result.success) {
      return false;
    }

    state = ExamState(
      questions: result.questions!,
      startTime: DateTime.now(),
      duration: result.duration!,
      passScore: result.passScore!,
    );

    return true;
  }

  /// Submit answer for current question
  Future<void> submitAnswer({
    required String userAnswer,
    required int timeSpent,
  }) async {
    if (state == null || state!.currentQuestion == null) return;

    final question = state!.currentQuestion!;
    final questionId = question.id;

    // Check if answer is correct
    final isCorrect = AnswerChecker.checkAnswer(question, userAnswer);

    // Create or update answer
    final newAnswer = UserAnswerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      questionId: questionId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      answeredAt: DateTime.now(),
    );

    // Remove existing answer if any
    final updatedAnswers = state!.answers
        .where((a) => a.questionId != questionId)
        .toList()
      ..add(newAnswer);

    state = state!.copyWith(answers: updatedAnswers);
  }

  /// Go to next question
  void goToNext() {
    if (state == null) return;
    if (state!.currentIndex < state!.questions.length - 1) {
      state = state!.copyWith(currentIndex: state!.currentIndex + 1);
    }
  }

  /// Go to previous question
  void goToPrevious() {
    if (state == null) return;
    if (state!.currentIndex > 0) {
      state = state!.copyWith(currentIndex: state!.currentIndex - 1);
    }
  }

  /// Jump to specific question
  void jumpToQuestion(int index) {
    if (state == null) return;
    if (index >= 0 && index < state!.questions.length) {
      state = state!.copyWith(currentIndex: index);
    }
  }

  /// Submit the exam
  Future<SubmitExamResult?> submitExam() async {
    if (state == null || state!.isSubmitting) return null;

    state = state!.copyWith(isSubmitting: true);

    final repository = ref.read(questionRepositoryProvider);
    final useCase = SubmitExamUseCase(repository);

    // Calculate actual duration in seconds
    final actualDuration = DateTime.now().difference(state!.startTime).inSeconds;

    final result = await useCase.execute(SubmitExamParams(
      examName: '模拟考试',
      questionIds: state!.questions.map((q) => q.id).toList(),
      answers: state!.answers,
      startTime: state!.startTime,
      actualDuration: actualDuration,
      configDuration: state!.duration,
      passScore: state!.passScore,
    ));

    if (result.success) {
      state = state!.copyWith(
        isCompleted: true,
        isSubmitting: false,
      );
      // Invalidate exam history cache
      ref.invalidate(examHistoryProvider);
      ref.invalidate(examStatisticsProvider);
    } else {
      state = state!.copyWith(
        isSubmitting: false,
        error: result.error,
      );
    }

    return result;
  }

  /// End exam (without submitting)
  void endExam() {
    state = null;
  }

  /// Clear error
  void clearError() {
    if (state != null) {
      state = state!.copyWith(error: null);
    }
  }

  /// Update exam configuration (duration and pass score)
  void updateConfig({
    int? duration,
    int? passScore,
  }) {
    if (state != null) {
      AppLogger.debug('🔄 updateConfig: old duration=${state!.duration}, new duration=$duration');
      state = state!.copyWith(
        duration: duration,
        passScore: passScore,
      );
      AppLogger.debug('✅ updateConfig done: current duration=${state!.duration}');
    }
  }
}

/// Exam History State
class ExamHistoryState {
  final List<ExamRecordModel> records;
  final int totalCount;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const ExamHistoryState({
    this.records = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  ExamHistoryState copyWith({
    List<ExamRecordModel>? records,
    int? totalCount,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return ExamHistoryState(
      records: records ?? this.records,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Exam History Provider
@riverpod
class ExamHistory extends _$ExamHistory {
  @override
  ExamHistoryState build() {
    // Don't call loadHistory here to avoid circular dependency
    // State will be loaded when first accessed
    return const ExamHistoryState(isLoading: true);
  }

  Future<void> loadHistory({
    DateTime? startDate,
    DateTime? endDate,
    bool? passedOnly,
    int offset = 0,
    int? limit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(questionRepositoryProvider);
    final useCase = GetExamHistoryUseCase(repository);

    // Default to initial page size if no limit specified
    final loadLimit = limit ?? AppConfig.initialHistoryPageSize;

    final result = await useCase.execute(GetExamHistoryParams(
      startDate: startDate,
      endDate: endDate,
      passedOnly: passedOnly,
      offset: offset,
      limit: loadLimit,
    ));

    if (!result.success) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    state = state.copyWith(
      records: result.records ?? [],
      totalCount: result.totalCount ?? 0,
      hasMore: result.hasMore ?? false,
      isLoading: false,
    );
  }

  /// Load more records
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final currentCount = state.records.length;

    final repository = ref.read(questionRepositoryProvider);
    final useCase = GetExamHistoryUseCase(repository);

    final result = await useCase.execute(GetExamHistoryParams(
      offset: currentCount,
      limit: AppConfig.historyLoadMorePageSize,
    ));

    if (!result.success) return;

    state = state.copyWith(
      records: [...state.records, ...(result.records ?? [])],
      hasMore: result.hasMore ?? false,
    );
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadHistory();
  }

  /// Delete an exam record
  Future<bool> deleteRecord(String recordId) async {
    try {
      // Use the repository directly through the use case
      final repository = ref.read(questionRepositoryProvider);
      await repository.deleteExamRecord(recordId);

      // Refresh the list
      await loadHistory(
        passedOnly: state.records.isNotEmpty && state.records.first.passed,
      );

      // Invalidate statistics cache
      ref.invalidate(examStatisticsProvider);

      return true;
    } catch (e) {
      AppLogger.debug('Failed to delete exam record: $e');
      return false;
    }
  }
}

/// Exam Statistics Provider
@riverpod
Future<ExamStatistics> examStatistics(Ref ref) async {
  final repository = ref.read(questionRepositoryProvider);
  final useCase = GetExamStatisticsUseCase(repository);

  final result = await useCase.execute();

  if (result.success) {
    return result.statistics!;
  }

  // Return empty statistics on error
  return const ExamStatistics(
    totalExams: 0,
    passedExams: 0,
    totalQuestionsAttempted: 0,
    totalCorrectAnswers: 0,
    averageAccuracy: 0,
    averageScore: 0,
    bestScore: 0,
    worstScore: 0,
    currentStreak: 0,
    bestStreak: 0,
    categoryStats: {},
  );
}

/// Single Exam Record Provider
@riverpod
Future<ExamRecordModel?> examRecord(Ref ref, String id) async {
  final repository = ref.read(questionRepositoryProvider);
  final useCase = GetExamRecordByIdUseCase(repository);

  final result = await useCase.execute(id);

  if (result.success) {
    return result.record;
  }

  return null;
}
