// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subclass_choice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subclassChoiceRepository)
final subclassChoiceRepositoryProvider = SubclassChoiceRepositoryProvider._();

final class SubclassChoiceRepositoryProvider
    extends
        $FunctionalProvider<
          SubclassChoiceRepository,
          SubclassChoiceRepository,
          SubclassChoiceRepository
        >
    with $Provider<SubclassChoiceRepository> {
  SubclassChoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subclassChoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subclassChoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubclassChoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubclassChoiceRepository create(Ref ref) {
    return subclassChoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubclassChoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubclassChoiceRepository>(value),
    );
  }
}

String _$subclassChoiceRepositoryHash() =>
    r'ad674eaed6db51eba5050345696687d2d522cd8d';

/// Classes qui choisissent leur sous-classe au niveau 1, avec leurs options —
/// exposé à `ClassStepScreen` et au récapitulatif. `autoDispose`, pas de
/// retry automatique : même rationale que `classCatalogProvider` (l'écran
/// expose son propre bouton « Réessayer »).

@ProviderFor(subclassChoiceCatalog)
final subclassChoiceCatalogProvider = SubclassChoiceCatalogProvider._();

/// Classes qui choisissent leur sous-classe au niveau 1, avec leurs options —
/// exposé à `ClassStepScreen` et au récapitulatif. `autoDispose`, pas de
/// retry automatique : même rationale que `classCatalogProvider` (l'écran
/// expose son propre bouton « Réessayer »).

final class SubclassChoiceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<SubclassChoiceCatalog>,
          SubclassChoiceCatalog,
          FutureOr<SubclassChoiceCatalog>
        >
    with
        $FutureModifier<SubclassChoiceCatalog>,
        $FutureProvider<SubclassChoiceCatalog> {
  /// Classes qui choisissent leur sous-classe au niveau 1, avec leurs options —
  /// exposé à `ClassStepScreen` et au récapitulatif. `autoDispose`, pas de
  /// retry automatique : même rationale que `classCatalogProvider` (l'écran
  /// expose son propre bouton « Réessayer »).
  SubclassChoiceCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'subclassChoiceCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subclassChoiceCatalogHash();

  @$internal
  @override
  $FutureProviderElement<SubclassChoiceCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SubclassChoiceCatalog> create(Ref ref) {
    return subclassChoiceCatalog(ref);
  }
}

String _$subclassChoiceCatalogHash() =>
    r'689ea67c545bc67d12cf069d35e28380d1594c68';
