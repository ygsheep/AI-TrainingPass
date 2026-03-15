import '../entities/question.dart';
import '../entities/question_summary.dart';
import '../entities/question_filter.dart';
import '../entities/exam_statistics.dart';
import '../entities/category_statistics.dart';
import '../entities/source_statistics.dart';
import '../../data/models/exam_record.dart';
import '../../data/models/app_config.dart';
import '../../data/datasources/local/file_service_stub.dart';

/// Question Repository Interface
/// Domain layer interface for question operations
abstract class QuestionRepository {
  // ========== Question Bank Operations ==========

  /// Load all questions from local storage
  Future<List<Question>> loadQuestionBank();

  /// Save questions to local storage
  Future<void> saveQuestionBank(List<Question> questions);

  /// Get questions by category
  Future<List<Question>> getQuestionsByCategory(String category);

  /// Get questions by type
  Future<List<Question>> getQuestionsByType(String type);

  /// Get random questions
  Future<List<Question>> getRandomQuestions(int count);

  /// Get random questions from specific categories
  Future<List<Question>> getRandomQuestionsFromCategories(
    int count,
    List<String> categories,
  );

  /// Get random questions with filter and type restrictions
  Future<List<Question>> getRandomQuestionsWithFilter({
    required int count,
    QuestionFilter? filter,
    List<String>? types,
  });

  /// Get questions by source
  Future<List<Question>> getQuestionsBySources(List<String> sources);

  /// Get statistics for a specific source
  Future<SourceStatistics> getSourceStatistics(String source);

  /// Get question by ID
  Future<Question?> getQuestionById(String id);

  /// Get all categories
  Future<List<String>> getCategories();

  /// Get current question bank version
  Future<String?> getQuestionBankVersion();

  /// Update question bank version
  Future<void> updateQuestionBankVersion(String version);

  // ========== Question Summary Operations ==========

  /// Get question summaries with optional filter and pagination
  Future<List<QuestionSummary>> getQuestionSummaries({
    QuestionFilter? filter,
    int? limit,
    int? offset,
  });

  /// Get question count with optional filter
  Future<int> getQuestionCount({QuestionFilter? filter});

  /// Get statistics for a specific category
  Future<CategoryStatistics> getCategoryStatistics(String category);

  /// Search questions by query
  Future<List<QuestionSummary>> searchQuestions(
    String query, {
    int? offset,
    int? limit,
  });

  // ========== Answer Operations ==========

  /// Submit an answer
  Future<void> submitAnswer({
    required String questionId,
    required String userAnswer,
    required bool isCorrect,
    required int timeSpent,
  });

  /// Get answers for a specific question
  Future<List<dynamic>> getAnswersForQuestion(String questionId);

  // ========== Wrong Book Operations ==========

  /// Get all wrong questions
  Future<List<WrongQuestion>> getWrongQuestions();

  /// Get wrong questions that need review
  Future<List<WrongQuestion>> getWrongQuestionsForReview();

  /// Mark wrong question as mastered
  Future<void> markAsMastered(String wrongQuestionId);

  /// Add review attempt for wrong question
  Future<void> addReviewAttempt({
    required String wrongQuestionId,
    required bool wasCorrect,
  });

  /// Remove question from wrong book
  Future<void> removeWrongQuestion(String wrongQuestionId);

  // ========== File Operations ==========

  /// Import question bank from file
  Future<ImportResult> importQuestionBank(String filePath);

  /// Export question bank to file
  Future<String?> exportQuestionBank({
    required List<Question> questions,
    required String name,
    required String version,
    List<String>? categories,
    String? description,
  });

  /// Get list of imported question bank files
  Future<List<QuestionBankFile>> getImportedFiles();

  /// Delete a question bank file
  Future<bool> deleteQuestionBankFile(String filePath);

  // ========== Utility ==========

  /// Clear all user data
  Future<void> clearUserData();

  // ========== Exam Operations ==========

  /// Save exam record
  Future<void> saveExamRecord(ExamRecordModel record);

  /// Get exam history
  Future<List<ExamRecordModel>> getExamHistory();

  /// Get exam record by ID
  Future<ExamRecordModel?> getExamRecordById(String id);

  /// Delete exam record by ID
  Future<void> deleteExamRecord(String id);

  /// Get exam statistics
  Future<ExamStatistics> getExamStatistics();
}

/// Exam Repository Interface
/// Domain layer interface for exam operations
abstract class ExamRepository {
  /// Create a new exam configuration
  Future<void> createExamConfig(ExamConfigModel config);

  /// Get current exam config
  Future<ExamConfigModel?> getExamConfig();

  /// Save exam record
  Future<void> saveExamRecord(ExamRecordModel record);

  /// Get exam history
  Future<List<ExamRecordModel>> getExamHistory();

  /// Get exam record by ID
  Future<ExamRecordModel?> getExamRecordById(String id);

  /// Delete exam record by ID
  Future<void> deleteExamRecord(String id);

  /// Get exam statistics
  Future<ExamStatistics> getExamStatistics();
}

/// Config Repository Interface
/// Domain layer interface for configuration operations
abstract class ConfigRepository {
  /// Get app configuration
  Future<AppConfigModel?> getAppConfig();

  /// Save app configuration
  Future<void> saveAppConfig(AppConfigModel config);

  /// Get user settings
  Future<UserSettingsModel?> getUserSettings();

  /// Save user settings
  Future<void> saveUserSettings(UserSettingsModel settings);

  /// Get study progress
  Future<StudyProgressModel?> getStudyProgress();

  /// Update study progress
  Future<void> updateStudyProgress(StudyProgressModel progress);

  /// Increment study day count if first study today
  Future<void> incrementStudyDay();
}
