// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dataExportRepository)
final dataExportRepositoryProvider = DataExportRepositoryProvider._();

final class DataExportRepositoryProvider
    extends
        $FunctionalProvider<
          DataExportRepository,
          DataExportRepository,
          DataExportRepository
        >
    with $Provider<DataExportRepository> {
  DataExportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataExportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataExportRepositoryHash();

  @$internal
  @override
  $ProviderElement<DataExportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DataExportRepository create(Ref ref) {
    return dataExportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataExportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataExportRepository>(value),
    );
  }
}

String _$dataExportRepositoryHash() =>
    r'597ddb23c1fd0608c6a3baf8af4f3f0d48a2f08b';
