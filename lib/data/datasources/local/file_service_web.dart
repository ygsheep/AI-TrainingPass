/// File Service for Web platform
import 'dart:convert';
import 'dart:html' as html;
import '../../models/question.dart';
import 'file_service_stub.dart';

/// File Service for web platform
/// Uses browser download/upload for file operations
class FileService {
  /// Import questions from JSON file
  Future<ImportResult> importQuestionsFromFile(html.File file) async {
    try {
      final reader = html.FileReader();
      reader.readAsText(file);
      await reader.onLoad.first;
      final jsonString = reader.result as String;

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
          .map((q) => q.category)
          .expand((cats) => cats) // Expand all category arrays
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

  /// Export questions to JSON file (triggers browser download)
  Future<String?> exportQuestionsToFile(
    List<QuestionModel> questions,
    String name,
    String version, {
    List<String>? categories,
    String? description,
  }) async {
    try {
      final fileName = _sanitizeFileName(name);

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
      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrl(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', '${fileName}_$version.json')
        ..click();

      html.Url.revokeObjectUrl(url);

      return fileName;
    } catch (e) {
      return null;
    }
  }

  /// Get list of imported question bank files (not supported on web)
  Future<List<QuestionBankFile>> getImportedFiles() async {
    // Web doesn't support file system access
    return [];
  }

  /// Delete a question bank file (not supported on web)
  Future<bool> deleteQuestionBankFile(String filePath) async {
    // Web doesn't support file deletion
    return false;
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
