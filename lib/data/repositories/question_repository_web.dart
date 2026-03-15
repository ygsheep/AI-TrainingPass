/// Question Repository Implementation for Web platform
import 'dart:html' as html;
import '../../domain/entities/question.dart' as domain;
import '../models/question.dart';
import '../datasources/local/file_service_web.dart' as file_service_web;
import '../datasources/local/file_service_stub.dart';
import 'question_repository_base.dart';

/// Question Repository for Web platform
/// Extends base class with web-specific file operations
class QuestionRepositoryImpl extends QuestionRepositoryBase {
  QuestionRepositoryImpl({
    required super.localDatasource,
    required super.fileService,
    super.uuid,
  });

  // ========== File Operations (Web platform) ==========

  /// Import questions from HTML file input
  /// Note: On Web, this method is not available - use importQuestionBankFromFile instead
  @override
  Future<ImportResult> importQuestionBank(String filePath) async {
    // Web doesn't support file path access
    return ImportResult.error('Web平台不支持通过文件路径导入。请使用文件选择器。');
  }

  /// Import questions from a file object (Web-specific)
  Future<ImportResult> importQuestionBankFromFile(html.File file) async {
    // Use web-specific file service directly
    final webFileService = file_service_web.FileService();
    return await webFileService.importQuestionsFromFile(file);
  }

  @override
  Future<String?> exportQuestionBank({
    required List<domain.Question> questions,
    required String name,
    required String version,
    List<String>? categories,
    String? description,
  }) async {
    final models = questions.map((q) => _convertToModel(q)).toList();
    return await fileService.exportQuestionsToFile(
      models,
      name,
      version,
      categories: categories,
      description: description,
    );
  }

  @override
  Future<List<QuestionBankFile>> getImportedFiles() async {
    // Web doesn't support listing files
    return [];
  }

  @override
  Future<bool> deleteQuestionBankFile(String filePath) async {
    // Web doesn't support file deletion
    return false;
  }

  /// Convert domain entity to model
  QuestionModel _convertToModel(domain.Question entity) {
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
    );
  }
}
