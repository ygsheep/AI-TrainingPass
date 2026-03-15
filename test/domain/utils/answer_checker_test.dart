import 'package:flutter_test/flutter_test.dart';
import 'package:trainingpass/domain/entities/question.dart';
import 'package:trainingpass/domain/utils/answer_checker.dart';

void main() {
  group('AnswerChecker', () {
    // Single choice tests
    group('Single Choice Questions', () {
      late Question singleChoiceQuestion;

      setUp(() {
        singleChoiceQuestion = const Question(
          id: '1',
          source: 'main',
          category: '测试',
          type: 'single',
          question: '测试题目',
          options: ['选项A', '选项B', '选项C', '选项D'],
          answer: 'A',
        );
      });

      test('should return true for correct single choice answer', () {
        expect(AnswerChecker.checkAnswer(singleChoiceQuestion, 'A'), isTrue);
      });

      test('should return false for incorrect single choice answer', () {
        expect(AnswerChecker.checkAnswer(singleChoiceQuestion, 'B'), isFalse);
      });

      test('should handle case-sensitive single choice answers', () {
        expect(AnswerChecker.checkAnswer(singleChoiceQuestion, 'a'), isFalse);
      });
    });

    // Multiple choice tests
    group('Multiple Choice Questions', () {
      late Question multipleChoiceQuestion;

      setUp(() {
        multipleChoiceQuestion = const Question(
          id: '2',
          source: 'main',
          category: '测试',
          type: 'multiple',
          question: '多选题',
          options: ['选项A', '选项B', '选项C', '选项D'],
          answer: 'A|B|C',
        );
      });

      test('should return true for correct multiple choice answer', () {
        expect(AnswerChecker.checkAnswer(multipleChoiceQuestion, 'A|B|C'), isTrue);
      });

      test('should return true for correct answer in different order', () {
        expect(AnswerChecker.checkAnswer(multipleChoiceQuestion, 'C|A|B'), isTrue);
      });

      test('should return false for incomplete multiple choice answer', () {
        expect(AnswerChecker.checkAnswer(multipleChoiceQuestion, 'A|B'), isFalse);
      });

      test('should return false for incorrect multiple choice answer', () {
        expect(AnswerChecker.checkAnswer(multipleChoiceQuestion, 'A|B|D'), isFalse);
      });

      test('should handle whitespace in multiple choice answers', () {
        expect(AnswerChecker.checkAnswer(multipleChoiceQuestion, ' A | B | C '), isTrue);
      });
    });

    // Judge (true/false) tests
    group('Judge Questions', () {
      late Question judgeQuestion;

      setUp(() {
        judgeQuestion = const Question(
          id: '3',
          source: 'main',
          category: '测试',
          type: 'judge',
          question: '判断题',
          answer: '正确',
        );
      });

      test('should return true for correct judge answer', () {
        expect(AnswerChecker.checkAnswer(judgeQuestion, '正确'), isTrue);
      });

      test('should return false for incorrect judge answer', () {
        expect(AnswerChecker.checkAnswer(judgeQuestion, '错误'), isFalse);
      });

      test('should handle case-insensitive judge answers', () {
        expect(AnswerChecker.checkAnswer(judgeQuestion, '正确'), isTrue);
      });
    });

    // Essay tests
    group('Essay Questions', () {
      late Question essayQuestion;

      setUp(() {
        essayQuestion = const Question(
          id: '4',
          source: 'main',
          category: '测试',
          type: 'essay',
          question: '简答题',
          answer: '人工智能 机器学习 深度学习',
        );
      });

      test('should return true when keywords match threshold (50%)', () {
        expect(AnswerChecker.checkAnswer(essayQuestion, '人工智能和机器学习'), isTrue);
      });

      test('should return false when keywords below threshold', () {
        expect(AnswerChecker.checkAnswer(essayQuestion, '人工智能'), isFalse);
      });

      test('should return true for exact match', () {
        expect(AnswerChecker.checkAnswer(essayQuestion, '人工智能 机器学习 深度学习'), isTrue);
      });

      test('should handle empty answer gracefully', () {
        expect(AnswerChecker.checkAnswer(essayQuestion, ''), isFalse);
      });
    });

    // Edge cases
    group('Edge Cases', () {
      test('should return false for question with null answer', () {
        const question = Question(
          id: '5',
          source: 'main',
          category: '测试',
          type: 'single',
          question: '测试',
          answer: null,
        );
        expect(AnswerChecker.checkAnswer(question, 'A'), isFalse);
      });

      test('should return false for question with empty answer', () {
        const question = Question(
          id: '6',
          source: 'main',
          category: '测试',
          type: 'single',
          question: '测试',
          answer: '',
        );
        expect(AnswerChecker.checkAnswer(question, 'A'), isFalse);
      });

      test('should handle essay question with no keywords', () {
        const question = Question(
          id: '7',
          source: 'main',
          category: '测试',
          type: 'essay',
          question: '简答题',
          answer: 'a',
        );
        // Should pass if user provides any answer (since no 2+ char keywords exist)
        expect(AnswerChecker.checkAnswer(question, 'some answer'), isTrue);
      });
    });
  });
}
