import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/load_question_bank.dart';
import '../../domain/usecases/submit_answer.dart';
import '../../domain/usecases/update_question_bank.dart';
import '../../domain/repositories/question_repository.dart';
import '../../core/extensions/iterable_extensions.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../data/datasources/local/question_local_datasource.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../data/datasources/local/file_service.dart';
import 'package:uuid/uuid.dart';

part 'question_provider.g.dart';

/// Question Repository Provider
@riverpod
QuestionRepository questionRepository(Ref ref) {
  final hiveService = HiveService();
  // Note: Initialize should be called once in main()
  // hiveService.initialize();

  return QuestionRepositoryImpl(
    localDatasource: QuestionLocalDatasource(hiveService: hiveService),
    fileService: FileService(),
    uuid: const Uuid(),
  );
}

/// Load Question Bank UseCase Provider
@riverpod
LoadQuestionBankUseCase loadQuestionBankUseCase(Ref ref) {
  final repository = ref.watch(questionRepositoryProvider);
  return LoadQuestionBankUseCase(repository);
}

/// Submit Answer UseCase Provider
@riverpod
SubmitAnswerUseCase submitAnswerUseCase(Ref ref) {
  final repository = ref.watch(questionRepositoryProvider);
  return SubmitAnswerUseCase(repository);
}

/// Update Question Bank UseCase Provider
@riverpod
UpdateQuestionBankUseCase updateQuestionBankUseCase(Ref ref) {
  final repository = ref.watch(questionRepositoryProvider);
  return UpdateQuestionBankUseCase(repository);
}

/// Question Bank State
class QuestionBankState {
  final List<Question> questions;
  final List<String> categories;
  final bool isLoading;
  final String? error;
  final String? version;

  const QuestionBankState({
    this.questions = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.version,
  });

  QuestionBankState copyWith({
    List<Question>? questions,
    List<String>? categories,
    bool? isLoading,
    String? error,
    String? version,
  }) {
    return QuestionBankState(
      questions: questions ?? this.questions,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      version: version ?? this.version,
    );
  }
}

/// Question Bank State Provider
@riverpod
class QuestionBank extends _$QuestionBank {
  bool _hasInitialized = false;
  bool _isLoading = false;

  @override
  QuestionBankState build() {
    // Auto-load on first access with smart retry
    if (!_hasInitialized && !_isLoading) {
      _isLoading = true;
      // Schedule loading after this frame
      Future.microtask(() => _smartLoadWithRetry());
    }

    return const QuestionBankState(isLoading: true);
  }

