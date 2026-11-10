import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/notifications/notification_providers.dart';
import '../../data/pending_character_write_syncer.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'character_write_sync_coordinator.g.dart';

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : orchestre la synchro hors-ligne PV/XP
/// (`PendingCharacterWriteSyncer`) déclenchée par la connectivité, invalide
/// `characterDetailProvider` pour chaque personnage synchronisé avec succès
/// (pour que la fiche, si affichée, se resynchronise proprement avec l'état
/// serveur confirmé), et signale au joueur toute écriture abandonnée après
/// un refus non rejouable répété ([_notifyAbandonedWrites], D34 du registre
/// de dette technique) — voir
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
@Riverpod(keepAlive: true)
CharacterWriteSyncCoordinator characterWriteSyncCoordinator(Ref ref) {
  final coordinator = CharacterWriteSyncCoordinator(ref);
  coordinator.start();
  ref.onDispose(coordinator.dispose);
  return coordinator;
}

class CharacterWriteSyncCoordinator {
  CharacterWriteSyncCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<bool>? _subscription;

  void start() {
    unawaited(_sync());
    _subscription = _ref
        .read(connectivityCheckerProvider)
        .onConnectivityRestored
        .listen((_) => unawaited(_sync()));
  }

  final StreamController<ServerValueConflict> _conflicts =
      StreamController<ServerValueConflict>.broadcast();

  /// Modifications concurrentes détectées au rejeu (F19/D178) : le serveur
  /// avait changé depuis la mise en file, l'écriture en file a été rejouée
  /// quand même (alerte **non bloquante**, jamais un blocage). Flux en
  /// mémoire, sans abonné par défaut : consommé plus tard par l'alerte de la
  /// tranche T8 du chantier hors-ligne.
  Stream<ServerValueConflict> get conflicts => _conflicts.stream;

  Future<void> _sync() async {
    final report = await _ref
        .read(pendingCharacterWriteSyncerProvider)
        .syncWithReport();
    // Synchronisés ET abandonnés (D186) : une entrée abandonnée cesse d'être
    // superposée à la fiche, mais une fiche déjà affichée ne le sait pas
    // tant qu'elle n'est pas relue.
    for (final characterId in {
      ...report.synced,
      ...report.abandonedCharacterIds,
    }) {
      _ref.invalidate(characterDetailProvider(characterId));
    }
    if (!_conflicts.isClosed) report.conflicts.forEach(_conflicts.add);
    await _notifyAbandonedWrites();
  }

  /// Signale au joueur, par un `SnackBar` global (voir
  /// [scaffoldMessengerKeyProvider] — même mécanisme que
  /// `PushTokenRegistrar._showForegroundMessage` : ce coordinateur n'a pas
  /// de `BuildContext` propre, la fiche concernée n'étant pas forcément
  /// ouverte), toute écriture en file abandonnée depuis le dernier passage
  /// (D34 du registre de dette technique — voir
  /// `PendingCharacterWriteSyncer.sync`/`PendingCharacterWriteQueue
  /// .recordNonRetryableFailure`) : sans ce signal, un refus non rejouable
  /// (contrainte, RLS, personnage modifié ailleurs) resterait invisible au
  /// joueur après son retrait silencieux de la file.
  ///
  /// Appelée après chaque [_sync] (démarrage et retour de connectivité),
  /// pas seulement quand `pendingCharacterWriteSyncerProvider.sync` vient
  /// d'abandonner une entrée : une entrée déjà abandonnée lors d'un passage
  /// précédent (ex. app tuée avant d'avoir pu afficher le message) reste
  /// consommée ici à la prochaine occasion.
  ///
  /// Best-effort (comme [_sync]) : une erreur ici (pas de session active,
  /// lecture locale en échec) ne doit jamais empêcher la synchro elle-même.
  ///
  /// N'appelle [PendingCharacterWriteQueue.consumeAbandonedMessages] (qui
  /// **supprime** les lignes en base, irréversible) que si un
  /// `ScaffoldMessengerState` est déjà attaché à [scaffoldMessengerKeyProvider] :
  /// ce coordinateur est instancié très tôt (`NexusJdrApp.build`, avant que
  /// `MaterialApp.router` n'ait fini de construire/monter son arbre — voir
  /// `main.dart`), donc le tout premier passage de [_sync] au démarrage peut
  /// s'exécuter alors que la clé n'a pas encore de `currentState`. Sans cette
  /// garde, les messages seraient consommés (donc perdus) sans jamais avoir
  /// été montrés, à l'encontre de la garantie documentée sur
  /// [PendingCharacterWrites]. Si le messenger n'est pas encore prêt, cette
  /// méthode ne fait rien cette fois-ci : un prochain passage de [_sync]
  /// (prochain retour de connectivité, ou prochain démarrage) retentera —
  /// limite résiduelle acceptée : un très léger délai avant le tout premier
  /// affichage possible d'un message d'abandon.
  Future<void> _notifyAbandonedWrites() async {
    try {
      final ownerId = _ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (ownerId == null) return;

      final messenger = _ref.read(scaffoldMessengerKeyProvider).currentState;
      if (messenger == null) return;

      final abandoned = await _ref
          .read(pendingCharacterWriteQueueProvider)
          .consumeAbandoned(ownerId: ownerId);
      for (final entry in abandoned) {
        // Aussi pour une entrée abandonnée lors d'un passage précédent
        // (app tuée avant l'affichage) : sa fiche doit être relue.
        _ref.invalidate(characterDetailProvider(entry.characterId));
        messenger.showSnackBar(SnackBar(content: Text(entry.message)));
      }
    } catch (_) {
      // Best-effort — voir la documentation de cette méthode.
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_conflicts.close());
  }
}
