import 'dart:io';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/services/question_update_service.dart';
import '../../core/utils/app_logger.dart';
import '../providers/question_provider.dart';

part 'question_update_provider.g.dart';

/// Question Update Service Provider
@riverpod
QuestionUpdateService questionUpdateService(Ref ref) {
  return QuestionUpdateService();
}

/// Question Update State
class QuestionUpdateState {
  final bool isChecking;
  final bool isUpdating;
  final bool isSuccess;
  final String? error;
  final QuestionBankMetadata? availableUpdate;
  final String? currentVersion;
  final int? currentQuestionCount;
  final int? updatedQuestionCount;
  final String? newVersion;

  const QuestionUpdateState({
    this.isChecking = false,
    this.isUpdating = false,
    this.isSuccess = false,
    this.error,
    this.availableUpdate,
    this.currentVersion,
    this.currentQuestionCount,
    this.updatedQuestionCount,
    this.newVersion,
  });

  QuestionUpdateState copyWith({
    bool? isChecking,
    bool? isUpdating,
    bool? isSuccess,
    String? error,
    QuestionBankMetadata? availableUpdate,
    String? currentVersion,
    int? currentQuestionCount,
    int? updatedQuestionCount,
    String? newVersion,
  }) {
    return QuestionUpdateState(
      isChecking: isChecking ?? this.isChecking,
      isUpdating: isUpdating ?? this.isUpdating,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      availableUpdate: availableUpdate ?? this.availableUpdate,
      currentVersion: currentVersion ?? this.currentVersion,
      currentQuestionCount: currentQuestionCount ?? this.currentQuestionCount,
      updatedQuestionCount: updatedQuestionCount ?? this.updatedQuestionCount,
      newVersion: newVersion ?? this.newVersion,
    );
  }

  /// Check if there's an update available
  bool get hasUpdateAvailable => availableUpdate != null;
}

/// Question Update Provider
@riverpod
class QuestionUpdate extends _$QuestionUpdate {
  @override
  QuestionUpdateState build() {
    // Load current version on initialization
    _loadCurrentVersion();
    return const QuestionUpdateState();
  }

  /// Load current version and question count
  Future<void> _loadCurrentVersion() async {
    try {
      final service = ref.read(questionUpdateServiceProvider);
      final version = await service.getCurrentVersion();
      final count = await service.getCurrentQuestionCount();

      state = state.copyWith(
        currentVersion: version,
        currentQuestionCount: count,
      );
      AppLogger.debug('📦 Current version: $version, Questions: $count');
    } catch (e) {
      AppLogger.debug('❌ Error loading current version: $e');
    }
  }

  /// Check for updates from remote URL
  Future<void> checkForUpdates(String updateUrl) async {
    state = state.copyWith(
      isChecking: true,
      error: null,
      availableUpdate: null,
    );

    try {
      final service = ref.read(questionUpdateServiceProvider);
      final metadata = await service.checkForUpdates(updateUrl);

      if (metadata != null) {
        state = state.copyWith(
          isChecking: false,
          availableUpdate: metadata,
        );
        AppLogger.debug('✅ Update available: ${metadata.formatVersion}');
      } else {
        state = state.copyWith(
          isChecking: false,
          availableUpdate: null,
        );
        AppLogger.debug('✅ No updates available');
      }
    } catch (e) {
      AppLogger.debug('❌ Error checking for updates: $e');
      state = state.copyWith(
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  /// Download and apply update from remote URL
  Future<void> updateFromUrl(String updateUrl) async {
    state = state.copyWith(
      isUpdating: true,
      error: null,
      isSuccess: false,
    );

    try {
      AppLogger.debug('📥 Starting update from URL...');

      final service = ref.read(questionUpdateServiceProvider);
      final result = await service.updateFromUrl(updateUrl);

      if (!result.success) {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
        return;
      }

      // Reload question bank to refresh UI
      // Use Future.microtask to avoid triggering state updates during async operation
      AppLogger.debug('🔄 Scheduling question bank reload...');
      Future.microtask(() {
        ref.read(questionBankProvider.notifier).loadQuestionBank();
      });

      // Reload current version
      await _loadCurrentVersion();

      state = state.copyWith(
        isUpdating: false,
        isSuccess: true,
        updatedQuestionCount: result.questionCount,
        newVersion: result.newVersion,
        availableUpdate: null, // Clear available update after applying
      );

      AppLogger.debug('✅ Update completed successfully');
    } catch (e) {
      AppLogger.debug('❌ Error updating from URL: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Import from local file (IO platform)
  Future<void> importFromFile(File file) async {
    state = state.copyWith(
      isUpdating: true,
      error: null,
      isSuccess: false,
    );

    try {
      AppLogger.debug('📂 Starting import from file: ${file.path}');

      // Explicitly use UTF-8 encoding to ensure Chinese characters are read correctly
      final jsonString = await file.readAsString(encoding: utf8);
      final service = ref.read(questionUpdateServiceProvider);
      final result = await service.importFromJsonString(jsonString);

      if (!result.success) {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
        return;
      }

      // Reload question bank to refresh UI
      // Use Future.microtask to avoid triggering state updates during async operation
      AppLogger.debug('🔄 Scheduling question bank reload...');
      Future.microtask(() {
        ref.read(questionBankProvider.notifier).loadQuestionBank();
      });

      // Reload current version
      await _loadCurrentVersion();

      state = state.copyWith(
        isUpdating: false,
        isSuccess: true,
        updatedQuestionCount: result.questionCount,
        newVersion: result.newVersion,
      );

      AppLogger.debug('✅ Import completed successfully');
    } catch (e) {
      AppLogger.debug('❌ Error importing from file: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Import from JSON string (Web platform - from file picker)
  Future<void> importFromJsonString(String jsonString) async {
    state = state.copyWith(
      isUpdating: true,
      error: null,
      isSuccess: false,
    );

    try {
      AppLogger.debug('📄 Starting import from JSON string...');

      final service = ref.read(questionUpdateServiceProvider);
      final result = await service.importFromJsonString(jsonString);

      if (!result.success) {
        state = state.copyWith(
          isUpdating: false,
          error: result.error,
        );
        return;
      }

      // Reload question bank to refresh UI
      // Use Future.microtask to avoid triggering state updates during async operation
      AppLogger.debug('🔄 Scheduling question bank reload...');
      Future.microtask(() {
        ref.read(questionBankProvider.notifier).loadQuestionBank();
      });

      // Reload current version
      await _loadCurrentVersion();

      state = state.copyWith(
        isUpdating: false,
        isSuccess: true,
        updatedQuestionCount: result.questionCount,
        newVersion: result.newVersion,
      );

      AppLogger.debug('✅ Import completed successfully');
    } catch (e) {
      AppLogger.debug('❌ Error importing from JSON string: $e');
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Reset state
  void reset() {
    state = const QuestionUpdateState();
    _loadCurrentVersion();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
