/// Hive Box Names and Storage Keys
class StorageKeys {
  // Hive Box Names
  static const String userDataBox = 'user_data';
  static const String questionBankBox = 'question_bank';
  static const String appConfigBox = 'app_config';

  // User Data Keys
  static const String userAnswers = 'user_answers';
  static const String studyProgress = 'study_progress';
  static const String examHistory = 'exam_history';
  static const String wrongQuestions = 'wrong_questions';
  static const String practiceProgress = 'practice_progress';

  // Question Bank Keys
  static const String questions = 'questions';
  static const String categories = 'categories';
  static const String version = 'version';
  static const String lastUpdated = 'last_updated';

  // App Config Keys
  static const String appConfig = 'app_config';
  static const String userSettings = 'user_settings';
}

/// Hive Type IDs
/// Used for registering adapters
class HiveTypeIds {
  static const int questionModelId = 0;
  static const int optionModelId = 1;
  static const int userAnswerModelId = 2;
  static const int wrongQuestionModelId = 3;
  static const int examRecordModelId = 4;
  static const int examConfigModelId = 5;
  static const int appConfigModelId = 6;
  static const int userSettingsModelId = 7;
  static const int studyProgressModelId = 8;
}
