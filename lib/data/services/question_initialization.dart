import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/question.dart';
import '../datasources/local/hive_service.dart';
import '../datasources/local/question_local_datasource.dart';

/// Question Bank Initialization Service
/// Handles loading default questions from assets
class QuestionInitialization {
  static const String _assetPath = 'assets/data/questions.json';

  /// Load default questions from assets and save to local storage
  /// Supports both old (array) and new (meta + questions) JSON formats
  static Future<void> initializeDefaultQuestions() async {
    try {
      // Load JSON from assets
      final String jsonString = await rootBundle.loadString(_assetPath);
      final dynamic jsonData = jsonDecode(jsonString);

      // Parse JSON - support both new format (with _meta) and old format (direct array)
      List<dynamic> jsonList;
      Map<String, dynamic>? metadata;

      if (jsonData is Map && jsonData.containsKey('_meta')) {
        // New format: { "_meta": {...}, "questions": [...] }
        final dataMap = jsonData as Map<String, dynamic>;
        metadata = dataMap['_meta'] as Map<String, dynamic>?;
        jsonList = dataMap['questions'] as List<dynamic>;

        // Log metadata info
        if (metadata != null) {
          AppLogger.debug('📦 Question Bank Metadata:');
          AppLogger.debug('   Format: ${metadata['format']}');
          AppLogger.debug('   Version: ${metadata['format_version']}');
          AppLogger.debug('   Updated: ${metadata['updated_at']}');
          AppLogger.debug('   Total Questions: ${metadata['total_questions']}');
          AppLogger.debug('   Categories: ${metadata['categories']}');
        }
      } else if (jsonData is List) {
        // Old format: direct array of questions
        jsonList = jsonData as List<dynamic>;
        AppLogger.debug('📦 Loaded OLD format (direct array, no metadata)');
      } else {
        throw FormatException('Invalid JSON format: expected Map with _meta or List');
      }

      // Convert all questions using fromNewJson (supports both Chinese type names and English codes)
      final questions = jsonList.map((json) {
        return QuestionModel.fromNewJson(json as Map<String, dynamic>);
      }).toList();

      AppLogger.debug('✅ Parsed ${questions.length} questions');

      // Save to local storage
      final hiveService = HiveService();
      await hiveService.initialize();

      final datasource = QuestionLocalDatasource(hiveService: hiveService);
      await datasource.saveQuestions(questions);

      // Verify questions were saved correctly (important for all platforms)
      // Retry verification if initial read returns 0 (async write issue)
      int verificationAttempts = 0;
      List<QuestionModel> savedQuestions;

      do {
        savedQuestions = datasource.getQuestions();
        verificationAttempts++;

        if (savedQuestions.isEmpty) {
          AppLogger.debug('📝 Verification attempt $verificationAttempts: No questions yet, waiting...');
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } while (savedQuestions.isEmpty && verificationAttempts < 10);

      AppLogger.debug('📝 Verification: ${savedQuestions.length} questions saved (after $verificationAttempts attempts)');

      if (savedQuestions.length != questions.length) {
        AppLogger.debug('⚠️ Warning: Saved ${savedQuestions.length} but expected ${questions.length} questions');
      }

      // Update question bank version (use metadata version if available, otherwise default)
      final version = metadata?['format_version']?.toString() ?? '1.0.0';
      await datasource.updateQuestionBankVersion(version);

      // Ensure data is persisted before returning
      // For all platforms (IO and Web), add delay to ensure storage operations complete
      // Web: IndexedDB operations are async
      // IO: File system operations may need time to flush
      await Future.delayed(const Duration(milliseconds: 300));

      AppLogger.debug('✅ Initialized ${questions.length} questions from assets (version $version)');
    } catch (e) {
      AppLogger.debug('❌ Error initializing questions: $e');
      rethrow;
    }
  }

  /// Check if questions are already loaded
  static Future<bool> hasQuestions() async {
    try {
      final hiveService = HiveService();
      await hiveService.initialize();

      final datasource = QuestionLocalDatasource(hiveService: hiveService);
      final questions = datasource.getQuestions();

      if (questions.isEmpty) return false;

      // Check if questions need migration (old type format)
      // Old format: type is single/multiple/judge/fill
      // New format: type is single/multiple/judge/essay
      // We detect old format by checking if any question has 'fill' type
      final needsMigration = questions.any((q) => q.type == 'fill');
      if (needsMigration) {
        AppLogger.debug('🔄 Old data format detected, clearing and reloading...');
        await hiveService.clearAll();
        return false; // Return false so questions will be reloaded
      }

      // Check if all sources are 'main' (default value) - indicates old data
      // This happens when the old source mapping was incorrect
      final sources = questions.map((q) => q.source).toSet();
      if (sources.length == 1 && sources.contains('main')) {
        AppLogger.debug('🔄 Old source data detected (all sources are "main"), clearing and reloading...');
        await hiveService.clearAll();
        return false; // Return false so questions will be reloaded
      }

      return true;
    } catch (e) {
      AppLogger.debug('Error checking questions: $e');
      return false;
    }
  }

  /// Clear and reload questions (for data migration)
  static Future<void> reloadQuestions() async {
    final hiveService = HiveService();
    await hiveService.initialize();
    await hiveService.clearAll(); // Clear all data
    await initializeDefaultQuestions(); // Reload
  }

  /// Ensure question bank is initialized before app starts
  /// This is the preferred method to call in main() before runApp()
  /// Returns true if initialization was successful
  static Future<bool> ensureInitialized() async {
    AppLogger.debug('🔍 QuestionInitialization: Checking if questions exist...');

    // Check if questions already exist
    final bool hasExistingQuestions = await _hasQuestionsInternal();
    if (hasExistingQuestions) {
      AppLogger.debug('✅ QuestionInitialization: Questions already exist');
      return true;
    }

    // Initialize default questions
    AppLogger.debug('📦 QuestionInitialization: No questions found, initializing...');
    await initializeDefaultQuestions();

    // Verify initialization succeeded
    final bool verifyHasQuestions = await _hasQuestionsInternal();
    if (!verifyHasQuestions) {
      AppLogger.debug('❌ QuestionInitialization: Initialization verification failed!');
      return false;
    }

    AppLogger.debug('✅ QuestionInitialization: Successfully initialized and verified');
    return true;
  }

  /// Internal method to check if questions exist
  /// This is a separate method to avoid naming conflicts with the public hasQuestions()
  static Future<bool> _hasQuestionsInternal() async {
    try {
      final hiveService = HiveService();
      await hiveService.initialize();

      final datasource = QuestionLocalDatasource(hiveService: hiveService);
      final questions = datasource.getQuestions();

      if (questions.isEmpty) return false;

      // Check if questions need migration (old type format)
      final needsMigration = questions.any((q) => q.type == 'fill');
      if (needsMigration) {
        AppLogger.debug('🔄 Old data format detected, clearing and reloading...');
        await hiveService.clearAll();
        return false;
      }

      // Check if all sources are 'main' (default value) - indicates old data
      final sources = questions.map((q) => q.source).toSet();
      if (sources.length == 1 && sources.contains('main')) {
        AppLogger.debug('🔄 Old source data detected (all sources are "main"), clearing and reloading...');
        await hiveService.clearAll();
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.debug('Error checking questions: $e');
      return false;
    }
  }
}
