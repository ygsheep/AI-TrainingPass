// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dataExportServiceHash() => r'ab04f90f8951a9b7a0e53dd0e8b17b38c0b734f1';

/// Data Export Service Provider
///
/// Copied from [dataExportService].
@ProviderFor(dataExportService)
final dataExportServiceProvider =
    AutoDisposeProvider<DataExportService>.internal(
  dataExportService,
  name: r'dataExportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dataExportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DataExportServiceRef = AutoDisposeProviderRef<DataExportService>;
String _$dataExportHash() => r'e250abdb804a0caf4e87358092f1b6c1df53a683';

/// Data Export Provider
///
/// Copied from [DataExport].
@ProviderFor(DataExport)
final dataExportProvider =
    AutoDisposeNotifierProvider<DataExport, DataExportState>.internal(
  DataExport.new,
  name: r'dataExportProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dataExportHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DataExport = AutoDisposeNotifier<DataExportState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
