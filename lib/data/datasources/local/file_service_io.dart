/// File Service for IO platforms (Android, iOS, Windows, macOS, Linux)
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../models/question.dart';
import 'file_service_stub.dart';

/// File Service for mobile/desktop platforms
class FileService {
  /// Import questions from JSON file
  Future<ImportResult> importQuestionsFromFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (jsonData.containsKey('questions')) {
        return _parseQuestionBankFormat(jsonData);
      } else {
        return _parseLegacyFormat(jsonData);
      }
    } on FormatException catch (e) {
      return ImportResult.error('JSON格式错误: ${e.message}');
    } catch (e) {
      return ImportResult.error('导入失败: ${e.toString()}');
    }
  }

  /// Parse new question bank format with metadata
  ImportResult _parseQuestionBankFormat(Map<String, dynamic> jsonData) {
    try {
      final meta = jsonData['meta'] as Map<String, dynamic>?;
      final questionsJson = jsonData['questions'] as List;
      final categoriesJson = jsonData['categories'] as List?;

      final questions = <QuestionModel>[];
      for (var q in questionsJson) {
        final question = QuestionModel.fromJson(q as Map<String, dynamic>);
        questions.add(question);
      }

      final categories = categoriesJson?.map((e) {
        if (e is String) return e;
        if (e is Map) return e['name'] as String? ?? e['id'] as String;
        return e.toString();
      }).toList();

      return ImportResult.success(
        questions: questions,
        version: meta?['version'] as String? ?? '1.0.0',
        name: meta?['name'] as String? ?? '导入的题库',
        totalQuestions: questions.length,
        categories: categories,
      );
    } catch (e) {
      return ImportResult.error('解析题库格式失败: ${e.toString()}');
    }
  }

  /// Parse legacy format (direct array of questions)
  ImportResult _parseLegacyFormat(dynamic jsonData) {
    try {
      final questionsJson = jsonData as List;
      final questions = <QuestionModel>[];

      for (var q in questionsJson) {
        final question = QuestionModel.fromJson(q as Map<String, dynamic>);
        questions.add(question);
      }

      final categories = questions
          .expand((q) => q.category)
          .toSet()
          .toList();

      return ImportResult.success(
        questions: questions,
        version: '1.0.0',
        name: '导入的题库',
        totalQuestions: questions.length,
        categories: categories,
      );
    } catch (e) {
      return ImportResult.error('解析题目数据失败: ${e.toString()}');
    }
  }

  /// Export questions to JSON file
  Future<String?> exportQuestionsToFile(
    List<QuestionModel> questions,
    String name,
    String version, {
    List<String>? categories,
    String? description,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final questionBankDir = Directory(path.join(appDir.path, 'question_banks'));
      if (!await questionBankDir.exists()) {
        await questionBankDir.create(recursive: true);
      }

      final fileName = _sanitizeFileName(name);
      final file = File(path.join(questionBankDir.path, '${fileName}_$version.json'));

      final questionBank = {
        'meta': {
          'name': name,
          'version': version,
          'description': description ?? '',
          'created_at': DateTime.now().toIso8601String(),
          'total_questions': questions.length,
        },
        'categories': (categories ?? questions.map((q) => q.category).toSet().toList())
            .map((cat) => {'id': cat, 'name': cat})
            .toList(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(questionBank);
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Get list of imported question bank files
  Future<List<QuestionBankFile>> getImportedFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final questionBankDir = Directory(path.join(appDir.path, 'question_banks'));

      if (!await questionBankDir.exists()) {
        return [];
      }

      final files = await questionBankDir.list()
          .where((e) => e.path.endsWith('.json'))
          .toList();

      final result = <QuestionBankFile>[];
      for (var file in files) {
        if (file is File) {
          final info = await _getQuestionBankInfo(file);
          if (info != null) {
            result.add(info);
          }
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  Future<QuestionBankFile?> _getQuestionBankInfo(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final meta = jsonData['meta'] as Map<String, dynamic>?;
      final questions = jsonData['questions'] as List?;

      return _QuestionBankFileIO(
        path: file.path,
        name: meta?['name'] as String? ?? path.basenameWithoutExtension(file.path),
        version: meta?['version'] as String? ?? 'unknown',
        totalQuestions: questions?.length ?? 0,
        createdAt: file.lastModifiedSync(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete a question bank file
  Future<bool> deleteQuestionBankFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sanitize filename to remove invalid characters
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }
}

/// Question Bank File with file size support for IO platforms
class _QuestionBankFileIO extends QuestionBankFile {
  _QuestionBankFileIO({
    required super.path,
    required super.name,
    required super.version,
    required super.totalQuestions,
    required super.createdAt,
  });

  @override
  String get formattedSize {
    final file = File(this.path);
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
