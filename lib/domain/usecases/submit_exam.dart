import '../entities/exam_statistics.dart';
import '../repositories/question_repository.dart';
import '../../data/models/exam_record.dart';
import '../../data/models/user_answer.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Submit Exam Use Case
/// Finalizes an exam session and calculates results
class SubmitExamUseCase {
  final QuestionRepository _repository;
  final Uuid _uuid;

  SubmitExamUseCase(this._repository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  /// Execute the use case
  /// Returns [SubmitExamResult] with exam statistics
  Future<SubmitExamResult> execute(SubmitExamParams params) async {
    try {
      // Calculate score based on total questions (not just answered ones)
      // Unanswered questions are counted as wrong
      final correctCount = params.answers.where((a) => a.isCorrect).length;
      final totalQuestionCount = params.questionIds.length;
      final answeredCount = params.answers.length;
      final unansweredCount = totalQuestionCount - answeredCount;

      // Score is based on total questions, unanswered = wrong
      final score = totalQuestionCount > 0
          ? (correctCount / totalQuestionCount * 100).round()
          : 0;

      final passed = score >= params.passScore;

      // Save wrong answers to wrong book
      await _saveWrongAnswersToBook(params.answers, params.questionIds);

      // Create exam config
      final config = ExamConfigModel(
        name: params.examName,
        questionCount: totalQuestionCount,
        duration: params.configDuration,
        passScore: params.passScore,
        categories: params.categoryIds,
      );

      // Create exam record
      final record = ExamRecordModel(
        id: _uuid.v4(),
        config: config,
        questionIds: params.questionIds,
        answers: params.answers,
        startTime: params.startTime,
        endTime: DateTime.now(),
        duration: params.actualDuration,
        score: score,
        passed: passed,
        correctCount: correctCount,
        totalCount: totalQuestionCount,
      );

      // Save exam record via exam repository
      await _repository.saveExamRecord(record);

      // Get updated statistics
      final stats = await _repository.getExamStatistics();

      return SubmitExamResult.success(
        score: score,
        correctCount: correctCount,
        wrongCount: totalQuestionCount - correctCount,
        passed: passed,
        statistics: stats,
      );
    } catch (e) {
      return SubmitExamResult.error(e.toString());
    }
  }

  /// Save wrong answers to the wrong book
  Future<void> _saveWrongAnswersToBook(
    List<UserAnswerModel> answers,
    List<String> questionIds,
  ) async {
    for (final answer in answers) {
      // Only save wrong answers
      if (!answer.isCorrect) {
        try {
          await _repository.submitAnswer(
            questionId: answer.questionId,
            userAnswer: answer.userAnswer,
            isCorrect: false,
            timeSpent: answer.timeSpent,
          );
        } catch (e) {
          // Log but don't fail the entire exam submission
          AppLogger.debug('Failed to save wrong answer for ${answer.questionId}: $e');
        }
      }
    }
  }
}

/// Submit Exam Parameters
class SubmitExamParams {
  final String examName;
  final List<String> questionIds;
  final List<UserAnswerModel> answers;
  final DateTime startTime;
  final int? actualDuration; // seconds
  final int configDuration; // minutes (from config)
  final int passScore;
  final List<String>? categoryIds;

  const SubmitExamParams({
    required this.examName,
    required this.questionIds,
    required this.answers,
    required this.startTime,
    this.actualDuration,
    required this.configDuration,
    required this.passScore,
    this.categoryIds,
  });
}

/// Submit Exam Result
class SubmitExamResult {
  final bool success;
  final int? score;
  final int? correctCount;
  final int? wrongCount;
  final bool? passed;
  final ExamStatistics? statistics;
  final String? error;

  const SubmitExamResult._({
    required this.success,
    this.score,
    this.correctCount,
    this.wrongCount,
    this.passed,
    this.statistics,
    this.error,
  });

  factory SubmitExamResult.success({
    required int score,
    required int correctCount,
    required int wrongCount,
    required bool passed,
    required ExamStatistics statistics,
  }) {
    return SubmitExamResult._(
      success: true,
      score: score,
      correctCount: correctCount,
      wrongCount: wrongCount,
      passed: passed,
      statistics: statistics,
    );
  }

  factory SubmitExamResult.error(String error) {
    return SubmitExamResult._(
      success: false,
      error: error,
    );
  }
}
