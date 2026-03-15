import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/exam_config.dart';
import '../../domain/entities/source_statistics.dart';
import '../../domain/usecases/generate_exam_questions.dart';
import '../../core/constants/app_config.dart';
import 'question_provider.dart';
import 'exam_provider.dart';

part 'exam_setup_provider.g.dart';

/// Exam Setup State
class ExamSetupState {
  final ExamTemplate selectedTemplate;
  final List<String> selectedSources;
  final int durationMinutes;
  final int totalQuestions;
  final Map<String, int> typeAllocation;
  final int passScore;
  final Map<String, SourceStatistics> sourceStatistics;
  final bool isLoading;
  final bool isStartingExam;
  final String? error;
  final String? validationError;
  final bool examStartSuccess; // Track successful exam start

  const ExamSetupState({
    this.selectedTemplate = ExamTemplate.quick,
    this.selectedSources = const ['main'],
    this.durationMinutes = 90,
    this.totalQuestions = 100,
    this.typeAllocation = const {
      'single': 60,
      'multiple': 20,
      'judge': 20,
    },
    this.passScore = 60,
    this.sourceStatistics = const {},
    this.isLoading = true,
    this.isStartingExam = false,
    this.error,
    this.validationError,
    this.examStartSuccess = false,
  });

  /// Get total available questions from selected sources
  int get totalAvailableQuestions {
    return selectedSources.fold(
      0,
      (sum, source) => sum + (sourceStatistics[source]?.totalCount ?? 0),
    );
  }

  /// Get available questions by type
  Map<String, int> get availableByType {
    final result = <String, int>{};
    for (final source in selectedSources) {
      final stats = sourceStatistics[source];
      if (stats != null) {
        for (final entry in stats.typeDistribution.entries) {
          result[entry.key] = (result[entry.key] ?? 0) + entry.value;
        }
      }
    }
    return result;
  }

  /// Check if configuration is valid
  bool get isValid {
    // Must have at least one source selected
    if (selectedSources.isEmpty) {
      AppLogger.debug('ExamSetup: isValid=false - no sources selected');
      return false;
    }

    // Must have valid parameters
    if (durationMinutes <= 0 || totalQuestions <= 0) {
      AppLogger.debug('ExamSetup: isValid=false - invalid parameters');
      return false;
    }

    // Must have questions available
    if (totalAvailableQuestions < totalQuestions) {
      AppLogger.debug('ExamSetup: isValid=false - not enough questions (available: $totalAvailableQuestions, required: $totalQuestions)');
      return false;
    }

    // Check type allocation - verify each type has enough questions
    final availableByType = this.availableByType;
    for (final entry in typeAllocation.entries) {
      final required = entry.value;
      final available = availableByType[entry.key] ?? 0;
      if (required > 0 && available < required) {
        AppLogger.debug('ExamSetup: isValid=false - not enough ${entry.key} questions (available: $available, required: $required)');
        return false;
      }
    }

    AppLogger.debug('ExamSetup: isValid=true');
    return true;
  }

  /// Get validation error message
  String? getValidationErrorMessage() {
    if (selectedSources.isEmpty) {
      return '请至少选择一个题库来源';
    }

    if (durationMinutes <= 0) {
      return '考试时长必须大于0';
    }

    if (totalQuestions <= 0) {
      return '题目数量必须大于0';
    }

    final available = totalAvailableQuestions;
    if (available < totalQuestions) {
      return '可用题目不足：需要 $totalQuestions 题，可用 $available 题';
    }

    // Check type allocation
    final availableByType = this.availableByType;
    for (final entry in typeAllocation.entries) {
      final required = entry.value;
      final availableType = availableByType[entry.key] ?? 0;
      if (required > 0 && availableType < required) {
        final typeName = _getTypeDisplayName(entry.key);
        return '可用${typeName}不足：需要 $required 题，可用 $availableType 题';
      }
    }

    return null;
  }

  String _getTypeDisplayName(String type) {
    const names = {
      'single': '单选题',
      'multiple': '多选题',
      'judge': '判断题',
      'essay': '简答题',
    };
    return names[type] ?? type;
  }

