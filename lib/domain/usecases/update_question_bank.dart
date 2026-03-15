import '../entities/question.dart';
import '../repositories/question_repository.dart';
import '../../data/datasources/local/file_service_stub.dart';

/// Update Question Bank Use Case
/// Handles importing question banks from files or URLs
class UpdateQuestionBankUseCase {
  final QuestionRepository _repository;

  UpdateQuestionBankUseCase(this._repository);

  /// Import question bank from a local file
  /// Returns [UpdateQuestionBankResult] with import statistics
  Future<UpdateQuestionBankResult> importFromFile(String filePath) async {
    try {
      final result = await _repository.importQuestionBank(filePath);

      if (!result.success) {
        return UpdateQuestionBankResult.error(result.errorMessage ?? '导入失败');
      }

      // Check if questions list is null
      if (result.questions == null) {
        return UpdateQuestionBankResult.error('导入的题目为空');
      }

      // Convert QuestionModel to Question domain entity
      final domainQuestions = result.questions!.map((model) {
        return Question(
          id: model.id,
          source: model.source,
          category: model.category,
          type: model.type,
          question: model.question,
          options: model.options?.map((o) => o.text).toList(),
          answer: model.answer,
          explanation: model.explanation,
          difficulty: model.difficulty,
        );
      }).toList();

      // Save the imported questions
      await _repository.saveQuestionBank(domainQuestions);

      // Update version if provided
      if (result.version != null) {
        await _repository.updateQuestionBankVersion(result.version!);
      }

      return UpdateQuestionBankResult.success(
        questionCount: domainQuestions.length,
        version: result.version,
        name: result.name,
      );
    } catch (e) {
      return UpdateQuestionBankResult.error(e.toString());
    }
  }

  /// Import question bank from a URL
  /// Returns [UpdateQuestionBankResult] with import statistics
  Future<UpdateQuestionBankResult> importFromUrl(String url) async {
    try {
      // For URL import, we would need to:
      // 1. Download the file
      // 2. Save it temporarily
      // 3. Use importFromFile

      // This is a placeholder for URL import functionality
      // In a real implementation, you'd use dio or http to download
      return UpdateQuestionBankResult.error('URL import not yet implemented');
    } catch (e) {
      return UpdateQuestionBankResult.error(e.toString());
    }
  }

  /// Export current question bank to a file
  /// Returns [UpdateQuestionBankResult] with export path
  Future<UpdateQuestionBankResult> exportToFile({
    required String name,
    required String version,
    List<String>? categories,
    String? description,
  }) async {
    try {
      // Get all questions
      final questions = await _repository.loadQuestionBank();

      // Filter by categories if specified
      final filteredQuestions = categories != null && categories.isNotEmpty
          ? questions.where((q) => categories.contains(q.category)).toList()
          : questions;

      if (filteredQuestions.isEmpty) {
        return UpdateQuestionBankResult.error('没有可导出的题目');
      }

      // Export to file
      final filePath = await _repository.exportQuestionBank(
        questions: filteredQuestions,
        name: name,
        version: version,
        categories: categories,
        description: description,
      );

      if (filePath == null) {
        return UpdateQuestionBankResult.error('导出失败');
      }

      return UpdateQuestionBankResult.success(
        questionCount: filteredQuestions.length,
        version: version,
        name: name,
        exportPath: filePath,
      );
    } catch (e) {
      return UpdateQuestionBankResult.error(e.toString());
    }
  }

  /// Get list of imported question bank files
  Future<List<QuestionBankFile>> getImportedFiles() async {
    return await _repository.getImportedFiles();
  }

  /// Delete an imported question bank file
  Future<bool> deleteFile(String filePath) async {
    return await _repository.deleteQuestionBankFile(filePath);
  }
}

/// Update Question Bank Result
class UpdateQuestionBankResult {
  final bool success;
  final int? questionCount;
  final String? version;
  final String? name;
  final String? exportPath;
  final String? error;

  const UpdateQuestionBankResult._({
    required this.success,
    this.questionCount,
    this.version,
    this.name,
    this.exportPath,
    this.error,
  });

  factory UpdateQuestionBankResult.success({
    required int questionCount,
    String? version,
    String? name,
    String? exportPath,
  }) {
    return UpdateQuestionBankResult._(
      success: true,
      questionCount: questionCount,
      version: version,
      name: name,
      exportPath: exportPath,
    );
  }

  factory UpdateQuestionBankResult.error(String error) {
    return UpdateQuestionBankResult._(
      success: false,
      error: error,
    );
  }
}
