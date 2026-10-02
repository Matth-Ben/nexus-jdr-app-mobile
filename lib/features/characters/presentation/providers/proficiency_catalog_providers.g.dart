// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proficiency_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Catalogue de référence armes/armures/boucliers — voir
/// [ProficiencyCatalogRepository].

@ProviderFor(proficiencyCatalogRepository)
final proficiencyCatalogRepositoryProvider =
    ProficiencyCatalogRepositoryProvider._();

/// Catalogue de référence armes/armures/boucliers — voir
/// [ProficiencyCatalogRepository].

final class ProficiencyCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          ProficiencyCatalogRepository,
          ProficiencyCatalogRepository,
          ProficiencyCatalogRepository
        >
    with $Provider<ProficiencyCatalogRepository> {
  /// Catalogue de référence armes/armures/boucliers — voir
  /// [ProficiencyCatalogRepository].
  ProficiencyCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proficiencyCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proficiencyCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProficiencyCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProficiencyCatalogRepository create(Ref ref) {
    return proficiencyCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProficiencyCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProficiencyCatalogRepository>(value),
    );
  }
}

String _$proficiencyCatalogRepositoryHash() =>
    r'6e31c023089f93f3296e33cb8a7178ece5d8d524';

/// Catalogue chargé à l'ouverture du panneau "Infos" d'un token de maîtrise
/// (`proficiency_detail_panel.dart`), libéré à sa fermeture.
///
/// `retry: null` : le panneau expose un bouton « Réessayer » explicite, même
/// rationale que `pactWeaponOptionsProvider`.

@ProviderFor(proficiencyCatalog)
final proficiencyCatalogProvider = ProficiencyCatalogProvider._();

/// Catalogue chargé à l'ouverture du panneau "Infos" d'un token de maîtrise
/// (`proficiency_detail_panel.dart`), libéré à sa fermeture.
///
/// `retry: null` : le panneau expose un bouton « Réessayer » explicite, même
/// rationale que `pactWeaponOptionsProvider`.

final class ProficiencyCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProficiencyCatalog>,
          ProficiencyCatalog,
          FutureOr<ProficiencyCatalog>
        >
    with
        $FutureModifier<ProficiencyCatalog>,
        $FutureProvider<ProficiencyCatalog> {
  /// Catalogue chargé à l'ouverture du panneau "Infos" d'un token de maîtrise
  /// (`proficiency_detail_panel.dart`), libéré à sa fermeture.
  ///
  /// `retry: null` : le panneau expose un bouton « Réessayer » explicite, même
  /// rationale que `pactWeaponOptionsProvider`.
  ProficiencyCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'proficiencyCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proficiencyCatalogHash();

  @$internal
  @override
  $FutureProviderElement<ProficiencyCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProficiencyCatalog> create(Ref ref) {
    return proficiencyCatalog(ref);
  }
}

String _$proficiencyCatalogHash() =>
    r'291047c0daf6e8b7053ab0975028d1858934cf6f';
