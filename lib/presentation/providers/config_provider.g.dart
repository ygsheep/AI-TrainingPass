// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$configRepositoryHash() => r'50c25a2d749fb9789c17b0fa7997c25a5d2cc971';

/// Config Repository Provider
///
/// Copied from [configRepository].
@ProviderFor(configRepository)
final configRepositoryProvider = AutoDisposeProvider<ConfigRepository>.internal(
  configRepository,
  name: r'configRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$configRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ConfigRepositoryRef = AutoDisposeProviderRef<ConfigRepository>;
String _$appConfigHash() => r'f3a56b1785f10c9576c8eba83338fcdb024f8887';

/// App Config Provider
///
/// Copied from [AppConfig].
@ProviderFor(AppConfig)
final appConfigProvider =
    AutoDisposeNotifierProvider<AppConfig, AppConfigState>.internal(
  AppConfig.new,
  name: r'appConfigProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppConfig = AutoDisposeNotifier<AppConfigState>;
String _$userSettingsHash() => r'75af09c439dc31b25562cf3803aa3f14eb3e8f80';

/// User Settings Provider
///
/// Copied from [UserSettings].
@ProviderFor(UserSettings)
final userSettingsProvider =
    AutoDisposeNotifierProvider<UserSettings, UserSettingsState>.internal(
  UserSettings.new,
  name: r'userSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserSettings = AutoDisposeNotifier<UserSettingsState>;
String _$studyProgressHash() => r'f7c20141f7f27433f578d872b0c3d9196e5eb2ee';

/// Study Progress Provider
///
/// Copied from [StudyProgress].
@ProviderFor(StudyProgress)
final studyProgressProvider =
    AutoDisposeNotifierProvider<StudyProgress, StudyProgressState>.internal(
  StudyProgress.new,
  name: r'studyProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studyProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudyProgress = AutoDisposeNotifier<StudyProgressState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
