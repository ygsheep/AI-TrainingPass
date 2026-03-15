import '../entities/question.dart';
import '../repositories/question_repository.dart';

/// Load Question Bank Use Case
/// Loads all questions from local storage
class LoadQuestionBankUseCase {
  final QuestionRepository _repository;

  LoadQuestionBankUseCase(this._repository);

  /// Execute the use case
  /// Returns a list of all questions
  Future<Result<List<Question>>> execute() async {
    try {
      final questions = await _repository.loadQuestionBank();
      return Result.success(questions);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get questions by category
  Future<Result<List<Question>>> getByCategory(String category) async {
    try {
      final questions = await _repository.getQuestionsByCategory(category);
      return Result.success(questions);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get random questions
  Future<Result<List<Question>>> getRandom(int count) async {
    try {
      final questions = await _repository.getRandomQuestions(count);
      return Result.success(questions);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get random questions from categories
  Future<Result<List<Question>>> getRandomFromCategories(
    int count,
    List<String> categories,
  ) async {
    try {
      final questions = await _repository.getRandomQuestionsFromCategories(
        count,
        categories,
      );
      return Result.success(questions);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get question by ID
  Future<Result<Question>> getById(String id) async {
    try {
      final question = await _repository.getQuestionById(id);
      if (question == null) {
        return Result.failure('题目不存在');
      }
      return Result.success(question);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  /// Get all categories
  Future<Result<List<String>>> getCategories() async {
    try {
      final categories = await _repository.getCategories();
      return Result.success(categories);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

/// Result Type
/// Wrapper for use case results
class Result<T> {
  final T? data;
  final String? error;

  const Result._({this.data, this.error});

  factory Result.success(T data) {
    return Result._(data: data);
  }

  factory Result.failure(String error) {
    return Result._(error: error);
  }

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  T get dataOrThrow {
    if (isSuccess && data != null) return data as T;
    throw Exception(error ?? 'Unknown error');
  }
}
