/// Question Repository Implementation for IO platforms (Android, iOS, Windows, macOS, Linux)
import 'dart:io';
import '../../domain/entities/question.dart' as domain;
import '../models/question.dart';
import '../datasources/local/file_service_stub.dart';
import 'question_repository_base.dart';

/// Question Repository for IO platforms
/// Extends base class with file system operations
class QuestionRepositoryImpl extends QuestionRepositoryBase {
  QuestionRepositoryImpl({
    required super.localDatasource,
    required super.fileService,
    super.uuid,
  });

  // ========== File Operations (IO platforms only) ==========

  @override
  Future<ImportResult> importQuestionBank(String filePath) async {
    final file = File(filePath);
    return await fileService.importQuestionsFromFile(file);
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
    return await fileService.getImportedFiles();
  }

  @override
  Future<bool> deleteQuestionBankFile(String filePath) async {
    return await fileService.deleteQuestionBankFile(filePath);
  }

  /// Convert domain entity to model (alias for private _toModel in base)
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
