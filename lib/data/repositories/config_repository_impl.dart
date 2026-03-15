import '../models/app_config.dart';
import '../../domain/repositories/question_repository.dart';
import '../datasources/local/question_local_datasource.dart';

/// Config Repository Implementation
class ConfigRepositoryImpl implements ConfigRepository {
  final QuestionLocalDatasource _localDatasource;

  ConfigRepositoryImpl({
    required QuestionLocalDatasource localDatasource,
  }) : _localDatasource = localDatasource;

  @override
  Future<AppConfigModel?> getAppConfig() async {
    return _localDatasource.getAppConfig();
  }

  @override
  Future<void> saveAppConfig(AppConfigModel config) async {
    await _localDatasource.saveAppConfig(config);
  }

  @override
  Future<UserSettingsModel?> getUserSettings() async {
    return _localDatasource.getUserSettings();
  }

  @override
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    await _localDatasource.saveUserSettings(settings);
  }

  @override
  Future<StudyProgressModel?> getStudyProgress() async {
    return _localDatasource.getStudyProgress();
  }

  @override
  Future<void> updateStudyProgress(StudyProgressModel progress) async {
    await _localDatasource.saveStudyProgress(progress);
  }

  @override
  Future<void> incrementStudyDay() async {
    final progress = await getStudyProgress();

    if (progress == null) {
      // First study session
      await updateStudyProgress(StudyProgressModel(
        totalAnswered: 0,
        correctCount: 0,
        wrongCount: 0,
        studyDays: 1,
        lastStudyDate: DateTime.now(),
        categoryProgress: {},
      ));
      return;
    }

    // Check if last study was today
    final now = DateTime.now();
    final lastStudy = progress.lastStudyDate;
    final isDifferentDay = now.year != lastStudy.year ||
        now.month != lastStudy.month ||
        now.day != lastStudy.day;

    if (isDifferentDay) {
      await updateStudyProgress(progress.copyWith(
        studyDays: progress.studyDays + 1,
        lastStudyDate: now,
      ));
    }
  }
}
