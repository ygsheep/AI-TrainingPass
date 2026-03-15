// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questionUpdateServiceHash() =>
    r'a24bf03949324fb6c4d777d98a4c40b15173363c';

/// Question Update Service Provider
///
/// Copied from [questionUpdateService].
@ProviderFor(questionUpdateService)
final questionUpdateServiceProvider =
    AutoDisposeProvider<QuestionUpdateService>.internal(
  questionUpdateService,
  name: r'questionUpdateServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questionUpdateServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef QuestionUpdateServiceRef
    = AutoDisposeProviderRef<QuestionUpdateService>;
String _$questionUpdateHash() => r'5e90820e771714f0247ba87df1fdb6a7f414da41';

/// Question Update Provider
///
/// Copied from [QuestionUpdate].
@ProviderFor(QuestionUpdate)
final questionUpdateProvider =
    AutoDisposeNotifierProvider<QuestionUpdate, QuestionUpdateState>.internal(
  QuestionUpdate.new,
  name: r'questionUpdateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questionUpdateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestionUpdate = AutoDisposeNotifier<QuestionUpdateState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