  /// Create ExamConfig from current state
  ExamConfig toExamConfig() {
    return ExamConfig(
      template: selectedTemplate,
      sources: selectedSources,
      durationMinutes: durationMinutes,
      totalQuestions: totalQuestions,
      typeAllocation: typeAllocation,
      passScore: passScore,
    );
  }

  ExamSetupState copyWith({
    ExamTemplate? selectedTemplate,
    List<String>? selectedSources,
    int? durationMinutes,
    int? totalQuestions,
    Map<String, int>? typeAllocation,
    int? passScore,
    Map<String, SourceStatistics>? sourceStatistics,
    bool? isLoading,
    bool? isStartingExam,
    String? error,
    String? validationError,
    bool? examStartSuccess,
  }) {
    return ExamSetupState(
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      selectedSources: selectedSources ?? this.selectedSources,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      typeAllocation: typeAllocation ?? this.typeAllocation,
      passScore: passScore ?? this.passScore,
      sourceStatistics: sourceStatistics ?? this.sourceStatistics,
      isLoading: isLoading ?? this.isLoading,
      isStartingExam: isStartingExam ?? this.isStartingExam,
      error: error ?? this.error,
      validationError: validationError ?? this.validationError,
      examStartSuccess: examStartSuccess ?? this.examStartSuccess,
    );
  }
}

/// Exam Setup Provider
@riverpod
class ExamSetup extends _$ExamSetup {
  @override
  ExamSetupState build() {
    // Load source statistics asynchronously after first build
    Future.microtask(() => loadSourceStatistics());

    // Initial state with empty sources - will be updated after statistics load
    return ExamSetupState(
      selectedTemplate: ExamTemplate.quick,
      selectedSources: [], // Will be updated after statistics load
      durationMinutes: 30,
      totalQuestions: 30,
      typeAllocation: _getQuickTypeAllocation(),
      passScore: AppConfig.defaultExamPassScore,
      isLoading: true, // Start in loading state
      examStartSuccess: false, // Initialize to false
    );
  }

  /// Get standard type allocation (60 single, 20 multiple, 20 judge)
  Map<String, int> _getStandardTypeAllocation() {
    return const {
      'single': 60,
      'multiple': 20,
      'judge': 20,
    };
  }

  /// Get quick type allocation (20 single, 5 multiple, 5 judge)
  Map<String, int> _getQuickTypeAllocation() {
    return const {
      'single': 20,
      'multiple': 5,
      'judge': 5,
    };
  }

  /// Get practice type allocation (30 single, 10 multiple, 10 judge)
  Map<String, int> _getPracticeTypeAllocation() {
    return const {
      'single': 30,
      'multiple': 10,
      'judge': 10,
    };
  }

  /// Load source statistics
  Future<void> loadSourceStatistics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(questionRepositoryProvider);

      // First, get all questions and find unique sources dynamically
      final allQuestions = await repository.loadQuestionBank();
      final uniqueSources = allQuestions.map((q) => q.source).toSet();

      AppLogger.debug('Found sources: $uniqueSources');

      final statistics = <String, SourceStatistics>{};

      // Load statistics for each unique source found in the question bank
      for (final source in uniqueSources) {
        try {
          final stats = await repository.getSourceStatistics(source);
          statistics[source] = stats;
          AppLogger.debug('Loaded stats for $source: ${stats.totalCount} questions');
        } catch (e) {
          AppLogger.debug('Error loading stats for $source: $e');
          // Continue loading other sources even if one fails
          continue;
        }
      }

      AppLogger.debug('Total statistics loaded: ${statistics.length}');

      // Auto-select best source if none selected
      // Prefer sources that have all three types (single, multiple, judge)
      String? bestSource;
      int bestSourceScore = -1;

