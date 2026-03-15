// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questionRepositoryHash() =>
    r'4df8a996fe128eab82e3e2a2106a7b0003a7a003';

/// Question Repository Provider
///
/// Copied from [questionRepository].
@ProviderFor(questionRepository)
final questionRepositoryProvider =
    AutoDisposeProvider<QuestionRepository>.internal(
  questionRepository,
  name: r'questionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef QuestionRepositoryRef = AutoDisposeProviderRef<QuestionRepository>;
String _$loadQuestionBankUseCaseHash() =>
    r'928cbf71560affe2994622d1785747e6db33bac7';

/// Load Question Bank UseCase Provider
///
/// Copied from [loadQuestionBankUseCase].
@ProviderFor(loadQuestionBankUseCase)
final loadQuestionBankUseCaseProvider =
    AutoDisposeProvider<LoadQuestionBankUseCase>.internal(
  loadQuestionBankUseCase,
  name: r'loadQuestionBankUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadQuestionBankUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LoadQuestionBankUseCaseRef
    = AutoDisposeProviderRef<LoadQuestionBankUseCase>;
String _$submitAnswerUseCaseHash() =>
    r'c9ce2119e3ae27b2a41d027169da4c19046a05a6';

/// Submit Answer UseCase Provider
///
/// Copied from [submitAnswerUseCase].
@ProviderFor(submitAnswerUseCase)
final submitAnswerUseCaseProvider =
    AutoDisposeProvider<SubmitAnswerUseCase>.internal(
  submitAnswerUseCase,
  name: r'submitAnswerUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$submitAnswerUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubmitAnswerUseCaseRef = AutoDisposeProviderRef<SubmitAnswerUseCase>;
String _$updateQuestionBankUseCaseHash() =>
    r'9f8c8f8f328c44ffc3f6dd47bf092ce250e28833';

/// Update Question Bank UseCase Provider
///
/// Copied from [updateQuestionBankUseCase].
@ProviderFor(updateQuestionBankUseCase)
final updateQuestionBankUseCaseProvider =
    AutoDisposeProvider<UpdateQuestionBankUseCase>.internal(
  updateQuestionBankUseCase,
  name: r'updateQuestionBankUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateQuestionBankUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UpdateQuestionBankUseCaseRef
    = AutoDisposeProviderRef<UpdateQuestionBankUseCase>;
String _$questionBankHash() => r'976cdc0e968ea458fa89cec743ad8fa4105d04b4';

/// Question Bank State Provider
///
/// Copied from [QuestionBank].
@ProviderFor(QuestionBank)
final questionBankProvider =
    AutoDisposeNotifierProvider<QuestionBank, QuestionBankState>.internal(
  QuestionBank.new,
  name: r'questionBankProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$questionBankHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestionBank = AutoDisposeNotifier<QuestionBankState>;
String _$questionBankImportHash() =>
    r'fcde2b8612f62cf4d01df0ad6edf70f095ff2aef';

/// Question Bank Import Provider
///
/// Copied from [QuestionBankImport].
@ProviderFor(QuestionBankImport)
final questionBankImportProvider =
    AutoDisposeNotifierProvider<QuestionBankImport, ImportResultState>.internal(
  QuestionBankImport.new,
  name: r'questionBankImportProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questionBankImportHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestionBankImport = AutoDisposeNotifier<ImportResultState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