  /// Smart load with exponential backoff retry
  Future<void> _smartLoadWithRetry() async {
    if (_hasInitialized) return;

    final maxAttempts = 5;
    int attempt = 0;
    List<Question> loadedQuestions = [];
    List<String> categories = [];
    String? error;

    while (attempt < maxAttempts) {
      attempt++;
      AppLogger.debug('🔄 QuestionBank: Load attempt $attempt/$maxAttempts');

      try {
        final useCase = ref.read(loadQuestionBankUseCaseProvider);
        final result = await useCase.execute();

        if (result.isSuccess) {
          loadedQuestions = result.dataOrThrow;
          final categoriesResult = await useCase.getCategories();
          categories = categoriesResult.isSuccess
              ? categoriesResult.dataOrThrow
              : [];

          if (loadedQuestions.isNotEmpty) {
            // Success!
            state = QuestionBankState(
              questions: loadedQuestions,
              categories: categories,
              isLoading: false,
              error: null,
            );
            _hasInitialized = true;
            _isLoading = false;
            AppLogger.debug('✅ QuestionBank: Loaded ${loadedQuestions.length} questions (attempt $attempt)');
            return;
          }
        } else {
          error = result.error;
        }

        // If we got here, load failed or returned empty - retry with delay
        if (attempt < maxAttempts) {
          final delay = Duration(milliseconds: 200 * attempt); // Exponential backoff
          AppLogger.debug('⏳ QuestionBank: Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      } catch (e) {
        error = e.toString();
        AppLogger.debug('❌ QuestionBank: Error on attempt $attempt: $e');
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      }
    }

    // All attempts failed
    state = QuestionBankState(
      questions: loadedQuestions,
      categories: categories,
      isLoading: false,
      error: error ?? 'Failed to load questions after $maxAttempts attempts',
    );
    _isLoading = false;
    AppLogger.debug('❌ QuestionBank: Failed to load after $maxAttempts attempts');
  }

  /// Load all questions (public method)
  Future<void> loadQuestionBank() async {
    await _smartLoadWithRetry();
  }

  /// Get questions by category
  Future<void> loadByCategory(String category) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = ref.read(loadQuestionBankUseCaseProvider);
    final result = await useCase.getByCategory(category);

    if (!result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    state = state.copyWith(
      questions: result.dataOrThrow,
      isLoading: false,
    );
  }

  /// Get random questions
  Future<void> loadRandom(int count) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = ref.read(loadQuestionBankUseCaseProvider);
    final result = await useCase.getRandom(count);

    if (!result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    state = state.copyWith(
      questions: result.dataOrThrow,
      isLoading: false,
    );
  }

  /// Get random questions from categories
  Future<void> loadRandomFromCategories(int count, List<String> categories) async {
    state = state.copyWith(isLoading: true, error: null);

    final useCase = ref.read(loadQuestionBankUseCaseProvider);
    final result = await useCase.getRandomFromCategories(count, categories);

    if (!result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
      return;
    }

    state = state.copyWith(
      questions: result.dataOrThrow,
      isLoading: false,
    );
  }

  /// Get question by ID
  Question? getQuestionById(String id) {
    return state.questions.firstWhereOrNull((q) => q.id == id);
  }
}

/// Import Result State
class ImportResultState {
  final bool isImporting;
  final bool isSuccess;
  final String? error;
  final int? questionCount;

  const ImportResultState({
    this.isImporting = false,
    this.isSuccess = false,
    this.error,
    this.questionCount,
  });

  ImportResultState copyWith({
    bool? isImporting,
    bool? isSuccess,
    String? error,
    int? questionCount,
  }) {
    return ImportResultState(
      isImporting: isImporting ?? this.isImporting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}

/// Question Bank Import Provider
@riverpod
class QuestionBankImport extends _$QuestionBankImport {
  @override
  ImportResultState build() {
    return const ImportResultState();
  }

  /// Import question bank from file
  Future<void> importFromFile(String filePath) async {
    state = state.copyWith(
      isImporting: true,
      isSuccess: false,
      error: null,
    );

    final useCase = ref.read(updateQuestionBankUseCaseProvider);
    final result = await useCase.importFromFile(filePath);

    if (!result.success) {
      state = state.copyWith(
        isImporting: false,
        isSuccess: false,
        error: result.error,
      );
      return;
    }

    // Reload question bank after import
    ref.read(questionBankProvider.notifier).loadQuestionBank();

    state = state.copyWith(
      isImporting: false,
      isSuccess: true,
      questionCount: result.questionCount,
    );
  }

  /// Export question bank to file
  Future<String?> exportToFile({
    required String name,
    required String version,
    List<String>? categories,
    String? description,
  }) async {
    final useCase = ref.read(updateQuestionBankUseCaseProvider);
    final result = await useCase.exportToFile(
      name: name,
      version: version,
      categories: categories,
      description: description,
    );

    return result.success ? result.exportPath : result.error;
  }

  /// Get imported files
  Future<List<QuestionBankFile>> getImportedFiles() async {
    final useCase = ref.read(updateQuestionBankUseCaseProvider);
    return await useCase.getImportedFiles();
  }

  /// Delete imported file
  Future<bool> deleteFile(String filePath) async {
    final useCase = ref.read(updateQuestionBankUseCaseProvider);
    return await useCase.deleteFile(filePath);
  }

  /// Reset import state
  void reset() {
    state = const ImportResultState();
  }
}
