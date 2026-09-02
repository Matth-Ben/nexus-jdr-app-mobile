// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterRepository)
final characterRepositoryProvider = CharacterRepositoryProvider._();

final class CharacterRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterRepository,
          CharacterRepository,
          CharacterRepository
        >
    with $Provider<CharacterRepository> {
  CharacterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterRepository create(Ref ref) {
    return characterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterRepository>(value),
    );
  }
}

String _$characterRepositoryHash() =>
    r'208385b8ada01b47c8c2bb0331b74548ca6a9b80';

/// Vide, best-effort, la file d'attente PV/XP hors-ligne — voir
/// `PendingCharacterWriteSyncer`. Seul consommateur :
/// `character_write_sync_coordinator.dart` (déclenche [sync] au démarrage et
/// à chaque retour de connectivité).

@ProviderFor(pendingCharacterWriteSyncer)
final pendingCharacterWriteSyncerProvider =
    PendingCharacterWriteSyncerProvider._();

/// Vide, best-effort, la file d'attente PV/XP hors-ligne — voir
/// `PendingCharacterWriteSyncer`. Seul consommateur :
/// `character_write_sync_coordinator.dart` (déclenche [sync] au démarrage et
/// à chaque retour de connectivité).

final class PendingCharacterWriteSyncerProvider
    extends
        $FunctionalProvider<
          PendingCharacterWriteSyncer,
          PendingCharacterWriteSyncer,
          PendingCharacterWriteSyncer
        >
    with $Provider<PendingCharacterWriteSyncer> {
  /// Vide, best-effort, la file d'attente PV/XP hors-ligne — voir
  /// `PendingCharacterWriteSyncer`. Seul consommateur :
  /// `character_write_sync_coordinator.dart` (déclenche [sync] au démarrage et
  /// à chaque retour de connectivité).
  PendingCharacterWriteSyncerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingCharacterWriteSyncerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingCharacterWriteSyncerHash();

  @$internal
  @override
  $ProviderElement<PendingCharacterWriteSyncer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingCharacterWriteSyncer create(Ref ref) {
    return pendingCharacterWriteSyncer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingCharacterWriteSyncer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingCharacterWriteSyncer>(value),
    );
  }
}

String _$pendingCharacterWriteSyncerHash() =>
    r'1fdd437867eb2afbdfee6c882ee08a97b7973222';

/// Liste des personnages du joueur connecté, exposée à
/// `CharacterListScreen`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur) :
/// contrairement à l'état d'authentification, cette liste n'a pas besoin de
/// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
/// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
/// nouvel appel.
///
/// `retry: null` désactive les tentatives automatiques en arrière-plan de
/// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
/// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
/// explicite pour l'état d'erreur, une relance automatique et silencieuse
/// masquerait une erreur persistante (ex. session expirée) derrière des
/// appels réseau répétés sans que le joueur en soit informé.

@ProviderFor(characters)
final charactersProvider = CharactersProvider._();

/// Liste des personnages du joueur connecté, exposée à
/// `CharacterListScreen`.
///
/// Volontairement `autoDispose` (comportement par défaut du générateur) :
/// contrairement à l'état d'authentification, cette liste n'a pas besoin de
/// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
/// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
/// nouvel appel.
///
/// `retry: null` désactive les tentatives automatiques en arrière-plan de
/// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
/// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
/// explicite pour l'état d'erreur, une relance automatique et silencieuse
/// masquerait une erreur persistante (ex. session expirée) derrière des
/// appels réseau répétés sans que le joueur en soit informé.

final class CharactersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CharacterSummary>>,
          List<CharacterSummary>,
          FutureOr<List<CharacterSummary>>
        >
    with
        $FutureModifier<List<CharacterSummary>>,
        $FutureProvider<List<CharacterSummary>> {
  /// Liste des personnages du joueur connecté, exposée à
  /// `CharacterListScreen`.
  ///
  /// Volontairement `autoDispose` (comportement par défaut du générateur) :
  /// contrairement à l'état d'authentification, cette liste n'a pas besoin de
  /// survivre à la fermeture de l'écran qui l'affiche. `ref.invalidate(
  /// charactersProvider)` (bouton "Réessayer" de l'état d'erreur) relance un
  /// nouvel appel.
  ///
  /// `retry: null` désactive les tentatives automatiques en arrière-plan de
  /// Riverpod 3 (comportement par défaut : relances illimitées avec backoff
  /// exponentiel sur toute erreur) : l'écran expose déjà un bouton "Réessayer"
  /// explicite pour l'état d'erreur, une relance automatique et silencieuse
  /// masquerait une erreur persistante (ex. session expirée) derrière des
  /// appels réseau répétés sans que le joueur en soit informé.
  CharactersProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'charactersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$charactersHash();

  @$internal
  @override
  $FutureProviderElement<List<CharacterSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CharacterSummary>> create(Ref ref) {
    return characters(ref);
  }
}

String _$charactersHash() => r'3a8e32a7a9df2817331ea519b8e72b7ca49ec5ad';

/// Catalogue complet des objets `items`, exposé aux sheets "Depuis le
/// catalogue" de l'onglet "Inventaire" (`presentation/widgets
/// /add_item_flow.dart`) — voir `CharacterRepository.fetchInventoryCatalog`.
///
/// `autoDispose` par défaut : ce catalogue n'a pas besoin de survivre à la
/// fermeture de la sheet qui l'affiche, même rationale que [characters].

@ProviderFor(inventoryCatalog)
final inventoryCatalogProvider = InventoryCatalogProvider._();

/// Catalogue complet des objets `items`, exposé aux sheets "Depuis le
/// catalogue" de l'onglet "Inventaire" (`presentation/widgets
/// /add_item_flow.dart`) — voir `CharacterRepository.fetchInventoryCatalog`.
///
/// `autoDispose` par défaut : ce catalogue n'a pas besoin de survivre à la
/// fermeture de la sheet qui l'affiche, même rationale que [characters].

final class InventoryCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryCatalogItem>>,
          List<InventoryCatalogItem>,
          FutureOr<List<InventoryCatalogItem>>
        >
    with
        $FutureModifier<List<InventoryCatalogItem>>,
        $FutureProvider<List<InventoryCatalogItem>> {
  /// Catalogue complet des objets `items`, exposé aux sheets "Depuis le
  /// catalogue" de l'onglet "Inventaire" (`presentation/widgets
  /// /add_item_flow.dart`) — voir `CharacterRepository.fetchInventoryCatalog`.
  ///
  /// `autoDispose` par défaut : ce catalogue n'a pas besoin de survivre à la
  /// fermeture de la sheet qui l'affiche, même rationale que [characters].
  InventoryCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'inventoryCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryCatalogItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryCatalogItem>> create(Ref ref) {
    return inventoryCatalog(ref);
  }
}

String _$inventoryCatalogHash() => r'cf03e8663cfa931f2fa404a89e9ee49862f5f24c';
