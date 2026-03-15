// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_setup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$examSetupSourcesHash() => r'cea39d1f1bb1af4344cfc4f07c61daaad73d24bd';

/// Available sources for exam setup
///
/// Copied from [examSetupSources].
@ProviderFor(examSetupSources)
final examSetupSourcesProvider = AutoDisposeProvider<List<String>>.internal(
  examSetupSources,
  name: r'examSetupSourcesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$examSetupSourcesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExamSetupSourcesRef = AutoDisposeProviderRef<List<String>>;
String _$examSetupHash() => r'237e747d0e1293f1866f2186d0e077fc34ab6e76';

/// Exam Setup Provider
///
/// Copied from [ExamSetup].
@ProviderFor(ExamSetup)
final examSetupProvider =
    AutoDisposeNotifierProvider<ExamSetup, ExamSetupState>.internal(
  ExamSetup.new,
  name: r'examSetupProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$examSetupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExamSetup = AutoDisposeNotifier<ExamSetupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
