// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lineage_choice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lineageChoiceRepository)
final lineageChoiceRepositoryProvider = LineageChoiceRepositoryProvider._();

final class LineageChoiceRepositoryProvider
    extends
        $FunctionalProvider<
          LineageChoiceRepository,
          LineageChoiceRepository,
          LineageChoiceRepository
        >
    with $Provider<LineageChoiceRepository> {
  LineageChoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lineageChoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineageChoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<LineageChoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LineageChoiceRepository create(Ref ref) {
    return lineageChoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LineageChoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LineageChoiceRepository>(value),
    );
  }
}

String _$lineageChoiceRepositoryHash() =>
    r'9a6e876168e9cb0cab379c9ab26e3fc714a1a896';

/// Lignées 2024 à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).

@ProviderFor(lineageChoiceCatalog)
final lineageChoiceCatalogProvider = LineageChoiceCatalogProvider._();

/// Lignées 2024 à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
/// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
/// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
/// retry automatique : même rationale que `subclassChoiceCatalogProvider`
/// (l'écran expose son propre bouton « Réessayer »).

final class LineageChoiceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<LineageChoiceCatalog>,
          LineageChoiceCatalog,
          FutureOr<LineageChoiceCatalog>
        >
    with
        $FutureModifier<LineageChoiceCatalog>,
        $FutureProvider<LineageChoiceCatalog> {
  /// Lignées 2024 à choisir à l'étape 1/9 "Race", par `races.id` — exposé à
  /// `RaceStepScreen` (critère de déclenchement de `LineageStepScreen`, voir
  /// `_submit`) et à `LineageStepScreen` elle-même. `autoDispose`, pas de
  /// retry automatique : même rationale que `subclassChoiceCatalogProvider`
  /// (l'écran expose son propre bouton « Réessayer »).
  LineageChoiceCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'lineageChoiceCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lineageChoiceCatalogHash();

  @$internal
  @override
  $FutureProviderElement<LineageChoiceCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LineageChoiceCatalog> create(Ref ref) {
    return lineageChoiceCatalog(ref);
  }
}

String _$lineageChoiceCatalogHash() =>
    r'6ee3a83634a91f4712669fdc0dc55e73391e939d';
