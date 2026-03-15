// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_book_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$wrongQuestionHash() => r'9b4d1d08247a42b4f5e573e868522832dc34fdef';

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

/// Single Wrong Question Provider
///
/// Copied from [wrongQuestion].
@ProviderFor(wrongQuestion)
const wrongQuestionProvider = WrongQuestionFamily();

/// Single Wrong Question Provider
///
/// Copied from [wrongQuestion].
class WrongQuestionFamily extends Family<AsyncValue<WrongQuestion?>> {
  /// Single Wrong Question Provider
  ///
  /// Copied from [wrongQuestion].
  const WrongQuestionFamily();

  /// Single Wrong Question Provider
  ///
  /// Copied from [wrongQuestion].
  WrongQuestionProvider call(
    String id,
  ) {
    return WrongQuestionProvider(
      id,
    );
  }

  @override
  WrongQuestionProvider getProviderOverride(
    covariant WrongQuestionProvider provider,
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
  String? get name => r'wrongQuestionProvider';
}

/// Single Wrong Question Provider
///
/// Copied from [wrongQuestion].
class WrongQuestionProvider extends AutoDisposeFutureProvider<WrongQuestion?> {
  /// Single Wrong Question Provider
  ///
  /// Copied from [wrongQuestion].
  WrongQuestionProvider(
    String id,
  ) : this._internal(
          (ref) => wrongQuestion(
            ref as WrongQuestionRef,
            id,
          ),
          from: wrongQuestionProvider,
          name: r'wrongQuestionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$wrongQuestionHash,
          dependencies: WrongQuestionFamily._dependencies,
          allTransitiveDependencies:
              WrongQuestionFamily._allTransitiveDependencies,
          id: id,
        );

  WrongQuestionProvider._internal(
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
    FutureOr<WrongQuestion?> Function(WrongQuestionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WrongQuestionProvider._internal(
        (ref) => create(ref as WrongQuestionRef),
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
  AutoDisposeFutureProviderElement<WrongQuestion?> createElement() {
    return _WrongQuestionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WrongQuestionProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WrongQuestionRef on AutoDisposeFutureProviderRef<WrongQuestion?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _WrongQuestionProviderElement
    extends AutoDisposeFutureProviderElement<WrongQuestion?>
    with WrongQuestionRef {
  _WrongQuestionProviderElement(super.provider);

  @override
  String get id => (origin as WrongQuestionProvider).id;
}

String _$wrongBookHash() => r'67be1cd33ef408f7868e3d680bbc4a52a52927c8';

/// Wrong Book State Provider
///
/// Copied from [WrongBook].
@ProviderFor(WrongBook)
final wrongBookProvider =
    AutoDisposeNotifierProvider<WrongBook, WrongBookState>.internal(
  WrongBook.new,
  name: r'wrongBookProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$wrongBookHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WrongBook = AutoDisposeNotifier<WrongBookState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
