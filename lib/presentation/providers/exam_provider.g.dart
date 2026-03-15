// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$examStatisticsHash() => r'770404e6bb5bae3de9535aca4bfe8ec7addf491d';

/// Exam Statistics Provider
///
/// Copied from [examStatistics].
@ProviderFor(examStatistics)
final examStatisticsProvider =
    AutoDisposeFutureProvider<ExamStatistics>.internal(
  examStatistics,
  name: r'examStatisticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$examStatisticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExamStatisticsRef = AutoDisposeFutureProviderRef<ExamStatistics>;
String _$examRecordHash() => r'f0700b8fc495a2f8e25813747b3796abc7d571b1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Single Exam Record Provider
///
/// Copied from [examRecord].
@ProviderFor(examRecord)
const examRecordProvider = ExamRecordFamily();

/// Single Exam Record Provider
///
/// Copied from [examRecord].
class ExamRecordFamily extends Family<AsyncValue<ExamRecordModel?>> {
  /// Single Exam Record Provider
  ///
  /// Copied from [examRecord].
  const ExamRecordFamily();

  /// Single Exam Record Provider
  ///
  /// Copied from [examRecord].
  ExamRecordProvider call(
    String id,
  ) {
    return ExamRecordProvider(
      id,
    );
  }

  @override
  ExamRecordProvider getProviderOverride(
    covariant ExamRecordProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'examRecordProvider';
}

/// Single Exam Record Provider
///
/// Copied from [examRecord].
class ExamRecordProvider extends AutoDisposeFutureProvider<ExamRecordModel?> {
  /// Single Exam Record Provider
  ///
  /// Copied from [examRecord].
  ExamRecordProvider(
    String id,
  ) : this._internal(
          (ref) => examRecord(
            ref as ExamRecordRef,
            id,
          ),
          from: examRecordProvider,
          name: r'examRecordProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$examRecordHash,
          dependencies: ExamRecordFamily._dependencies,
          allTransitiveDependencies:
              ExamRecordFamily._allTransitiveDependencies,
          id: id,
        );

  ExamRecordProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<ExamRecordModel?> Function(ExamRecordRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExamRecordProvider._internal(
        (ref) => create(ref as ExamRecordRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ExamRecordModel?> createElement() {
    return _ExamRecordProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExamRecordProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ExamRecordRef on AutoDisposeFutureProviderRef<ExamRecordModel?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ExamRecordProviderElement
    extends AutoDisposeFutureProviderElement<ExamRecordModel?>
    with ExamRecordRef {
  _ExamRecordProviderElement(super.provider);

  @override
  String get id => (origin as ExamRecordProvider).id;
}

String _$activeExamHash() => r'80197c8c5f0124011dd24687e7e61a35c3c80f80';

/// Active Exam State Provider
///
/// Copied from [ActiveExam].
@ProviderFor(ActiveExam)
final activeExamProvider =
    AutoDisposeNotifierProvider<ActiveExam, ExamState?>.internal(
  ActiveExam.new,
  name: r'activeExamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$activeExamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveExam = AutoDisposeNotifier<ExamState?>;
String _$examHistoryHash() => r'22691d5cbe9d9e7a310842ec68ef512731912183';

/// Exam History Provider
///
/// Copied from [ExamHistory].
@ProviderFor(ExamHistory)
final examHistoryProvider =
    AutoDisposeNotifierProvider<ExamHistory, ExamHistoryState>.internal(
  ExamHistory.new,
  name: r'examHistoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$examHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExamHistory = AutoDisposeNotifier<ExamHistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
