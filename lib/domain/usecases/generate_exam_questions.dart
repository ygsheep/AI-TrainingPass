import '../entities/question.dart';
import '../entities/exam_config.dart';
import '../repositories/question_repository.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

/// Generate Exam Questions Use Case
/// Generates questions for an exam based on configuration
class GenerateExamQuestionsUseCase {
  final QuestionRepository _repository;

  GenerateExamQuestionsUseCase(this._repository);

  /// Execute the use case
  /// Returns [GenerateExamQuestionsResult] with selected questions
  Future<GenerateExamQuestionsResult> execute(GenerateExamQuestionsParams params) async {
    try {
      // Get all questions from selected sources
      final allQuestions = await _repository.getQuestionsBySources(params.sources);

      if (allQuestions.isEmpty) {
        return GenerateExamQuestionsResult.error(
          'No questions found for selected sources',
        );
      }

      // Group questions by type
      final questionsByType = <String, List<Question>>{
        'single': [],
        'multiple': [],
        'judge': [],
        'essay': [],
      };

      for (final question in allQuestions) {
        if (questionsByType.containsKey(question.type)) {
          questionsByType[question.type]!.add(question);
        }
      }

      // Validate that we have enough questions for each type
      // If not enough, adjust allocation to use available questions
      final adjustedAllocation = Map<String, int>.from(params.typeAllocation);
      final validationErrors = <String>[];
      int totalRequired = params.totalQuestions;

      // Check each type and adjust if necessary
      for (final entry in params.typeAllocation.entries) {
        final type = entry.key;
        final required = entry.value;
        final available = questionsByType[type]?.length ?? 0;

        if (required > 0 && available < required) {
          // Not enough questions of this type
          AppLogger.debug('Not enough $type questions: required $required, available $available');

          // Use available count and note the shortage
          adjustedAllocation[type] = available;
          totalRequired -= (required - available);

          validationErrors.add(
            'Not enough $type questions: required $required, available $available',
          );
        }
      }

      // If we couldn't get all required questions, try to fill from other types
      if (totalRequired < params.totalQuestions) {
        int remainingShortage = params.totalQuestions - totalRequired;
        AppLogger.debug('Shortage of $remainingShortage questions, trying to fill from other types');

        // Try to fill shortage from other available types
        for (final type in ['single', 'multiple', 'judge']) {
          if (remainingShortage <= 0) break;

          final currentlyAllocated = adjustedAllocation[type] ?? 0;
          final available = questionsByType[type]?.length ?? 0;
          final unused = available - currentlyAllocated;

          if (unused > 0) {
            final toAdd = unused < remainingShortage ? unused : remainingShortage;
            adjustedAllocation[type] = currentlyAllocated + toAdd;
            remainingShortage -= toAdd;
            AppLogger.debug('Added $toAdd $type questions to fill shortage');
          }
        }
      }

      // Select questions using adjusted allocation
      final selectedQuestions = <Question>[];
      final typeOrder = ['single', 'multiple', 'judge'];

      AppLogger.debug('🎯 GenerateExam: Selecting questions with allocation: $adjustedAllocation');

      for (final type in typeOrder) {
        final count = adjustedAllocation[type] ?? 0;
        if (count == 0) continue;

        final typeQuestions = questionsByType[type] ?? [];
        AppLogger.debug('🎯 GenerateExam: Type $type - available=${typeQuestions.length}, selecting=$count');

        // Shuffle to randomize, then take required count
        final shuffled = List<Question>.from(typeQuestions)..shuffle();
        final taken = shuffled.take(count).toList();
        selectedQuestions.addAll(taken);

        // Debug: Show selected IDs for this type
        final ids = taken.map((q) => q.id).take(3).join(', ');
        AppLogger.debug('🎯 GenerateExam: Selected $count $type questions (sample IDs: $ids...)');
      }

      AppLogger.debug('🎯 GenerateExam: Total selected=${selectedQuestions.length}');

      // Debug: Show detailed type distribution of selected questions
      final selectedTypeCounts = <String, int>{};
      for (final q in selectedQuestions) {
        selectedTypeCounts[q.type] = (selectedTypeCounts[q.type] ?? 0) + 1;
      }
      AppLogger.debug('🎯 GenerateExam: Selected type distribution: $selectedTypeCounts');

      // Debug: Show first few questions with ID and type
      AppLogger.debug('🎯 GenerateExam: ALL selected questions:');
      for (int i = 0; i < selectedQuestions.length; i++) {
        final q = selectedQuestions[i];
        AppLogger.debug('  [$i] id=${q.id.substring(0, 8)}..., type=${q.type}, originalType=${q.originalType ?? 'N/A'}');
      }

      // Verify total count - allow some flexibility
      if (selectedQuestions.length < params.totalQuestions * 0.8) {
        // If we got less than 80% of required questions, that's an error
        return GenerateExamQuestionsResult.error(
          'Insufficient questions: generated ${selectedQuestions.length}, expected ${params.totalQuestions}. '
          'Please select more sources or reduce question count.',
        );
      }

      // Log any adjustments made
      if (validationErrors.isNotEmpty) {
        AppLogger.debug('Question allocation adjusted: ${validationErrors.join('\n')}');
      }

      return GenerateExamQuestionsResult.success(
        questions: selectedQuestions,
        availableCounts: questionsByType.map(
          (type, questions) => MapEntry(type, questions.length),
        ),
      );
    } catch (e) {
      AppLogger.debug('Error generating exam questions: $e');
      return GenerateExamQuestionsResult.error(e.toString());
    }
  }
}

