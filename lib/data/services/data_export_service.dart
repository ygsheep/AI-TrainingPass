import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_answer.dart';
import '../models/wrong_question.dart';
import '../models/exam_record.dart';
import '../models/app_config.dart';
import '../models/practice_progress.dart';
import '../datasources/local/hive_service.dart';
import '../datasources/local/question_local_datasource.dart';
import '../../core/utils/app_logger.dart';

/// Export Data Result
class ExportResult {
  final bool success;
  final String? error;
  final String? filePath;
  final int? totalRecords;

  const ExportResult({
    required this.success,
    this.error,
    this.filePath,
    this.totalRecords,
  });

  factory ExportResult.success({
    required String filePath,
    required int totalRecords,
  }) {
    return ExportResult(
      success: true,
      filePath: filePath,
      totalRecords: totalRecords,
    );
  }

  factory ExportResult.error(String error) {
    return ExportResult(
      success: false,
      error: error,
    );
  }
}

/// User Export Data
/// Contains all user data for export
class UserExportData {
  final String exportDate;
  final String appVersion;
  final List<UserAnswerModel> userAnswers;
  final List<ExamRecordModel> examRecords;
  final List<WrongQuestionModel> wrongQuestions;
  final StudyProgressModel? studyProgress;
  final UserSettingsModel? userSettings;

  UserExportData({
    required this.exportDate,
    required this.appVersion,
    required this.userAnswers,
    required this.examRecords,
    required this.wrongQuestions,
    this.studyProgress,
    this.userSettings,
  });

  Map<String, dynamic> toJson() => {
    'export_date': exportDate,
    'app_version': appVersion,
    'user_answers': userAnswers.map((a) => a.toJson()).toList(),
    'exam_records': examRecords.map((r) => r.toJson()).toList(),
    'wrong_questions': wrongQuestions.map((w) => w.toJson()).toList(),
    'study_progress': studyProgress?.toJson(),
    'user_settings': userSettings?.toJson(),
  };

  int get totalRecords =>
      userAnswers.length + examRecords.length + wrongQuestions.length;
}

/// Data Export Service
/// Handles exporting user data to JSON file
class DataExportService {
  final HiveService _hiveService;
  QuestionLocalDatasource? _datasource;
  bool _isInitialized = false;

  DataExportService({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService();

  /// Ensure HiveService is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _hiveService.initialize();
      _datasource = QuestionLocalDatasource(hiveService: _hiveService);
      _isInitialized = true;
    }
  }

  /// Get the datasource (initialized lazily)
  QuestionLocalDatasource get _datasourceOrThrow {
    if (_datasource == null) {
      throw StateError('DataExportService not initialized. Call _ensureInitialized() first.');
    }
    return _datasource!;
  }

  /// Collect all user data
  Future<UserExportData> _collectUserData() async {
    await _ensureInitialized();

    // Get all user answers
    final userAnswers = _datasourceOrThrow.getUserAnswers();
    AppLogger.debug('📊 Collected ${userAnswers.length} user answers');

    // Get all exam records
    final examRecords = _datasourceOrThrow.getExamHistory();
    AppLogger.debug('📊 Collected ${examRecords.length} exam records');

    // Get all wrong questions
    final wrongQuestions = _datasourceOrThrow.getWrongQuestions();
    AppLogger.debug('📊 Collected ${wrongQuestions.length} wrong questions');

    // Get study progress
    final studyProgress = await _datasourceOrThrow.getStudyProgress();
    AppLogger.debug('📊 Collected study progress');

    // Get user settings
    final userSettings = await _datasourceOrThrow.getUserSettings();
    AppLogger.debug('📊 Collected user settings');

    return UserExportData(
      exportDate: DateTime.now().toIso8601String(),
      appVersion: '1.0.0',
      userAnswers: userAnswers,
      examRecords: examRecords,
      wrongQuestions: wrongQuestions,
      studyProgress: studyProgress,
      userSettings: userSettings,
    );
  }

  /// Export user data to JSON file (IO platform)
  Future<ExportResult> exportToFile() async {
    try {
      AppLogger.debug('📤 Starting data export...');

      // Collect data
      final userData = await _collectUserData();

      if (userData.totalRecords == 0) {
        return ExportResult.error('没有可导出的数据');
      }

      // Create JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData.toJson());

      // Save to file (platform-specific)
      final filePath = await _saveToFile(jsonString);

      AppLogger.debug('✅ Export completed: $filePath');

      return ExportResult.success(
        filePath: filePath,
        totalRecords: userData.totalRecords,
      );
    } catch (e) {
      AppLogger.debug('❌ Export failed: $e');
      return ExportResult.error('导出失败: ${e.toString()}');
    }
  }

  /// Save JSON string to file (platform-specific)
  Future<String> _saveToFile(String jsonString) async {
    if (kIsWeb) {
      // Web: Use file picker to save
      return await _saveToFileWeb(jsonString);
    } else {
      // IO: Save to documents directory
      return await _saveToFileIO(jsonString);
    }
  }

  /// Save to file on IO platforms
  Future<String> _saveToFileIO(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'trainingpass_export_$timestamp.json';
    final file = File('${exportDir.path}/$fileName');

    await file.writeAsString(jsonString);
    return file.path;
  }

  /// Save to file on Web platform
  Future<String> _saveToFileWeb(String jsonString) async {
    // On web, we need to trigger a download
    // This is handled by the UI layer using file_picker or direct download
    // Return a placeholder path
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    return 'trainingpass_export_$timestamp.json';
  }

  /// Get export data as JSON string (for web download)
  Future<String> getExportJsonString() async {
    final userData = await _collectUserData();
    return const JsonEncoder.withIndent('  ').convert(userData.toJson());
  }

  /// Get export statistics without full export
  Future<Map<String, int>> getExportStatistics() async {
    try {
      await _ensureInitialized();

      final userAnswers = _datasourceOrThrow.getUserAnswers();
      final examRecords = _datasourceOrThrow.getExamHistory();
      final wrongQuestions = _datasourceOrThrow.getWrongQuestions();

      return {
        'user_answers': userAnswers.length,
        'exam_records': examRecords.length,
        'wrong_questions': wrongQuestions.length,
        'total': userAnswers.length + examRecords.length + wrongQuestions.length,
      };
    } catch (e) {
      AppLogger.debug('❌ Error getting statistics: $e');
      return {
        'user_answers': 0,
        'exam_records': 0,
        'wrong_questions': 0,
        'total': 0,
      };
    }
  }
}
