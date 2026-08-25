// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_creation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterCreationRepository)
final characterCreationRepositoryProvider =
    CharacterCreationRepositoryProvider._();

final class CharacterCreationRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterCreationRepository,
          CharacterCreationRepository,
          CharacterCreationRepository
        >
    with $Provider<CharacterCreationRepository> {
  CharacterCreationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterCreationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterCreationRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterCreationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterCreationRepository create(Ref ref) {
    return characterCreationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterCreationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterCreationRepository>(value),
    );
  }
}

String _$characterCreationRepositoryHash() =>
    r'a2ea1c4efe3890562483ad09928d9f290a1cda84';

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.

@ProviderFor(raceCatalog)
final raceCatalogProvider = RaceCatalogProvider._();

/// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
///
/// `autoDispose` (comportement par défaut du générateur) : pas besoin de
/// survivre à la fermeture de l'écran, contrairement au brouillon de
/// création (`character_creation_draft_provider.dart`) qui doit persister
/// pendant toute la session de création. `retry: null` pour la même raison
/// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
/// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
/// erreur persistante derrière des tentatives automatiques silencieuses.

final class RaceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<RaceCatalog>,
          RaceCatalog,
          FutureOr<RaceCatalog>
        >
    with $FutureModifier<RaceCatalog>, $FutureProvider<RaceCatalog> {
  /// Catalogue races/sous-races de l'étape 1/9, exposé à `RaceStepScreen`.
  ///
  /// `autoDispose` (comportement par défaut du générateur) : pas besoin de
  /// survivre à la fermeture de l'écran, contrairement au brouillon de
  /// création (`character_creation_draft_provider.dart`) qui doit persister
  /// pendant toute la session de création. `retry: null` pour la même raison
  /// que `charactersProvider` (`features/characters/presentation/providers/character_providers.dart`) :
  /// l'écran expose son propre bouton "Réessayer" plutôt que de masquer une
  /// erreur persistante derrière des tentatives automatiques silencieuses.
  RaceCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'raceCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$raceCatalogHash();

  @$internal
  @override
  $FutureProviderElement<RaceCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RaceCatalog> create(Ref ref) {
    return raceCatalog(ref);
  }
}

String _$raceCatalogHash() => r'8c79727f6540a4acf682a33db08f636ed983c91e';
