import '../models/exam_record.dart';
import '../../domain/entities/exam_statistics.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/local/question_local_datasource.dart';

/// Exam Repository Implementation
class ExamRepositoryImpl implements ExamRepository {
  final QuestionLocalDatasource _localDatasource;

  ExamRepositoryImpl({
    required QuestionLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<void> createExamConfig(ExamConfigModel config) async {
    // In a real app, you might want to store this separately
    // For now, we'll just validate the config
    if (config.questionCount <= 0) {
      throw Exception('题目数量必须大于0');
    }
    if (config.duration <= 0) {
      throw Exception('考试时长必须大于0');
    }
    if (config.passScore < 0 || config.passScore > 100) {
      throw Exception('及格分必须在0-100之间');
    }
  }

  @override
  Future<ExamConfigModel?> getExamConfig() async {
    // Return default config for now
    return ExamConfigModel(
      name: '模拟考试',
      questionCount: 100,
      duration: 90,
      passScore: 60,
    );
  }

  @override
  Future<void> saveExamRecord(ExamRecordModel record) async {
    await _localDatasource.saveExamRecord(record);
  }

  @override
  Future<List<ExamRecordModel>> getExamHistory() async {
    return _localDatasource.getExamHistory();
  }

  @override
  Future<ExamRecordModel?> getExamRecordById(String id) async {
    return _localDatasource.getExamRecordById(id);
  }

  @override
  Future<void> deleteExamRecord(String id) async {
    await _localDatasource.deleteExamRecord(id);
  }

  @override
  Future<ExamStatistics> getExamStatistics() async {
    final history = await getExamHistory();

    if (history.isEmpty) {
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

    final totalExams = history.length;
    final passedExams = history.where((e) => e.passed).length;
    final totalQuestionsAttempted = history.fold<int>(
      0,
      (sum, record) => sum + record.totalCount,
    );
    final totalCorrectAnswers = history.fold<int>(
      0,
      (sum, record) => sum + record.correctCount,
    );
    final averageAccuracy = totalQuestionsAttempted > 0
        ? (totalCorrectAnswers / totalQuestionsAttempted) * 100
        : 0.0;
    final scores = history.map((e) => e.score).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final bestScore = scores.reduce((a, b) => a > b ? a : b);
    final worstScore = scores.reduce((a, b) => a < b ? a : b);

    // Calculate streaks
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    for (final record in history) {
      if (record.passed) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }
    currentStreak = tempStreak;

    // Calculate category stats
    final categoryStats = <String, CategoryStats>{};

    for (final record in history) {
      for (final answer in record.answers) {
        final question = _localDatasource.getQuestionById(answer.questionId);
        if (question != null) {
          final category = question.category;
          if (!categoryStats.containsKey(category)) {
            categoryStats[category] = CategoryStats(
              categoryId: category,
              categoryName: category,
              totalAttempts: 0,
              correctAnswers: 0,
              accuracy: 0,
              lastExamScore: 0,
            );
          }

          final stats = categoryStats[category]!;
          categoryStats[category] = CategoryStats(
            categoryId: stats.categoryId,
            categoryName: stats.categoryName,
            totalAttempts: stats.totalAttempts + 1,
            correctAnswers: stats.correctAnswers + (answer.isCorrect ? 1 : 0),
            accuracy: ((stats.correctAnswers + (answer.isCorrect ? 1 : 0)) /
                    (stats.totalAttempts + 1)) *
                100,
            lastExamScore: record.score,
          );
        }
      }
    }

    return ExamStatistics(
      totalExams: totalExams,
      passedExams: passedExams,
      totalQuestionsAttempted: totalQuestionsAttempted,
      totalCorrectAnswers: totalCorrectAnswers,
      averageAccuracy: averageAccuracy,
      averageScore: averageScore,
      bestScore: bestScore,
      worstScore: worstScore,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      categoryStats: categoryStats,
    );
  }
}
