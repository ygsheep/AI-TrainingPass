import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../datasources/local/hive_service.dart';
import '../datasources/local/question_local_datasource.dart';
import '../../core/utils/app_logger.dart';
import 'package:http/http.dart' as http;

/// Question Bank Metadata
/// Contains version and other metadata about the question bank
class QuestionBankMetadata {
  final String format;
  final String formatVersion;
  final String? minReaderVersion;
  final String? createdAt;
  final String? updatedAt;
  final int? totalQuestions;
  final List<String>? categories;

  const QuestionBankMetadata({
    required this.format,
    required this.formatVersion,
    this.minReaderVersion,
    this.createdAt,
    this.updatedAt,
    this.totalQuestions,
    this.categories,
  });

  factory QuestionBankMetadata.fromJson(Map<String, dynamic> json) {
    return QuestionBankMetadata(
      format: json['format'] as String? ?? 'cz002-questions',
      formatVersion: json['format_version'] as String? ?? '1.0.0',
      minReaderVersion: json['min_reader_version'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      totalQuestions: json['total_questions'] as int?,
      categories: (json['categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Check if this version is newer than the given version
  bool isNewerThan(String otherVersion) {
    try {
      final current = formatVersion.split('.').map(int.parse).toList();
      final other = otherVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < current.length ? current[i] : 0;
        final o = i < other.length ? other[i] : 0;
        if (c > o) return true;
        if (c < o) return false;
      }
      return false;
    } catch (e) {
      AppLogger.debug('⚠️ Error comparing versions: $e');
      return false;
    }
  }
}

/// Question Bank Update Result
class QuestionUpdateResult {
  final bool success;
  final String? error;
  final QuestionBankMetadata? metadata;
  final int? questionCount;
  final String? currentVersion;
  final String? newVersion;

  const QuestionUpdateResult({
    required this.success,
    this.error,
    this.metadata,
    this.questionCount,
    this.currentVersion,
    this.newVersion,
  });

  factory QuestionUpdateResult.success({
    QuestionBankMetadata? metadata,
    int? questionCount,
    String? currentVersion,
    String? newVersion,
  }) {
    return QuestionUpdateResult(
      success: true,
      metadata: metadata,
      questionCount: questionCount,
      currentVersion: currentVersion,
      newVersion: newVersion,
    );
  }

  factory QuestionUpdateResult.error(String error) {
    return QuestionUpdateResult(
      success: false,
      error: error,
    );
  }
}

/// Question Update Service
/// Handles updating question bank from network or local file
class QuestionUpdateService {
  final HiveService _hiveService;
  QuestionLocalDatasource? _datasource;
  bool _isInitialized = false;

  QuestionUpdateService({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService();

  /// Ensure HiveService is initialized before use
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
      throw StateError('QuestionUpdateService not initialized. Call _ensureInitialized() first.');
    }
    return _datasource!;
  }

  /// Check for updates from remote URL
  /// Returns metadata if update is available, null if up to date
  Future<QuestionBankMetadata?> checkForUpdates(String updateUrl) async {
    try {
      AppLogger.debug('🔍 Checking for updates at: $updateUrl');

      final response = await http.get(
        Uri.parse(updateUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('请求超时，请检查网络连接');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('服务器返回错误: ${response.statusCode}');
      }

      final jsonString = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse metadata
      if (jsonData.containsKey('_meta')) {
        final meta = QuestionBankMetadata.fromJson(
          jsonData['_meta'] as Map<String, dynamic>,
        );

        // Get current version
        final currentVersion = await _getCurrentVersion();
        AppLogger.debug('📦 Current version: $currentVersion');
        AppLogger.debug('📦 Remote version: ${meta.formatVersion}');

        // Check if update is needed
        if (currentVersion != null && meta.isNewerThan(currentVersion)) {
          AppLogger.debug('✅ New version available!');
          return meta;
        } else {
          AppLogger.debug('✅ Already up to date');
          return null;
        }
      } else {
        // Old format without metadata - consider it as an update
        AppLogger.debug('⚠️ Remote file has no metadata');
        return const QuestionBankMetadata(
          format: 'cz002-questions',
          formatVersion: '1.0.0',
        );
      }
    } catch (e) {
      AppLogger.debug('❌ Error checking for updates: $e');
      rethrow;
    }
  }

  /// Download and apply update from remote URL
  Future<QuestionUpdateResult> updateFromUrl(String updateUrl) async {
    try {
      AppLogger.debug('📥 Downloading update from: $updateUrl');

      final response = await http.get(
        Uri.parse(updateUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('下载超时，请检查网络连接');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('服务器返回错误: ${response.statusCode}');
      }

      final jsonString = utf8.decode(response.bodyBytes);
      return await _processAndImportJson(jsonString);
    } catch (e) {
      AppLogger.debug('❌ Error updating from URL: $e');
      return QuestionUpdateResult.error(e.toString());
    }
  }

  /// Import questions from JSON string (from file picker or network)
  Future<QuestionUpdateResult> importFromJsonString(String jsonString) async {
    try {
      return await _processAndImportJson(jsonString);
    } catch (e) {
      AppLogger.debug('❌ Error importing from JSON string: $e');
      return QuestionUpdateResult.error(e.toString());
    }
  }

  /// Process and import JSON data
  Future<QuestionUpdateResult> _processAndImportJson(String jsonString) async {
    try {
      // Ensure HiveService is initialized
      await _ensureInitialized();

      final dynamic jsonData = jsonDecode(jsonString);

      // Parse JSON - support both new format (with _meta) and old format (direct array)
      List<dynamic> jsonList;
      QuestionBankMetadata? metadata;

      if (jsonData is Map && jsonData.containsKey('_meta')) {
        // New format: { "_meta": {...}, "questions": [...] }
        final dataMap = jsonData as Map<String, dynamic>;
        metadata = QuestionBankMetadata.fromJson(
          dataMap['_meta'] as Map<String, dynamic>,
        );
        jsonList = dataMap['questions'] as List<dynamic>;

        AppLogger.debug('📦 Question Bank Metadata:');
        AppLogger.debug('   Format: ${metadata.format}');
        AppLogger.debug('   Version: ${metadata.formatVersion}');
        AppLogger.debug('   Updated: ${metadata.updatedAt}');
        AppLogger.debug('   Total Questions: ${metadata.totalQuestions}');
      } else if (jsonData is List) {
        // Old format: direct array of questions
        jsonList = jsonData as List<dynamic>;
        AppLogger.debug('📦 Loaded OLD format (direct array, no metadata)');
      } else {
        return QuestionUpdateResult.error('无效的JSON格式');
      }

      // Convert all questions using fromNewJson
      final questions = jsonList.map((json) {
        return QuestionModel.fromNewJson(json as Map<String, dynamic>);
      }).toList();

      AppLogger.debug('✅ Parsed ${questions.length} questions');

      // 统计有多少题目包含解析
      final withExplanation = questions.where((q) => q.explanation != null && q.explanation!.isNotEmpty).length;
      AppLogger.debug('📖 Questions with explanation: $withExplanation/${questions.length}');

      // Validate against metadata count if available
      if (metadata?.totalQuestions != null) {
        final expectedCount = metadata!.totalQuestions!;
        if (questions.length != expectedCount) {
          AppLogger.debug('⚠️ Warning: Expected $expectedCount questions, got ${questions.length}');
        }
      }

      // Get current version before updating
      final currentVersion = await _getCurrentVersion();

      // Save to local storage
      await _datasourceOrThrow.saveQuestions(questions);

      // Update version
      final newVersion = metadata?.formatVersion ?? '1.0.0';
      await _datasourceOrThrow.updateQuestionBankVersion(newVersion);

      // Verify save
      await Future.delayed(const Duration(milliseconds: 300));
      final savedQuestions = _datasourceOrThrow.getQuestions();
      if (savedQuestions.length != questions.length) {
        AppLogger.debug('⚠️ Warning: Saved ${savedQuestions.length} but expected ${questions.length}');
      }

      AppLogger.debug('✅ Successfully imported ${questions.length} questions');

      return QuestionUpdateResult.success(
        metadata: metadata,
        questionCount: questions.length,
        currentVersion: currentVersion,
        newVersion: newVersion,
      );
    } on FormatException catch (e) {
      return QuestionUpdateResult.error('JSON格式错误: ${e.message}');
    } catch (e) {
      return QuestionUpdateResult.error('导入失败: ${e.toString()}');
    }
  }

  /// Get current question bank version
  Future<String?> _getCurrentVersion() async {
    try {
      await _ensureInitialized();
      return await _datasourceOrThrow.getQuestionBankVersion();
    } catch (e) {
      AppLogger.debug('❌ Error getting current version: $e');
      return null;
    }
  }

  /// Get current version (public method)
  Future<String?> getCurrentVersion() async {
    return await _getCurrentVersion();
  }

  /// Get current question count
  Future<int> getCurrentQuestionCount() async {
    try {
      await _ensureInitialized();
      final questions = _datasourceOrThrow.getQuestions();
      return questions.length;
    } catch (e) {
      AppLogger.debug('❌ Error getting question count: $e');
      return 0;
    }
  }
}
