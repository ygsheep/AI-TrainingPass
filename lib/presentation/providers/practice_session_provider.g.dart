// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceSessionHash() => r'57b2f8363739535517d4e8c4ead2b25fb6442717';

/// Practice Session Provider
/// Manages practice session, current question, answers, and caching
///
/// Copied from [PracticeSession].
@ProviderFor(PracticeSession)
final practiceSessionProvider =
    AutoDisposeNotifierProvider<PracticeSession, PracticeSessionState>.internal(
  PracticeSession.new,
  name: r'practiceSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeSession = AutoDisposeNotifier<PracticeSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