      for (final entry in statistics.entries) {
        final source = entry.key;
        final stats = entry.value;

        // Calculate score: prioritize sources with more question types
        int typeCount = stats.typeDistribution.length;
        int totalQuestions = stats.totalCount;

        // Bonus for having judge questions (often the limiting factor)
        bool hasJudge = stats.typeDistribution.containsKey('judge') &&
                       stats.typeDistribution['judge']! > 0;

        int score = typeCount * 1000 + totalQuestions + (hasJudge ? 500 : 0);

        AppLogger.debug('Source $source score: $score (types: $typeCount, total: $totalQuestions, hasJudge: $hasJudge)');

        if (score > bestSourceScore) {
          bestSource = source;
          bestSourceScore = score;
        }
      }

      final selectedSources = state.selectedSources.isEmpty && bestSource != null
          ? [bestSource]
          : state.selectedSources;

      AppLogger.debug('Auto-selected sources: $selectedSources (best source: $bestSource)');

      // Log available questions by type for debugging
      for (final entry in statistics.entries) {
        final stats = entry.value;
        AppLogger.debug('Source ${entry.key}: total=${stats.totalCount}, typeDistribution=${stats.typeDistribution}');
      }

      state = state.copyWith(
        sourceStatistics: statistics,
        selectedSources: selectedSources,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.debug('Error loading source statistics: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Select a preset template
  void selectTemplate(ExamTemplate template) {
    final newConfig = _getTemplateConfig(template);

    // Check if current sources can support this template
    final allocation = newConfig['allocation'] as Map<String, int>;
    final availableByType = state.availableByType;

    // Check if all required types have enough questions
    bool canUseCurrentSources = true;
    String? missingType;

    for (final entry in allocation.entries) {
      final required = entry.value as int;
      if (required > 0) {
        final available = availableByType[entry.key] ?? 0;
        if (available < required) {
          canUseCurrentSources = false;
          missingType = entry.key;
          break;
        }
      }
    }

    // If current sources don't have enough questions, try to find a better source
    if (!canUseCurrentSources) {
      AppLogger.debug('Current sources cannot support template $template (missing $missingType)');
      AppLogger.debug('Searching for alternative sources...');

      // Try to find sources that have all required types
      String? bestSource;
      int bestSourceScore = -1;

      for (final entry in state.sourceStatistics.entries) {
        final source = entry.key;
        final stats = entry.value;

        // Check if this source has all required types
        bool hasAllTypes = true;
        for (final allocEntry in allocation.entries) {
          final required = allocEntry.value as int;
          if (required > 0) {
            final available = stats.typeDistribution[allocEntry.key] ?? 0;
            if (available < required) {
              hasAllTypes = false;
              break;
            }
          }
        }

        if (hasAllTypes) {
          // Calculate score based on total questions
          if (stats.totalCount > bestSourceScore) {
            bestSource = source;
            bestSourceScore = stats.totalCount;
          }
        }
      }

      // If found a better source, switch to it
      if (bestSource != null) {
        AppLogger.debug('Switching to source: $bestSource ($bestSourceScore questions)');
        state = state.copyWith(
          selectedTemplate: template,
          durationMinutes: newConfig['duration'] as int,
          totalQuestions: newConfig['questions'] as int,
          typeAllocation: allocation,
          selectedSources: [bestSource],
        );
        return;
      } else {
        AppLogger.debug('No single source can support this template, trying multiple sources...');
      }
    }

    state = state.copyWith(
      selectedTemplate: template,
      durationMinutes: newConfig['duration'] as int,
      totalQuestions: newConfig['questions'] as int,
      typeAllocation: allocation,
    );
  }

  /// Get template configuration
  Map<String, dynamic> _getTemplateConfig(ExamTemplate template) {
    switch (template) {
      case ExamTemplate.standard:
        return {
          'duration': 90,
          'questions': 100,
          'allocation': _getStandardTypeAllocation(),
        };
      case ExamTemplate.quick:
        return {
          'duration': 30,
          'questions': 30,
          'allocation': _getQuickTypeAllocation(),
        };
      case ExamTemplate.practice:
        return {
          'duration': 60,
          'questions': 50,
          'allocation': _getPracticeTypeAllocation(),
        };
      case ExamTemplate.custom:
        // Keep current values for custom
        return {
          'duration': state.durationMinutes,
          'questions': state.totalQuestions,
          'allocation': state.typeAllocation,
        };
    }
  }

  /// Toggle source selection
  void toggleSource(String source) {
    final current = state.selectedSources;
    List<String> updated;

    if (current.contains(source)) {
      // Don't allow deselecting the last source
      if (current.length == 1) return;
      updated = current.where((s) => s != source).toList();
    } else {
      updated = [...current, source];
    }

    state = state.copyWith(selectedSources: updated);
  }

  /// Update duration
  void updateDuration(int minutes) {
    state = state.copyWith(
      durationMinutes: minutes,
      selectedTemplate: ExamTemplate.custom,
    );
  }

  /// Update total questions
  void updateTotalQuestions(int count) {
    state = state.copyWith(
      totalQuestions: count,
      selectedTemplate: ExamTemplate.custom,
    );
  }

  /// Update type allocation for a specific type
  void updateTypeAllocation(String type, int count) {
    final newAllocation = Map<String, int>.from(state.typeAllocation);
    newAllocation[type] = count;
    state = state.copyWith(
      typeAllocation: newAllocation,
      selectedTemplate: ExamTemplate.custom,
    );
  }

  /// Update pass score
  void updatePassScore(int score) {
    state = state.copyWith(passScore: score);
  }

  /// Validate configuration
  bool validateConfiguration() {
    final error = state.getValidationErrorMessage();
    state = state.copyWith(validationError: error);
    return error == null;
  }

  /// Start exam with current configuration
  Future<bool> startExam() async {
    if (!validateConfiguration()) {
      return false;
    }

    state = state.copyWith(isStartingExam: true, examStartSuccess: false);

    AppLogger.debug('🚀 ExamSetup.startExam: duration=${state.durationMinutes}, questions=${state.totalQuestions}, passScore=${state.passScore}');

    try {
      final repository = ref.read(questionRepositoryProvider);
      final useCase = GenerateExamQuestionsUseCase(repository);

      final config = state.toExamConfig();
      AppLogger.debug('🚀 ExamConfig: duration=${config.durationMinutes}, questions=${config.totalQuestions}, sources=${config.sources}');

      final params = GenerateExamQuestionsParams.fromConfig(config);

      final result = await useCase.execute(params);

      if (!result.success) {
        state = state.copyWith(
          isStartingExam: false,
          examStartSuccess: false,
          validationError: result.error ?? '生成题目失败',
        );
        return false;
      }

      AppLogger.debug('🚀 Generated ${result.questions!.length} questions');

      // Start the exam using ActiveExam provider with the generated questions
      final activeExam = ref.read(activeExamProvider.notifier);

      // Generate questions successfully, now start exam with config
      final started = await activeExam.startExamWithConfig(
        questionIds: result.questions!.map((q) => q.id).toList(),
        duration: config.durationMinutes,
        passScore: config.passScore,
        sources: config.sources,
        typeAllocation: config.typeAllocation,
      );

      if (!started) {
        state = state.copyWith(
          isStartingExam: false,
          examStartSuccess: false,
          validationError: '启动考试失败',
        );
        return false;
      }

      AppLogger.debug('🚀 Exam started successfully');

      state = state.copyWith(isStartingExam: false, examStartSuccess: true);
      return true;
    } catch (e) {
      AppLogger.debug('❌ ExamSetup.startExam error: $e');
      state = state.copyWith(
        isStartingExam: false,
        examStartSuccess: false,
        validationError: e.toString(),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear validation error
  void clearValidationError() {
    state = state.copyWith(validationError: null);
  }

  /// Reset to default state
  void reset() {
    state = ExamSetupState(
      selectedTemplate: ExamTemplate.quick,
      selectedSources: [AppConfig.defaultExamSource],
      durationMinutes: 30,
      totalQuestions: 30,
      typeAllocation: _getQuickTypeAllocation(),
      passScore: AppConfig.defaultExamPassScore,
      sourceStatistics: state.sourceStatistics,
      examStartSuccess: false,
    );
  }
}

/// Available sources for exam setup
@riverpod
List<String> examSetupSources(Ref ref) {
  return const ['main', 'mock', 'review'];
}
