import '../entities/question.dart';
import '../repositories/question_repository.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

/// Start Exam Use Case
/// Initializes a new exam session with selected questions
class StartExamUseCase {
  final QuestionRepository _questionRepository;

  StartExamUseCase(this._questionRepository);

  /// Execute the use case
  /// Returns [StartExamResult] with exam questions and configuration
  Future<StartExamResult> execute(StartExamParams params) async {
    try {
      // Get default exam config (for now using hardcoded defaults)
      // In a real app, this would come from ConfigRepository
      const duration = 90; // minutes
      const passScore = 60; // points
      const defaultQuestionCount = 100;

      // Get questions based on selection mode
      List<Question> questions;

      if (params.questionIds != null && params.questionIds!.isNotEmpty) {
        // Get specific questions by IDs
        AppLogger.debug('📚 StartExam: Loading ${params.questionIds!.length} questions by ID');

        // Track unique IDs to detect duplicates
        final uniqueIds = <String>{};
        final duplicateCount = params.questionIds!.length - params.questionIds!.toSet().length;
        if (duplicateCount > 0) {
          AppLogger.debug('⚠️ StartExam: Found $duplicateCount duplicate IDs in input');
        }

        questions = [];
        for (final id in params.questionIds!) {
          final question = await _questionRepository.getQuestionById(id);
          if (question != null) {
            // Check if we already added this question (duplicate ID)
            if (!uniqueIds.add(id)) {
              AppLogger.debug('⚠️ Duplicate ID detected: $id, skipping');
              continue;
            }
            questions.add(question);
          }
        }

        AppLogger.debug('📚 StartExam: Loaded ${questions.length} unique questions (from ${params.questionIds!.length} IDs)');

        // Debug: Show type distribution of loaded questions
        final typeCounts = <String, int>{};
        for (final q in questions) {
          typeCounts[q.type] = (typeCounts[q.type] ?? 0) + 1;
        }
        AppLogger.debug('📊 StartExam: Type distribution: $typeCounts');

        if (questions.length < params.questionIds!.length * 0.8) {
          AppLogger.debug('❌ StartExam: Significant question loss - expected ${params.questionIds!.length}, got ${questions.length}');
        }

        // Debug: Show first 5 questions with their IDs and types
        AppLogger.debug('📋 StartExam: ALL questions with type details:');
        for (int i = 0; i < questions.length; i++) {
          final q = questions[i];
          AppLogger.debug('  [$i] id=${q.id.substring(0, 8)}..., type=${q.type}, originalType=${q.originalType ?? 'N/A'}');
        }

        // Show actual type distribution
        AppLogger.debug('📊 Actual type distribution: $typeCounts');
      } else if (params.categoryIds != null && params.categoryIds!.isNotEmpty) {
        // Get questions from specific categories
        questions = await _questionRepository.getRandomQuestionsFromCategories(
          params.questionCount ?? defaultQuestionCount,
          params.categoryIds!,
        );
      } else {
        // Get random questions from entire bank
        questions = await _questionRepository.getRandomQuestions(
          params.questionCount ?? defaultQuestionCount,
        );
      }

      if (questions.isEmpty) {
        return StartExamResult.error('没有可用的题目');
      }

      return StartExamResult.success(
        questions: questions,
        duration: duration,
        passScore: passScore,
        questionCount: questions.length,
      );
    } catch (e) {
      return StartExamResult.error(e.toString());
    }
  }
}

/// Start Exam Parameters
class StartExamParams {
  final List<String>? categoryIds;
  final List<String>? questionIds;
  final int? questionCount;

  const StartExamParams({
    this.categoryIds,
    this.questionIds,
    this.questionCount,
  });
}

/// Start Exam Result
class StartExamResult {
  final bool success;
  final List<Question>? questions;
  final int? duration;
  final int? passScore;
  final int? questionCount;
  final String? error;

  const StartExamResult._({
    required this.success,
    this.questions,
    this.duration,
    this.passScore,
    this.questionCount,
    this.error,
  });

  factory StartExamResult.success({
    required List<Question> questions,
    required int duration,
    required int passScore,
    required int questionCount,
  }) {
    return StartExamResult._(
      success: true,
      questions: questions,
      duration: duration,
      passScore: passScore,
      questionCount: questionCount,
    );
  }

  factory StartExamResult.error(String error) {
    return StartExamResult._(
      success: false,
      error: error,
    );
  }
}
