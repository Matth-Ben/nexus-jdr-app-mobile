// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_write_sync_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : orchestre la synchro hors-ligne PV/XP
/// (`PendingCharacterWriteSyncer`) déclenchée par la connectivité, et
/// invalide `characterDetailProvider` pour chaque personnage synchronisé
/// avec succès (pour que la fiche, si affichée, se resynchronise proprement
/// avec l'état serveur confirmé) — voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne".
///
/// Deux déclencheurs, tous deux best-effort (aucune exception ne doit jamais
/// remonter jusqu'à l'appelant de [start]) :
/// - immédiatement au démarrage (des écritures peuvent être restées en
///   attente depuis la dernière fermeture de l'app, avec un réseau déjà
///   revenu depuis) ;
/// - à chaque retour de connectivité (`ConnectivityChecker.onConnectivityRestored`).
///
/// Pas de synchro en arrière-plan pendant que l'app est fermée/suspendue —
/// hors périmètre (voir la tâche qui a introduit ce mécanisme).

@ProviderFor(characterWriteSyncCoordinator)
final characterWriteSyncCoordinatorProvider =
    CharacterWriteSyncCoordinatorProvider._();

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : orchestre la synchro hors-ligne PV/XP
/// (`PendingCharacterWriteSyncer`) déclenchée par la connectivité, et
/// invalide `characterDetailProvider` pour chaque personnage synchronisé
/// avec succès (pour que la fiche, si affichée, se resynchronise proprement
/// avec l'état serveur confirmé) — voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne".
///
/// Deux déclencheurs, tous deux best-effort (aucune exception ne doit jamais
/// remonter jusqu'à l'appelant de [start]) :
/// - immédiatement au démarrage (des écritures peuvent être restées en
///   attente depuis la dernière fermeture de l'app, avec un réseau déjà
///   revenu depuis) ;
/// - à chaque retour de connectivité (`ConnectivityChecker.onConnectivityRestored`).
///
/// Pas de synchro en arrière-plan pendant que l'app est fermée/suspendue —
/// hors périmètre (voir la tâche qui a introduit ce mécanisme).

final class CharacterWriteSyncCoordinatorProvider
    extends
        $FunctionalProvider<
          CharacterWriteSyncCoordinator,
          CharacterWriteSyncCoordinator,
          CharacterWriteSyncCoordinator
        >
    with $Provider<CharacterWriteSyncCoordinator> {
  /// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
  /// `main.dart`) : orchestre la synchro hors-ligne PV/XP
  /// (`PendingCharacterWriteSyncer`) déclenchée par la connectivité, et
  /// invalide `characterDetailProvider` pour chaque personnage synchronisé
  /// avec succès (pour que la fiche, si affichée, se resynchronise proprement
  /// avec l'état serveur confirmé) — voir
  /// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
  /// hors-ligne".
  ///
  /// Deux déclencheurs, tous deux best-effort (aucune exception ne doit jamais
  /// remonter jusqu'à l'appelant de [start]) :
  /// - immédiatement au démarrage (des écritures peuvent être restées en
  ///   attente depuis la dernière fermeture de l'app, avec un réseau déjà
  ///   revenu depuis) ;
  /// - à chaque retour de connectivité (`ConnectivityChecker.onConnectivityRestored`).
  ///
  /// Pas de synchro en arrière-plan pendant que l'app est fermée/suspendue —
  /// hors périmètre (voir la tâche qui a introduit ce mécanisme).
  CharacterWriteSyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterWriteSyncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterWriteSyncCoordinatorHash();

  @$internal
  @override
  $ProviderElement<CharacterWriteSyncCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterWriteSyncCoordinator create(Ref ref) {
    return characterWriteSyncCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterWriteSyncCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterWriteSyncCoordinator>(
        value,
      ),
    );
  }
}

String _$characterWriteSyncCoordinatorHash() =>
    r'2bac46332d590711e55e1fa7d1c4862fd24af417';