/// Generate Exam Questions Parameters
class GenerateExamQuestionsParams {
  /// Selected sources (e.g., ['main', 'mock'])
  final List<String> sources;

  /// Total number of questions needed
  final int totalQuestions;

  /// Type allocation (e.g., {'single': 60, 'multiple': 20, 'judge': 20})
  final Map<String, int> typeAllocation;

  const GenerateExamQuestionsParams({
    required this.sources,
    required this.totalQuestions,
    required this.typeAllocation,
  });

  /// Create from ExamConfig
  factory GenerateExamQuestionsParams.fromConfig(ExamConfig config) {
    return GenerateExamQuestionsParams(
      sources: config.sources,
      totalQuestions: config.totalQuestions,
      typeAllocation: config.typeAllocation,
    );
  }

  @override
  String toString() {
    return 'GenerateExamQuestionsParams(sources: $sources, '
        'total: $totalQuestions, allocation: $typeAllocation)';
  }
}

/// Generate Exam Questions Result
class GenerateExamQuestionsResult {
  final bool success;
  final List<Question>? questions;
  final Map<String, int>? availableCounts; // Available questions per type
  final String? error;

  const GenerateExamQuestionsResult._({
    required this.success,
    this.questions,
    this.availableCounts,
    this.error,
  });

  factory GenerateExamQuestionsResult.success({
    required List<Question> questions,
    required Map<String, int> availableCounts,
  }) {
    return GenerateExamQuestionsResult._(
      success: true,
      questions: questions,
      availableCounts: availableCounts,
    );
  }

  factory GenerateExamQuestionsResult.error(String error) {
    return GenerateExamQuestionsResult._(
      success: false,
      error: error,
    );
  }

  /// Get questions in order (1-60: single, 61-80: multiple, 81-100: judge)
  List<Question> get orderedQuestions => questions ?? [];

  /// Get the question number range for each type
  Map<String, QuestionRange> get typeRanges {
    if (!success || questions == null) return {};

    final ranges = <String, QuestionRange>{};
    int currentIndex = 1;

    // Single choice: 1-60
    final singleCount = availableCounts?['single'] ?? 0;
    if (singleCount > 0) {
      ranges['single'] = QuestionRange(
        start: currentIndex,
        end: currentIndex + singleCount - 1,
      );
      currentIndex += singleCount;
    }

    // Multiple choice: next range
    final multipleCount = availableCounts?['multiple'] ?? 0;
    if (multipleCount > 0) {
      ranges['multiple'] = QuestionRange(
        start: currentIndex,
        end: currentIndex + multipleCount - 1,
      );
      currentIndex += multipleCount;
    }

    // Judge: next range
    final judgeCount = availableCounts?['judge'] ?? 0;
    if (judgeCount > 0) {
      ranges['judge'] = QuestionRange(
        start: currentIndex,
        end: currentIndex + judgeCount - 1,
      );
      currentIndex += judgeCount;
    }

    return ranges;
  }
}

/// Question Range for a specific type
class QuestionRange {
  final int start;
  final int end;

  const QuestionRange({
    required this.start,
    required this.end,
  });

  @override
  String toString() => '$start-$end';
}
