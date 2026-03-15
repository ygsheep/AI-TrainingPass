import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/services/data_export_service.dart';
import '../../core/utils/app_logger.dart';

part 'data_export_provider.g.dart';

/// Data Export Service Provider
@riverpod
DataExportService dataExportService(Ref ref) {
  return DataExportService();
}

/// Data Export State
class DataExportState {
  final bool isExporting;
  final bool isSuccess;
  final String? error;
  final String? filePath;
  final int? totalRecords;
  final Map<String, int>? statistics;

  const DataExportState({
    this.isExporting = false,
    this.isSuccess = false,
    this.error,
    this.filePath,
    this.totalRecords,
    this.statistics,
  });

  DataExportState copyWith({
    bool? isExporting,
    bool? isSuccess,
    String? error,
    String? filePath,
    int? totalRecords,
    Map<String, int>? statistics,
  }) {
    return DataExportState(
      isExporting: isExporting ?? this.isExporting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      filePath: filePath ?? this.filePath,
      totalRecords: totalRecords ?? this.totalRecords,
      statistics: statistics ?? this.statistics,
    );
  }
}

/// Data Export Provider
@riverpod
class DataExport extends _$DataExport {
  @override
  DataExportState build() {
    // Load statistics on initialization
    _loadStatistics();
    return const DataExportState();
  }

  /// Load export statistics
  Future<void> _loadStatistics() async {
    try {
      final service = ref.read(dataExportServiceProvider);
      final stats = await service.getExportStatistics();

      state = state.copyWith(statistics: stats);
      AppLogger.debug('📊 Export statistics: $stats');
    } catch (e) {
      AppLogger.debug('❌ Error loading statistics: $e');
    }
  }

  /// Export data to file
  Future<void> exportToFile() async {
    state = state.copyWith(
      isExporting: true,
      error: null,
      isSuccess: false,
    );

    try {
      AppLogger.debug('📤 Starting export...');

      final service = ref.read(dataExportServiceProvider);
      final result = await service.exportToFile();

      if (!result.success) {
        state = state.copyWith(
          isExporting: false,
          error: result.error,
        );
        return;
      }

      // Reload statistics after export
      await _loadStatistics();

      state = state.copyWith(
        isExporting: false,
        isSuccess: true,
        filePath: result.filePath,
        totalRecords: result.totalRecords,
      );

      AppLogger.debug('✅ Export completed');
    } catch (e) {
      AppLogger.debug('❌ Export failed: $e');
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  /// Get export JSON string (for web download)
  Future<String> getExportJsonString() async {
    final service = ref.read(dataExportServiceProvider);
    return await service.getExportJsonString();
  }

  /// Reset state
  void reset() {
    state = const DataExportState();
    _loadStatistics();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
