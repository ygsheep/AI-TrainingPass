import '../entities/exam_statistics.dart';
import '../repositories/question_repository.dart';
import '../../data/models/exam_record.dart';

/// Get Exam History Use Case
/// Retrieves exam records with filtering and pagination
class GetExamHistoryUseCase {
  final QuestionRepository _repository;

  GetExamHistoryUseCase(this._repository);

  /// Execute the use case
  Future<GetExamHistoryResult> execute(GetExamHistoryParams params) async {
    try {
      final allRecords = await _repository.getExamHistory();

      // Filter by date range if specified
      var filtered = allRecords;
      if (params.startDate != null) {
        filtered = filtered.where((r) =>
            r.startTime.isAtSameMomentAs(params.startDate!) ||
            r.startTime.isAfter(params.startDate!)).toList();
      }
      if (params.endDate != null) {
        filtered = filtered.where((r) =>
            r.startTime.isAtSameMomentAs(params.endDate!) ||
            r.startTime.isBefore(params.endDate!)).toList();
      }

      // Filter by passed status if specified
      if (params.passedOnly != null) {
        filtered = filtered.where((r) => r.passed == params.passedOnly).toList();
      }

      // Sort by start time (newest first)
      filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Apply pagination
      final start = params.offset;
      final end = params.limit != null ? start + params.limit! : filtered.length;
      final paginated = filtered.sublist(
        start.clamp(0, filtered.length),
        end.clamp(0, filtered.length),
      );

      return GetExamHistoryResult.success(
        records: paginated,
        totalCount: filtered.length,
        hasMore: end < filtered.length,
      );
    } catch (e) {
      return GetExamHistoryResult.error(e.toString());
    }
  }
}

/// Get Exam History Parameters
class GetExamHistoryParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? passedOnly;
  final int offset;
  final int? limit;

  const GetExamHistoryParams({
    this.startDate,
    this.endDate,
    this.passedOnly,
    this.offset = 0,
    this.limit,
  });
}

/// Get Exam History Result
class GetExamHistoryResult {
  final bool success;
  final List<ExamRecordModel>? records;
  final int? totalCount;
  final bool? hasMore;
  final String? error;

  const GetExamHistoryResult._({
    required this.success,
    this.records,
    this.totalCount,
    this.hasMore,
    this.error,
  });

  factory GetExamHistoryResult.success({
    required List<ExamRecordModel> records,
    required int totalCount,
    required bool hasMore,
  }) {
    return GetExamHistoryResult._(
      success: true,
      records: records,
      totalCount: totalCount,
      hasMore: hasMore,
    );
  }

  factory GetExamHistoryResult.error(String error) {
    return GetExamHistoryResult._(
      success: false,
      error: error,
    );
  }
}

/// Get Exam Statistics Use Case
/// Retrieves overall exam statistics
class GetExamStatisticsUseCase {
  final QuestionRepository _repository;

  GetExamStatisticsUseCase(this._repository);

  /// Execute the use case
  Future<GetExamStatisticsResult> execute() async {
    try {
      final stats = await _repository.getExamStatistics();
      return GetExamStatisticsResult.success(stats);
    } catch (e) {
      return GetExamStatisticsResult.error(e.toString());
    }
  }
}

/// Get Exam Statistics Result
class GetExamStatisticsResult {
  final bool success;
  final ExamStatistics? statistics;
  final String? error;

  const GetExamStatisticsResult._({
    required this.success,
    this.statistics,
    this.error,
  });

  factory GetExamStatisticsResult.success(ExamStatistics statistics) {
    return GetExamStatisticsResult._(
      success: true,
      statistics: statistics,
    );
  }

  factory GetExamStatisticsResult.error(String error) {
    return GetExamStatisticsResult._(
      success: false,
      error: error,
    );
  }
}

/// Get Exam Record by ID Use Case
class GetExamRecordByIdUseCase {
  final QuestionRepository _repository;

  GetExamRecordByIdUseCase(this._repository);

  /// Execute the use case
  Future<GetExamRecordByIdResult> execute(String id) async {
    try {
      final record = await _repository.getExamRecordById(id);
      if (record == null) {
        return GetExamRecordByIdResult.error('考试记录不存在');
      }
      return GetExamRecordByIdResult.success(record);
    } catch (e) {
      return GetExamRecordByIdResult.error(e.toString());
    }
  }
}

/// Get Exam Record by ID Result
class GetExamRecordByIdResult {
  final bool success;
  final ExamRecordModel? record;
  final String? error;

  const GetExamRecordByIdResult._({
    required this.success,
    this.record,
    this.error,
  });

  factory GetExamRecordByIdResult.success(ExamRecordModel record) {
    return GetExamRecordByIdResult._(
      success: true,
      record: record,
    );
  }

  factory GetExamRecordByIdResult.error(String error) {
    return GetExamRecordByIdResult._(
      success: false,
      error: error,
    );
  }
}
