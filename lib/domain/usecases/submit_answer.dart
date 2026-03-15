import '../repositories/question_repository.dart';
import '../entities/question.dart';

/// Submit Answer Use Case
/// Handles answer submission and wrong question tracking
class SubmitAnswerUseCase {
  final QuestionRepository _repository;

  SubmitAnswerUseCase(this._repository);

  /// Execute the use case
  /// Returns [SubmitAnswerResult] with correctness and updated wrong book count
  Future<SubmitAnswerResult> execute(SubmitAnswerParams params) async {
    try {
      // Get the question to check answer
      final question = await _repository.getQuestionById(params.questionId);
      if (question == null) {
        return SubmitAnswerResult.error('题目不存在');
      }

      // Check if answer is correct
      final isCorrect = _checkAnswer(question, params.userAnswer);

      // Submit the answer
      await _repository.submitAnswer(
        questionId: params.questionId,
        userAnswer: params.userAnswer,
        isCorrect: isCorrect,
        timeSpent: params.timeSpent,
      );

      // Get updated wrong book count
      final wrongQuestions = await _repository.getWrongQuestions();
      final needsReviewCount = wrongQuestions
          .where((wq) => !wq.mastered)
          .length;

      return SubmitAnswerResult.success(
        isCorrect: isCorrect,
        wrongBookCount: wrongQuestions.length,
        needsReviewCount: needsReviewCount,
      );
    } catch (e) {
      return SubmitAnswerResult.error(e.toString());
    }
  }

  /// Check if the user's answer is correct
  bool _checkAnswer(Question question, String userAnswer) {
    if (question.answer == null) return false;

    // Essay type: keyword matching
    if (question.isEssay) {
      return _checkEssayAnswer(question.answer!, userAnswer);
    }

    if (question.isMultipleChoice) {
      // Multiple choice: compare sorted answer lists
      final userAnswers = userAnswer.split('|')
        .map((s) => s.trim())
        .toList()
        ..sort();
      final correctAnswers = question.answer!.split('|')
        .map((s) => s.trim())
        .toList()
        ..sort();

      if (userAnswers.length != correctAnswers.length) return false;

      for (int i = 0; i < userAnswers.length; i++) {
        if (userAnswers[i].toLowerCase() != correctAnswers[i].toLowerCase()) {
          return false;
        }
      }
      return true;
    } else {
      // Single choice, judge: direct comparison
      return userAnswer.trim().toLowerCase() == question.answer!.trim().toLowerCase();
    }
  }

  /// Check essay answer using keyword matching
  /// Returns true if user answer contains sufficient keywords (>= 50% match)
  bool _checkEssayAnswer(String correctAnswer, String userAnswer) {
    // Extract keywords from correct answer (2+ character words)
    final cleanCorrect = correctAnswer
        .replaceAll(RegExp(r'[；;。、,，．．\(\)（）\[\]【】]'), ' ')
        .toLowerCase();

    final cleanUser = userAnswer
        .replaceAll(RegExp(r'[；;。、,，．．\(\)（）\[\]【】]'), ' ')
        .toLowerCase();

    // Extract keywords (2+ character words)
    final keywords = cleanCorrect
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= 2)
        .toSet();

    if (keywords.isEmpty) {
      // If no keywords found, check if user provided any answer
      return cleanUser.trim().isNotEmpty;
    }

    // Count how many keywords the user included
    int matchedKeywords = 0;
    for (final keyword in keywords) {
      if (cleanUser.contains(keyword)) {
        matchedKeywords++;
      }
    }

    // Require at least 50% keyword match
    final matchRatio = matchedKeywords / keywords.length;
    return matchRatio >= 0.5;
  }
}

/// Submit Answer Parameters
class SubmitAnswerParams {
  final String questionId;
  final String userAnswer;
  final int timeSpent;

  const SubmitAnswerParams({
    required this.questionId,
    required this.userAnswer,
    required this.timeSpent,
  });
}

/// Submit Answer Result
class SubmitAnswerResult {
  final bool success;
  final bool? isCorrect;
  final int? wrongBookCount;
  final int? needsReviewCount;
  final String? error;

  const SubmitAnswerResult._({
    required this.success,
    this.isCorrect,
    this.wrongBookCount,
    this.needsReviewCount,
    this.error,
  });

  factory SubmitAnswerResult.success({
    required bool isCorrect,
    required int wrongBookCount,
    required int needsReviewCount,
  }) {
    return SubmitAnswerResult._(
      success: true,
      isCorrect: isCorrect,
      wrongBookCount: wrongBookCount,
      needsReviewCount: needsReviewCount,
    );
  }

  factory SubmitAnswerResult.error(String error) {
    return SubmitAnswerResult._(
      success: false,
      error: error,
    );
  }
}
