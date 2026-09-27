// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_updates_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inAppUpdateGateway)
final inAppUpdateGatewayProvider = InAppUpdateGatewayProvider._();

final class InAppUpdateGatewayProvider
    extends
        $FunctionalProvider<
          InAppUpdateGateway,
          InAppUpdateGateway,
          InAppUpdateGateway
        >
    with $Provider<InAppUpdateGateway> {
  InAppUpdateGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppUpdateGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppUpdateGatewayHash();

  @$internal
  @override
  $ProviderElement<InAppUpdateGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InAppUpdateGateway create(Ref ref) {
    return inAppUpdateGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InAppUpdateGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InAppUpdateGateway>(value),
    );
  }
}

String _$inAppUpdateGatewayHash() =>
    r'644c8c353c8c6df55a573f49bb6cb4b4ca9d7c5d';

/// Versions publiées décrites dans le changelog embarqué, de la plus
/// récente à la plus ancienne.

@ProviderFor(changelogReleases)
final changelogReleasesProvider = ChangelogReleasesProvider._();

/// Versions publiées décrites dans le changelog embarqué, de la plus
/// récente à la plus ancienne.

final class ChangelogReleasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChangelogRelease>>,
          List<ChangelogRelease>,
          FutureOr<List<ChangelogRelease>>
        >
    with
        $FutureModifier<List<ChangelogRelease>>,
        $FutureProvider<List<ChangelogRelease>> {
  /// Versions publiées décrites dans le changelog embarqué, de la plus
  /// récente à la plus ancienne.
  ChangelogReleasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changelogReleasesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changelogReleasesHash();

  @$internal
  @override
  $FutureProviderElement<List<ChangelogRelease>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChangelogRelease>> create(Ref ref) {
    return changelogReleases(ref);
  }
}

String _$changelogReleasesHash() => r'd3deafa9aae7d9e5b26af047355a68878c1d63bc';
