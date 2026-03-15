// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_swipe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentQuestionHash() => r'260c6708c6d5946b60b42153fd0fca550ff3774f';

/// Provider for accessing current question
///
/// Copied from [currentQuestion].
@ProviderFor(currentQuestion)
final currentQuestionProvider = AutoDisposeProvider<Question?>.internal(
  currentQuestion,
  name: r'currentQuestionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentQuestionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentQuestionRef = AutoDisposeProviderRef<Question?>;
String _$currentSummaryHash() => r'4b98af3d797c338353b12f356430df98052528df';

/// Provider for accessing current summary
///
/// Copied from [currentSummary].
@ProviderFor(currentSummary)
final currentSummaryProvider = AutoDisposeProvider<QuestionSummary?>.internal(
  currentSummary,
  name: r'currentSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentSummaryRef = AutoDisposeProviderRef<QuestionSummary?>;
String _$practiceSwipeHash() => r'88bc341e97ef545e92587e8ca306e1939c5fa3be';

/// Practice Swipe Provider
/// Manages card-based practice mode with pagination and lazy loading
///
/// Copied from [PracticeSwipe].
@ProviderFor(PracticeSwipe)
final practiceSwipeProvider =
    AutoDisposeNotifierProvider<PracticeSwipe, PracticeSwipeState>.internal(
  PracticeSwipe.new,
  name: r'practiceSwipeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceSwipeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeSwipe = AutoDisposeNotifier<PracticeSwipeState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
