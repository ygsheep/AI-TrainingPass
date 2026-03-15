import '../entities/question.dart';

/// Answer Checker Utility
/// Provides centralized answer validation logic
class AnswerChecker {
  const AnswerChecker._();

  /// Check if the user's answer is correct for the given question
  static bool checkAnswer(Question question, String userAnswer) {
    if (question.answer == null || question.answer!.isEmpty) {
      return false;
    }

    // Essay type: keyword matching
    if (question.isEssay) {
      return _checkEssayAnswer(question.answer!, userAnswer);
    }

    // Multiple choice: compare sorted answer lists (pipe-separated)
    if (question.isMultipleChoice) {
      return _checkMultipleChoiceAnswer(question.answer!, userAnswer);
    }

    // Judge: case-insensitive comparison
    if (question.isJudge) {
      return userAnswer.trim().toLowerCase() ==
          question.answer!.trim().toLowerCase();
    }

    // Single choice, fill: direct comparison
    return userAnswer.trim() == question.answer!.trim();
  }

  /// Check multiple choice answer (pipe-separated values)
  static bool _checkMultipleChoiceAnswer(String correctAnswer, String userAnswer) {
    final correctAnswers = correctAnswer.split('|')
      .map((s) => s.trim())
      .toList()
      ..sort();
    final userAnswers = userAnswer.split('|')
      .map((s) => s.trim())
      .toList()
      ..sort();

    if (correctAnswers.length != userAnswers.length) {
      return false;
    }

    // Use set comparison for order-independent matching
    final userSet = userAnswers.toSet();
    return correctAnswers.every((a) => userSet.contains(a));
  }

  /// Check essay answer using keyword matching
  /// Returns true if user answer contains sufficient keywords (>= 50% match)
  static bool _checkEssayAnswer(String correctAnswer, String userAnswer) {
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
