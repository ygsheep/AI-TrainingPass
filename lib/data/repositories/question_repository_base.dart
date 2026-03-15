/// Question Repository Base
/// Contains all platform-independent functionality
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/user_answer.dart';
import '../models/wrong_question.dart';
import '../models/exam_record.dart';
import '../../domain/entities/question.dart' as domain;
import '../../domain/entities/question_summary.dart' as domain;
import '../../domain/entities/question_filter.dart';
import '../../domain/entities/exam_statistics.dart';
import '../../domain/entities/category_statistics.dart';
import '../../domain/entities/source_statistics.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/local/question_local_datasource.dart';
import '../../core/utils/app_logger.dart';

/// Question Repository Base Class
/// Contains all platform-independent functionality
abstract class QuestionRepositoryBase implements QuestionRepository {
  final QuestionLocalDatasource _localDatasource;
  final dynamic fileService; // Use dynamic to accommodate platform differences
  final Uuid _uuid;

  QuestionRepositoryBase({
    required QuestionLocalDatasource localDatasource,
    required this.fileService,
    Uuid? uuid,
  })  : _localDatasource = localDatasource,
        _uuid = uuid ?? const Uuid();

  // ========== Question Bank Operations ==========

  @override
  Future<List<domain.Question>> loadQuestionBank() async {
    final questions = _localDatasource.getQuestions();
    return questions.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<void> saveQuestionBank(List<domain.Question> questions) async {
    final models = questions.map((q) => _toModel(q)).toList();
    await _localDatasource.saveQuestions(models);
  }

  @override
  Future<List<domain.Question>> getQuestionsByCategory(String category) async {
    final questions = _localDatasource.getQuestionsByCategory(category);
    return questions.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<List<domain.Question>> getQuestionsByType(String type) async {
    final questions = _localDatasource.getQuestionsByType(type);
    return questions.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<List<domain.Question>> getRandomQuestions(int count) async {
    final allQuestions = _localDatasource.getQuestions();
    final shuffled = List<QuestionModel>.from(allQuestions)..shuffle();
    final selected = shuffled.take(count).toList();
    return selected.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<List<domain.Question>> getRandomQuestionsFromCategories(
    int count,
    List<String> categories,
  ) async {
    final allQuestions = _localDatasource.getQuestions()
        .where((q) => q.category.any((c) => categories.contains(c)))
        .toList();
    final shuffled = allQuestions..shuffle();
    final selected = shuffled.take(count).toList();
    return selected.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<List<domain.Question>> getRandomQuestionsWithFilter({
    required int count,
    QuestionFilter? filter,
    List<String>? types,
  }) async {
    // 获取所有题目
    final allQuestions = _localDatasource.getQuestions();

    // 应用过滤条件
    Iterable<QuestionModel> filtered = allQuestions;

    if (filter != null) {
      filtered = allQuestions.where((q) {
        // Category filter: check if question has any of the filtered categories
        if (filter.category != null && filter.category != 'all') {
          if (!q.category.contains(filter.category!)) {
            return false;
          }
        }
        if (filter.type != null && q.type != filter.type) {
          return false;
        }
        if (filter.difficulty != null && q.difficulty != filter.difficulty) {
          return false;
        }
        return true;
      });
    }

    // 如果指定了题型列表，过滤出这些题型
    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((q) => types.contains(q.type));
    }

    // 转换为列表并随机打乱
    final shuffled = filtered.toList()..shuffle();

    // 取指定数量
    final selected = shuffled.take(count).toList();

    return selected.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<List<domain.Question>> getQuestionsBySources(List<String> sources) async {
    final allQuestions = _localDatasource.getQuestions();
    final filtered = allQuestions.where((q) => sources.contains(q.source));
    return filtered.map((q) => _toDomainEntity(q)).toList();
  }

  @override
  Future<SourceStatistics> getSourceStatistics(String source) async {
    final allQuestions = _localDatasource.getQuestions();

    // Filter by source
    final sourceQuestions = allQuestions.where((q) => q.source == source).toList();
    final totalCount = sourceQuestions.length;

    // Calculate type distribution
    final typeDistribution = <String, int>{};
    for (final q in sourceQuestions) {
      typeDistribution[q.type] = (typeDistribution[q.type] ?? 0) + 1;
    }

    // Get exam history for this source
    final history = await _localDatasource.getExamHistory();
    final sourceHistory = history.where((record) {
      // Check if exam questions are from this source
      for (final questionId in record.questionIds) {
        final question = _localDatasource.getQuestionById(questionId);
        if (question != null && question.source == source) {
          return true;
        }
      }
      return false;
    }).toList();

    // Calculate exam history stats
    ExamHistoryStats? historyStats;
    if (sourceHistory.isNotEmpty) {
      final scores = sourceHistory.map((e) => e.score).toList();
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;
      final highestScore = scores.reduce((a, b) => a > b ? a : b);
      final passedCount = sourceHistory.where((e) => e.passed).length;
      final passRate = passedCount / sourceHistory.length;

      historyStats = ExamHistoryStats(
        averageScore: averageScore,
        highestScore: highestScore,
        passRate: passRate,
        examCount: sourceHistory.length,
      );
    }

    // Get display name for source
    final displayName = _getSourceDisplayName(source);

    return SourceStatistics(
      source: source,
      displayName: displayName,
      totalCount: totalCount,
      typeDistribution: typeDistribution,
      history: historyStats,
    );
  }

  /// Get display name for source
  String _getSourceDisplayName(String source) {
    // Map source codes to display names
    const displayNames = {
      'main': '理论题试题',
      'mock': '理论题模拟题',
      'review': '人工智能训练师 复习题',
    };
    return displayNames[source] ?? source;
  }

  @override
  Future<domain.Question?> getQuestionById(String id) async {
    final question = _localDatasource.getQuestionById(id);
    return question != null ? _toDomainEntity(question) : null;
  }

  @override
  Future<List<String>> getCategories() async {
    // 动态获取所有分类
    final questions = _localDatasource.getQuestions();
    // 展开所有分类数组并去重
    final categories = <String>{};
    for (final q in questions) {
      categories.addAll(q.category);
    }
    final categoryList = categories.toList();
    categoryList.sort((a, b) => a.compareTo(b));
    return ['all', ...categoryList];
  }

  @override
  Future<String?> getQuestionBankVersion() async {
    return _localDatasource.getQuestionBankVersion();
  }

  @override
  Future<void> updateQuestionBankVersion(String version) async {
    await _localDatasource.updateQuestionBankVersion(version);
  }

  // ========== Question Summary Operations ==========

  @override
  Future<List<domain.QuestionSummary>> getQuestionSummaries({
    QuestionFilter? filter,
    int? limit,
    int? offset,
  }) async {
    var allQuestions = _localDatasource.getQuestions();

    print('🔍 Total questions in bank: ${allQuestions.length}');

    // Show type distribution
    final typeCounts = <String, int>{};
    for (final q in allQuestions) {
      typeCounts[q.type] = (typeCounts[q.type] ?? 0) + 1;
    }
    print('🔍 Type distribution: $typeCounts');

    final wrongQuestions = _localDatasource.getWrongQuestions();
    final wrongQuestionIds = wrongQuestions.map((w) => w.questionId).toSet();

    Iterable<QuestionModel> filtered = allQuestions;

    if (filter != null) {
      // Debug: Show filter details and sample question data
      if (allQuestions.isNotEmpty) {
        final sampleQ = allQuestions.first;
        print('🔍 Filter: type=${filter.type}, category=${filter.category}');
        print('🔍 Sample question: type=${sampleQ.type}, originalType=${sampleQ.originalType}, category=${sampleQ.category}');
      }

      filtered = allQuestions.where((q) {
        if (filter.category != null && filter.category != 'all' && !q.category.contains(filter.category!)) return false;
        if (filter.type != null && q.type != filter.type) {
          return false;
        }
        if (filter.difficulty != null && q.difficulty != filter.difficulty) return false;
        if (filter.inWrongBook == true && !wrongQuestionIds.contains(q.id)) return false;
        if (filter.searchKeyword != null) {
          final keyword = filter.searchKeyword!.toLowerCase();
          if (!q.question.toLowerCase().contains(keyword)) return false;
        }

        // Handle answerStatus filter
        if (filter.answerStatus != null) {
          final answers = _localDatasource.getAnswersForQuestion(q.id);
          final hasAnswered = answers.isNotEmpty;

          switch (filter.answerStatus!) {
            case AnswerStatus.notAnswered:
              if (hasAnswered) return false;
              break;
            case AnswerStatus.correct:
              if (!hasAnswered || !answers.any((a) => a.isCorrect)) return false;
              break;
            case AnswerStatus.wrong:
              if (!hasAnswered || answers.any((a) => a.isCorrect)) return false;
              break;
            case AnswerStatus.all:
              break; // Show all
          }
        }

        return true;
      });
    }

    print('🔍 Filtered result: ${filtered.length} questions');

    // Debug: Show first few filtered questions with ID and type
    final filteredList = filtered.toList();
    if (filteredList.isNotEmpty) {
      print('🔍 Filtered questions (first 5):');
      for (int i = 0; i < filteredList.length && i < 5; i++) {
        final q = filteredList[i];
        print('  [$i] id=${q.id}, type=${q.type}, originalType=${q.originalType}');
      }
    }

    // Apply pagination
    var result = filteredList;
    if (offset != null && offset > 0) {
      if (offset >= result.length) {
        return [];
      }
      result = result.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    // Convert to summaries
    final summaries = result.map((q) => _toDomainSummary(q, wrongQuestionIds)).toList();


    return summaries;
  }

  @override
  Future<int> getQuestionCount({QuestionFilter? filter}) async {
    final summaries = await getQuestionSummaries(filter: filter);
    return summaries.length;
  }

  @override
  Future<CategoryStatistics> getCategoryStatistics(String category) async {
    final allQuestions = _localDatasource.getQuestions();

    // Filter by category
    final categoryQuestions = category == 'all'
        ? allQuestions
        : allQuestions.where((q) => q.category.contains(category)).toList();

    final totalCount = categoryQuestions.length;

    // Get all answers to calculate statistics
    final allAnswers = _localDatasource.getUserAnswers();
    final questionIds = categoryQuestions.map((q) => q.id).toSet();

    // Count answered and correct
    int answeredCount = 0;
    int correctCount = 0;

    for (final questionId in questionIds) {
      final answers = allAnswers.where((a) => a.questionId == questionId);
      if (answers.isNotEmpty) {
        answeredCount++;
        if (answers.any((a) => a.isCorrect)) {
          correctCount++;
        }
      }
    }

    // Get display name for category
    final categoryName = _getCategoryDisplayName(category);

    return CategoryStatistics(
      categoryId: category,
      categoryName: categoryName,
      totalCount: totalCount,
      answeredCount: answeredCount,
      correctCount: correctCount,
    );
  }

  /// Get display name for category
  String _getCategoryDisplayName(String category) {
    if (category == 'all') return '全部';
    // category 直接存储中文名，无需转换
    return category;
  }

  @override
  Future<List<domain.QuestionSummary>> searchQuestions(
    String query, {
    int? offset,
    int? limit,
  }) async {
    final allQuestions = _localDatasource.getQuestions();
    final wrongQuestions = _localDatasource.getWrongQuestions();
    final wrongQuestionIds = wrongQuestions.map((w) => w.questionId).toSet();
    final lowerQuery = query.toLowerCase();

    var filtered = allQuestions.where((q) =>
        q.id.toLowerCase().contains(lowerQuery) ||
        q.question.toLowerCase().contains(lowerQuery) ||
        q.category.any((c) => c.toLowerCase().contains(lowerQuery)));

    // Apply pagination
    var result = filtered.toList();
    if (offset != null && offset > 0) {
      if (offset >= result.length) {
        return [];
      }
      result = result.skip(offset).toList();
    }
    if (limit != null && limit > 0) {
      result = result.take(limit).toList();
    }

    return result.map((q) => _toDomainSummary(q, wrongQuestionIds)).toList();
  }

  // ========== Answer Operations ==========

  @override
  Future<void> submitAnswer({
    required String questionId,
    required String userAnswer,
    required bool isCorrect,
    required int timeSpent,
  }) async {
    final answer = UserAnswerModel(
      id: _uuid.v4(),
      questionId: questionId,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      answeredAt: DateTime.now(),
    );

    await _localDatasource.saveUserAnswer(answer);

    // If wrong, add to wrong book
    if (!isCorrect) {
      final question = _localDatasource.getQuestionById(questionId);
      if (question != null) {
        final existingWrongQuestions = _localDatasource.getWrongQuestions();
        final existing = existingWrongQuestions
            .where((wq) => wq.questionId == questionId)
            .toList();

        final wrongAnswers = existing.isNotEmpty
            ? [...existing.first.wrongAnswers, answer]
            : [answer];

        final wrongQuestion = WrongQuestionModel(
          id: _uuid.v4(),
          questionId: questionId,
          question: question,  // This will be converted to JSON in addWrongQuestion
          wrongAnswers: wrongAnswers,
          lastReviewAt: DateTime.now(),
        );

        await _localDatasource.addWrongQuestion(wrongQuestion);
      }
    }
  }

  @override
  Future<List<UserAnswerModel>> getAnswersForQuestion(String questionId) async {
    return _localDatasource.getAnswersForQuestion(questionId);
  }

  // ========== Wrong Book Operations ==========

  @override
  Future<List<domain.WrongQuestion>> getWrongQuestions() async {
    final wrongQuestions = _localDatasource.getWrongQuestions();
    return wrongQuestions.map((wq) => _toDomainWrongQuestion(wq)).toList();
  }

  @override
  Future<List<domain.WrongQuestion>> getWrongQuestionsForReview() async {
    final wrongQuestions = _localDatasource.getWrongQuestionsForReview();
    return wrongQuestions.map((wq) => _toDomainWrongQuestion(wq)).toList();
  }

  @override
  Future<void> markAsMastered(String wrongQuestionId) async {
    AppLogger.debug('🎯 Repository.markAsMastered: id=$wrongQuestionId');
    final wrongQuestions = _localDatasource.getWrongQuestions();
    AppLogger.debug('🎯 Found ${wrongQuestions.length} wrong questions');
    AppLogger.debug('🎯 Looking for id: $wrongQuestionId');
    AppLogger.debug('🎯 Available ids: ${wrongQuestions.map((wq) => wq.id).take(5).toList()}...');

    // Use WrongQuestion.id to match
    final wrongQuestion = wrongQuestions.firstWhere(
      (wq) => wq.id == wrongQuestionId,
      orElse: () => throw Exception('Wrong question not found'),
    );
    AppLogger.debug('🎯 Found question: mastered=${wrongQuestion.mastered}, recordId=${wrongQuestion.id}');

    final updated = wrongQuestion.markAsMastered();
    AppLogger.debug('🎯 Updated question: mastered=${updated.mastered}');

    await _localDatasource.updateWrongQuestion(updated);
    AppLogger.debug('🎯 Saved to datasource');

    // Verify save by reading back
    final savedQuestions = _localDatasource.getWrongQuestions();
    final savedQuestion = savedQuestions.firstWhere(
      (wq) => wq.id == wrongQuestionId,
      orElse: () => wrongQuestion,
    );
    AppLogger.debug('🎯 Verified saved: mastered=${savedQuestion.mastered}');
  }

  @override
  Future<void> addReviewAttempt({
    required String wrongQuestionId,
    required bool wasCorrect,
  }) async {
    // Use WrongQuestion.id to match
    final wrongQuestions = _localDatasource.getWrongQuestions();
    final wrongQuestion = wrongQuestions.firstWhere(
      (wq) => wq.id == wrongQuestionId,
      orElse: () => throw Exception('Wrong question not found'),
    );

    final updated = wrongQuestion.addReview(wasCorrect: wasCorrect);
    await _localDatasource.updateWrongQuestion(updated);
  }

  @override
  Future<void> removeWrongQuestion(String wrongQuestionId) async {
    await _localDatasource.removeWrongQuestion(wrongQuestionId);
  }

  // ========== Utility ==========

  @override
  Future<void> clearUserData() async {
    await _localDatasource.clearUserData();
  }

  // ========== Exam Operations ==========

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
          // Add stats for each category the question belongs to
          for (final category in question.category) {
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

  // ========== Domain Entity Mapping ==========

  domain.Question _toDomainEntity(QuestionModel model) {
    return domain.Question(
      id: model.id,
      source: model.source,
      category: model.category,
      type: model.type,
      question: model.question,
      options: model.options?.map((o) => o.text).toList(),
      answer: model.answer,
      explanation: model.explanation,
      difficulty: model.difficulty,
      imageUrl: model.imageUrl,
      originalType: model.originalType,
      originalSource: model.originalSource,
    );
  }

  QuestionModel _toModel(domain.Question entity) {
    return QuestionModel(
      id: entity.id,
      source: entity.source,
      category: entity.category,
      type: entity.type,
      question: entity.question,
      options: entity.options?.asMap().entries.map((entry) {
        final key = String.fromCharCode(65 + entry.key); // A, B, C, D
        return QuestionOption(key: key, text: entry.value);
      }).toList(),
      answer: entity.answer,
      explanation: entity.explanation,
      difficulty: entity.difficulty,
      imageUrl: entity.imageUrl,
      originalType: entity.originalType,
      originalSource: entity.originalSource,
    );
  }

  domain.WrongQuestion _toDomainWrongQuestion(WrongQuestionModel model) {
    return domain.WrongQuestion(
      id: model.id,
      questionId: model.questionId,
      question: _toDomainEntity(model.question),
      wrongAnswers: model.wrongAnswers,
      mastered: model.mastered,
      reviewCount: model.reviewCount,
      lastReviewAt: model.lastReviewAt,
    );
  }

  domain.QuestionSummary _toDomainSummary(QuestionModel model, Set<String> wrongQuestionIds) {
    // Get answer status from local datasource
    final answers = _localDatasource.getAnswersForQuestion(model.id);
    final hasAnswered = answers.isNotEmpty;
    final isCorrect = hasAnswered && answers.any((a) => a.isCorrect);
    final wrongCount = answers.where((a) => !a.isCorrect).length;

    // Get primary category (first one)
    final primaryCategory = model.category.isNotEmpty ? model.category.first : '未分类';

    return domain.QuestionSummary(
      id: model.id,
      category: primaryCategory,
      type: model.type,
      title: model.question.length > 50
          ? '${model.question.substring(0, 50)}...'
          : model.question,
      difficulty: model.difficulty,
      hasAnswered: hasAnswered,
      isCorrect: isCorrect,
      wrongCount: wrongCount,
      inWrongBook: wrongQuestionIds.contains(model.id),
    );
  }
}
