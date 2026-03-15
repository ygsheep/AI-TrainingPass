import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../data/models/app_config.dart';
import '../../domain/repositories/question_repository.dart';
import '../../data/repositories/config_repository_impl.dart';
import '../../data/datasources/local/question_local_datasource.dart';
import '../../data/datasources/local/hive_service.dart';

part 'config_provider.g.dart';

/// Config Repository Provider
@riverpod
ConfigRepository configRepository(Ref ref) {
  // Reuse the same HiveService from question repository
  final hiveService = HiveService();

  return ConfigRepositoryImpl(
    localDatasource: QuestionLocalDatasource(hiveService: hiveService),
  );
}

/// App Config State
class AppConfigState {
  final AppConfigModel? config;
  final bool isLoading;
  final String? error;

  const AppConfigState({
    this.config,
    this.isLoading = false,
    this.error,
  });

  AppConfigState copyWith({
    AppConfigModel? config,
    bool? isLoading,
    String? error,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// App Config Provider
@riverpod
class AppConfig extends _$AppConfig {
  @override
  AppConfigState build() {
    // Don't call loadConfig here to avoid circular dependency
    return const AppConfigState(isLoading: true);
  }

  /// Load app config
  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(configRepositoryProvider);
    final config = await repository.getAppConfig();

    state = state.copyWith(
      config: config,
      isLoading: false,
    );
  }

  /// Save app config
  Future<bool> saveConfig(AppConfigModel config) async {
    final repository = ref.read(configRepositoryProvider);
    await repository.saveAppConfig(config);

    state = state.copyWith(config: config);
    return true;
  }

  /// Update question bank version
  Future<void> updateQuestionBankVersion(String version) async {
    final currentConfig = state.config;
    if (currentConfig == null) {
      final newConfig = AppConfigModel(
        appName: 'TrainingPass',
        appVersion: '1.0.0',
        questionBankVersion: version,
        lastUpdateCheck: DateTime.now(),
      );
      await saveConfig(newConfig);
    } else {
      final updatedConfig = currentConfig.copyWith(
        questionBankVersion: version,
        lastUpdateCheck: DateTime.now(),
      );
      await saveConfig(updatedConfig);
    }
  }
}

/// User Settings State
class UserSettingsState {
  final UserSettingsModel? settings;
  final bool isLoading;
  final String? error;

  const UserSettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
  });

  UserSettingsState copyWith({
    UserSettingsModel? settings,
    bool? isLoading,
    String? error,
  }) {
    return UserSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// User Settings Provider
@riverpod
class UserSettings extends _$UserSettings {
  @override
  UserSettingsState build() {
    // Don't call loadSettings here to avoid circular dependency
    // State will be loaded when first accessed
    return const UserSettingsState(isLoading: true);
  }

  /// Load user settings
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(configRepositoryProvider);
    final settings = await repository.getUserSettings();

    // Create default settings if none exist
    final finalSettings = settings ??
        const UserSettingsModel(
          themeMode: 'system',
          showExplanations: true,
          showTimer: true,
          textSize: 1,
          autoSubmit: true,
        );

    state = state.copyWith(
      settings: finalSettings,
      isLoading: false,
    );
  }

  /// Save user settings
  Future<bool> saveSettings(UserSettingsModel settings) async {
    final repository = ref.read(configRepositoryProvider);
    await repository.saveUserSettings(settings);

    state = state.copyWith(settings: settings);
    return true;
  }

  /// Update theme mode
  Future<void> updateThemeMode(String themeMode) async {
    final current = state.settings;
    if (current == null) return;

    final updated = current.copyWith(themeMode: themeMode);
    await saveSettings(updated);
  }

  /// Toggle show explanations
  Future<void> toggleShowExplanations() async {
    final current = state.settings;
    if (current == null) return;

    final updated = current.copyWith(showExplanations: !current.showExplanations);
    await saveSettings(updated);
  }

  /// Toggle show timer
  Future<void> toggleShowTimer() async {
    final current = state.settings;
    if (current == null) return;

    final updated = current.copyWith(showTimer: !current.showTimer);
    await saveSettings(updated);
  }

  /// Update text size
  Future<void> updateTextSize(int textSize) async {
    final current = state.settings;
    if (current == null) return;

    final updated = current.copyWith(textSize: textSize);
    await saveSettings(updated);
  }

  /// Toggle auto submit
  Future<void> toggleAutoSubmit() async {
    final current = state.settings;
    if (current == null) return;

    final updated = current.copyWith(autoSubmit: !current.autoSubmit);
    await saveSettings(updated);
  }
}

/// Study Progress State
class StudyProgressState {
  final StudyProgressModel? progress;
  final bool isLoading;
  final String? error;

  const StudyProgressState({
    this.progress,
    this.isLoading = false,
    this.error,
  });

  StudyProgressState copyWith({
    StudyProgressModel? progress,
    bool? isLoading,
    String? error,
  }) {
    return StudyProgressState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Study Progress Provider
@riverpod
class StudyProgress extends _$StudyProgress {
  @override
  StudyProgressState build() {
    // Don't call loadProgress here to avoid circular dependency
    return const StudyProgressState(isLoading: true);
  }

  /// Load study progress
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(configRepositoryProvider);
    final progress = await repository.getStudyProgress();

    state = state.copyWith(
      progress: progress,
      isLoading: false,
    );
  }

  /// Update study progress
  Future<bool> updateProgress(StudyProgressModel progress) async {
    final repository = ref.read(configRepositoryProvider);
    await repository.updateStudyProgress(progress);

    state = state.copyWith(progress: progress);
    return true;
  }

  /// Increment study day
  Future<void> incrementStudyDay() async {
    final repository = ref.read(configRepositoryProvider);
    await repository.incrementStudyDay();

    // Reload progress
    await loadProgress();
  }

  /// Add practice session
  Future<void> addPracticeSession({
    required int questionCount,
    required int correctCount,
    required int duration,
  }) async {
    final current = state.progress;
    final now = DateTime.now();
    final wrongCount = questionCount - correctCount;

    final updatedProgress = current == null
        ? StudyProgressModel(
            totalAnswered: questionCount,
            correctCount: correctCount,
            wrongCount: wrongCount,
            studyDays: 1,
            lastStudyDate: now,
            categoryProgress: {},
          )
        : StudyProgressModel(
            totalAnswered: current.totalAnswered + questionCount,
            correctCount: current.correctCount + correctCount,
            wrongCount: current.wrongCount + wrongCount,
            studyDays: _isNewDay(current.lastStudyDate, now)
                ? current.studyDays + 1
                : current.studyDays,
            lastStudyDate: now,
            categoryProgress: current.categoryProgress,
          );

    await updateProgress(updatedProgress);
  }

  /// Check if dates are different days
  bool _isNewDay(DateTime lastDate, DateTime newDate) {
    return lastDate.year != newDate.year ||
        lastDate.month != newDate.month ||
        lastDate.day != newDate.day;
  }

  /// Get accuracy percentage
  double get accuracy {
    final progress = state.progress;
    if (progress == null || progress.totalAnswered == 0) {
      return 0.0;
    }
    return progress.accuracy;
  }
}
