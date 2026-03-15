/// Application Configuration Constants
/// Contains magic numbers and configurable values for the app
class AppConfig {
  // ==================== Practice/Exam Configuration ====================

  /// Default question count for random practice
  static const int defaultPracticeQuestionCount = 20;

  /// Default question count for exams
  static const int defaultExamQuestionCount = 50;

  /// Default exam duration in minutes
  static const int defaultExamDurationMinutes = 60;

  /// Default passing score for exams (percentage)
  static const int defaultPassScore = 60;

  /// Default pass score for exam setup (alias for clarity)
  static const int defaultExamPassScore = 60;

  /// Default exam source (main question bank)
  static const String defaultExamSource = 'main';

  // ==================== Preloading Configuration ====================

  /// Number of questions to preload before and after current question
  static const int preloadQuestionCount = 3;

  /// Number of questions to load per batch in swipe mode
  static const int swipeBatchSize = 20;

  // ==================== Pagination Configuration ====================

  /// Default page size for paginated lists
  static const int defaultPageSize = 20;

  /// Maximum number of items to load in "load more" scenarios
  static const int loadMorePageSize = 20;

  /// Initial number of exam history records to load
  static const int initialHistoryPageSize = 5;

  /// Number of exam history records to load per batch
  static const int historyLoadMorePageSize = 5;

  // ==================== Thresholds ====================

  /// Warning threshold for countdown timer (10% remaining)
  static const double timerWarningThreshold = 0.1;

  /// Minimum keyword match ratio for essay answers (50%)
  static const double essayKeywordMatchThreshold = 0.5;

  /// Minimum word length for keyword extraction in essay answers
  static const int essayMinKeywordLength = 2;

  // ==================== Exam Review Configuration ====================

  /// Days to wait before reviewing based on review count (forgetting curve)
  static const Map<int, int> reviewIntervals = {
    0: 1,   // 1 day after first wrong attempt
    1: 3,   // 3 days after first review
    2: 7,   // 1 week after second review
    3: 14,  // 2 weeks after third review
  };

  /// Default interval for mastered questions (30 days)
  static const int masteredReviewInterval = 30;

  // ==================== Answer Separator ====================

  /// Separator for multiple choice answers
  static const String multipleChoiceAnswerSeparator = '|';
}
