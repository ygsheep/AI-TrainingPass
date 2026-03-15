import 'package:flutter/foundation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/question.dart';
import '../../../data/models/user_answer.dart';
import '../../../data/models/wrong_question.dart';
import '../../../data/models/exam_record.dart';
import '../../../data/models/app_config.dart';
import '../../../data/models/practice_progress.dart';
import '../../../core/constants/storage_keys.dart';
import 'hive_service.dart';

/// Question Local Datasource
/// Manages local storage of questions, answers, and exam records
class QuestionLocalDatasource {
  final HiveService _hiveService;

  QuestionLocalDatasource({
    required HiveService hiveService,
  }) : _hiveService = hiveService;

  /// Deep convert dynamic/LinkedMap to proper Map<String, dynamic>
  /// This is needed because Hive on web returns LinkedMap<dynamic, dynamic>
  /// which cannot be directly cast to Map<String, dynamic>
  static Map<String, dynamic> _deepConvertMap(dynamic source) {
    if (source == null) return {};
    if (source is! Map) return {};

    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map) {
        result[key] = _deepConvertMap(value);
      } else if (value is List) {
        result[key] = _deepConvertList(value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  /// Deep convert List with potential nested maps
  static List<dynamic> _deepConvertList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      }
      return item;
    }).toList();
  }

  // ========== Question Bank ==========

  /// Get all questions from local storage
  List<QuestionModel> getQuestions() {
    final questionsJson = _hiveService.getQuestionBankData(
      StorageKeys.questions,
    );
    if (questionsJson == null) return [];

    final list = questionsJson as List;

    return list
        .map((e) => QuestionModel.fromNewJson(_deepConvertMap(e)))
        .toList();
  }

  /// Save questions to local storage
  Future<void> saveQuestions(List<QuestionModel> questions) async {
    final questionsJson = questions.map((q) => q.toJson()).toList();
    await _hiveService.putQuestionBankData(
      StorageKeys.questions,
      questionsJson,
    );
  }

  /// Get question by ID
  QuestionModel? getQuestionById(String id) {
    final questions = getQuestions();
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get questions by category
  List<QuestionModel> getQuestionsByCategory(String category) {
    final questions = getQuestions();
    return questions.where((q) => q.category.contains(category)).toList();
  }

  /// Get questions by type
  List<QuestionModel> getQuestionsByType(String type) {
    final questions = getQuestions();
    return questions.where((q) => q.type == type).toList();
  }

  /// Get all categories
  List<String> getCategories() {
    final categoriesJson = _hiveService.getQuestionBankData(
      StorageKeys.categories,
    );
    if (categoriesJson == null) {
      // Extract from questions if not cached
      final questions = getQuestions();
      // Expand all category arrays and deduplicate
      final categorySet = <String>{};
      for (final q in questions) {
        categorySet.addAll(q.category);
      }
      final categories = categorySet.toList();
      _cacheCategories(categories);
      return categories;
    }
    return (categoriesJson as List).map((e) => e as String).toList();
  }

  /// Cache categories for quick access
  Future<void> _cacheCategories(List<String> categories) async {
    await _hiveService.putQuestionBankData(
      StorageKeys.categories,
      categories,
    );
  }

  /// Get question bank version
  String? getQuestionBankVersion() {
    return _hiveService.getQuestionBankData<String>(
      StorageKeys.version,
    );
  }

  /// Update question bank version
  Future<void> updateQuestionBankVersion(String version) async {
    await _hiveService.putQuestionBankData(
      StorageKeys.version,
      version,
    );
    await _hiveService.putQuestionBankData(
      StorageKeys.lastUpdated,
      DateTime.now().toIso8601String(),
    );
  }

  // ========== User Answers ==========

  /// Get all user answers
  List<UserAnswerModel> getUserAnswers() {
    final answersJson = _hiveService.getUserData(
      StorageKeys.userAnswers,
    );
    if (answersJson == null) return [];

    return (answersJson as List)
        .map((e) => UserAnswerModel.fromJson(_deepConvertMap(e)))
        .toList();
  }

  /// Save user answer
  Future<void> saveUserAnswer(UserAnswerModel answer) async {
    final answers = getUserAnswers();
    answers.add(answer);
    final answersJson = answers.map((a) => a.toJson()).toList();
    await _hiveService.putUserData(
      StorageKeys.userAnswers,
      answersJson,
    );
  }

  /// Get user answers for a specific question
  List<UserAnswerModel> getAnswersForQuestion(String questionId) {
    final answers = getUserAnswers();
    return answers.where((a) => a.questionId == questionId).toList();
  }

  // ========== Wrong Questions ==========

  /// Get all wrong questions
  List<WrongQuestionModel> getWrongQuestions() {
    final wrongJson = _hiveService.getUserData(
      StorageKeys.wrongQuestions,
    );
    if (wrongJson == null) {
      AppLogger.debug('📚 Wrong questions: None found (null data)');
      return [];
    }

    final questions = (wrongJson as List)
        .map((e) => WrongQuestionModel.fromJson(_deepConvertMap(e)))
        .toList();
    return questions;
  }

  /// Add wrong question
  Future<void> addWrongQuestion(WrongQuestionModel wrongQuestion) async {
    final wrongQuestions = getWrongQuestions();

    // Remove existing if present
    wrongQuestions.removeWhere((wq) => wq.questionId == wrongQuestion.questionId);

    // Add new entry
    wrongQuestions.add(wrongQuestion);

    // Convert to JSON - this will also convert nested QuestionModel
    final wrongJson = wrongQuestions.map((w) => w.toJson()).toList();

    await _hiveService.putUserData(
      StorageKeys.wrongQuestions,
      wrongJson,
    );
  }

  /// Update wrong question (e.g., mark as mastered)
  Future<void> updateWrongQuestion(WrongQuestionModel wrongQuestion) async {
    AppLogger.debug('🎯 Datasource.updateWrongQuestion: id=${wrongQuestion.id}, mastered=${wrongQuestion.mastered}');
    final wrongQuestions = getWrongQuestions();
    AppLogger.debug('🎯 Current questions count: ${wrongQuestions.length}');
    AppLogger.debug('🎯 Question IDs: ${wrongQuestions.map((wq) => wq.id).take(5).toList()}...');

    final index = wrongQuestions.indexWhere((wq) => wq.id == wrongQuestion.id);
    AppLogger.debug('🎯 Found at index: $index');

    if (index != -1) {
      final old = wrongQuestions[index];
      AppLogger.debug('🎯 Old mastered: ${old.mastered} -> New mastered: ${wrongQuestion.mastered}');

      wrongQuestions[index] = wrongQuestion;
      final wrongJson = wrongQuestions.map((w) => w.toJson()).toList();
      await _hiveService.putUserData(
        StorageKeys.wrongQuestions,
        wrongJson,
      );
      AppLogger.debug('🎯 Saved to Hive');
    } else {
      AppLogger.debug('❌ Question not found in list!');
      throw Exception('Wrong question not found: ${wrongQuestion.id}');
    }
  }

  /// Remove wrong question
  Future<void> removeWrongQuestion(String wrongQuestionId) async {
    final wrongQuestions = getWrongQuestions();
    wrongQuestions.removeWhere((wq) => wq.id == wrongQuestionId);

    final wrongJson = wrongQuestions.map((w) => w.toJson()).toList();
    await _hiveService.putUserData(
      StorageKeys.wrongQuestions,
      wrongJson,
    );
  }

  /// Get wrong questions that need review
  List<WrongQuestionModel> getWrongQuestionsForReview() {
    final wrongQuestions = getWrongQuestions();
    return wrongQuestions.where((wq) => wq.needsReview()).toList();
  }

  // ========== Exam History ==========

  /// Get all exam records
  List<ExamRecordModel> getExamHistory() {
    final historyJson = _hiveService.getUserData(
      StorageKeys.examHistory,
    );
    if (historyJson == null) return [];

    return (historyJson as List)
        .map((e) => ExamRecordModel.fromJson(_deepConvertMap(e)))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first
  }

  /// Save exam record
  Future<void> saveExamRecord(ExamRecordModel record) async {
    final history = getExamHistory();
    history.add(record);

    // Keep only last 50 records
    if (history.length > 50) {
      history.removeRange(0, history.length - 50);
    }

    final historyJson = history.map((r) => r.toJson()).toList();
    await _hiveService.putUserData(
      StorageKeys.examHistory,
      historyJson,
    );
  }

  /// Get exam record by ID
  ExamRecordModel? getExamRecordById(String id) {
    final history = getExamHistory();
    try {
      return history.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Delete exam record by ID
  Future<void> deleteExamRecord(String id) async {
    final history = getExamHistory();
    history.removeWhere((r) => r.id == id);

    final historyJson = history.map((r) => r.toJson()).toList();
    await _hiveService.putUserData(
      StorageKeys.examHistory,
      historyJson,
    );
  }

  // ========== App Configuration ==========

  /// Get app configuration
  AppConfigModel? getAppConfig() {
    final configJson = _hiveService.getAppConfigData(
      StorageKeys.appConfig,
    );
    if (configJson == null) return null;

    return AppConfigModel.fromJson(_deepConvertMap(configJson));
  }

  /// Save app configuration
  Future<void> saveAppConfig(AppConfigModel config) async {
    await _hiveService.putAppConfigData(
      StorageKeys.appConfig,
      config.toJson(),
    );
  }

  /// Get user settings
  UserSettingsModel? getUserSettings() {
    final settingsJson = _hiveService.getAppConfigData(
      StorageKeys.userSettings,
    );
    if (settingsJson == null) return null;

    return UserSettingsModel.fromJson(_deepConvertMap(settingsJson));
  }

  /// Save user settings
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _hiveService.putAppConfigData(
      StorageKeys.userSettings,
      settings.toJson(),
    );
  }

  /// Get study progress
  StudyProgressModel? getStudyProgress() {
    final progressJson = _hiveService.getUserData(
      StorageKeys.studyProgress,
    );
    if (progressJson == null) return null;

    return StudyProgressModel.fromJson(_deepConvertMap(progressJson));
  }

  /// Save study progress
  Future<void> saveStudyProgress(StudyProgressModel progress) async {
    await _hiveService.putUserData(
      StorageKeys.studyProgress,
      progress.toJson(),
    );
  }

  // ========== Practice Progress ==========

  /// Get practice progress for a specific category
  PracticeProgressModel? getPracticeProgress(String category) {
    final key = '${StorageKeys.practiceProgress}_$category';
    final progressJson = _hiveService.getUserData(key);
    if (progressJson == null) return null;

    return PracticeProgressModel.fromJson(_deepConvertMap(progressJson));
  }

  /// Save practice progress for a specific category
  Future<void> savePracticeProgress(PracticeProgressModel progress) async {
    final key = '${StorageKeys.practiceProgress}_${progress.category}';
    await _hiveService.putUserData(
      key,
      progress.toJson(),
    );
  }

  /// Clear practice progress for a specific category
  Future<void> clearPracticeProgress(String category) async {
    final key = '${StorageKeys.practiceProgress}_$category';
    await _hiveService.userDataBox.delete(key);
  }

  // ========== Utility ==========

  /// Clear all user data (keep questions)
  Future<void> clearUserData() async {
    await _hiveService.userDataBox.clear();
  }

  /// Clear all data including questions
  Future<void> clearAllData() async {
    await _hiveService.clearAll();
  }
}
