import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/sync/sync_activity_provider.dart';
import '../../data/pending_character_write_syncer.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'character_write_sync_coordinator.g.dart';

/// Vit toute la durée de l'app (`keepAlive`, instancié tôt — voir
/// `main.dart`) : orchestre la synchro hors-ligne PV/XP
/// (`PendingCharacterWriteSyncer`) déclenchée par la connectivité, invalide
/// `characterDetailProvider` pour chaque personnage synchronisé avec succès
/// (pour que la fiche, si affichée, se resynchronise proprement avec l'état
/// serveur confirmé), et enregistre comme **alertes persistées**
/// (`SyncAlerts`, affichées par `SyncStatusBanner`) toute écriture abandonnée
/// après un refus non rejouable répété ([_recordAbandonedWrites], D34 du
/// registre de dette technique) et tout conflit F19 — voir
/// `docs/cahier-des-charges/01-architecture-technique.md`, section "Mode
/// hors-ligne".
///
/// Deux déclencheurs, tous deux best-effort (aucune exception ne doit jamais
/// remonter jusqu'à l'appelant de [start]) :
/// - immédiatement au démarrage (des écritures peuvent être restées en
///   attente depuis la dernière fermeture de l'app, avec un réseau déjà
///   revenu depuis — c'est ce qui justifie que le dialogue de sortie Android
///   promette un envoi « à la prochaine ouverture avec du réseau ») ;
/// - à chaque retour de connectivité (`ConnectivityChecker.onConnectivityRestored`).
///
/// Chaque passe signale son activité à `syncActivityProvider` (bandeau
/// « Synchronisation… ») et, si au moins une écriture a abouti, date la
/// dernière synchro réussie (`SyncStateStore`).
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
  bool _disposed = false;

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
  /// mémoire, sans abonné par défaut ; l'alerte **persistée** correspondante
  /// est enregistrée en parallèle ([_recordConflicts]).
  Stream<ServerValueConflict> get conflicts => _conflicts.stream;

  Future<void> _sync() async {
    final activity = _ref.read(syncActivityProvider.notifier);
    // En microtâche : [start] est appelé pendant la construction du provider du
    // coordinateur, où Riverpod interdit de modifier un autre provider. File
    // FIFO : `begin` passe toujours avant le `end` correspondant.
    scheduleMicrotask(() {
      if (!_disposed) activity.begin();
    });
    try {
      final report = await _ref
          .read(pendingCharacterWriteSyncerProvider)
          .syncWithReport();
      if (_disposed) return;
      // Synchronisés ET abandonnés (D186) : une entrée abandonnée cesse
      // d'être superposée à la fiche, mais une fiche déjà affichée ne le sait
      // pas tant qu'elle n'est pas relue.
      for (final characterId in {
        ...report.synced,
        ...report.abandonedCharacterIds,
      }) {
        _ref.invalidate(characterDetailProvider(characterId));
      }
      if (!_conflicts.isClosed) report.conflicts.forEach(_conflicts.add);
      await _recordConflicts(report);
      await _recordAbandonedWrites();
      await _markSuccessIfReplayed(report);
    } finally {
      scheduleMicrotask(() {
        if (!_disposed) activity.end();
      });
    }
  }

  String? get _ownerId =>
      _ref.read(supabaseClientProvider).auth.currentUser?.id;

  /// Date la dernière synchro réussie si la file a effectivement été (en
  /// partie) rejouée. Best-effort.
  Future<void> _markSuccessIfReplayed(SyncReport report) async {
    if (report.synced.isEmpty) return;
    try {
      final ownerId = _ownerId;
      if (ownerId == null) return;
      await _ref.read(syncStateStoreProvider).markSuccess(ownerId);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Enregistre chaque conflit F19 comme alerte persistée. Best-effort.
  Future<void> _recordConflicts(SyncReport report) async {
    if (report.conflicts.isEmpty) return;
    try {
      final ownerId = _ownerId;
      if (ownerId == null) return;
      final recorder = _ref.read(syncAlertRecorderProvider);
      for (final conflict in report.conflicts) {
        await recorder.recordConflict(ownerId: ownerId, conflict: conflict);
      }
    } catch (_) {
      // Best-effort.
    }
  }

  /// Transforme en **alertes persistées** (`SyncAlerts`) toute écriture en
  /// file abandonnée depuis le dernier passage (D34 du registre de dette
  /// technique — voir `PendingCharacterWriteSyncer.sync`/
  /// `PendingCharacterWriteQueue.recordNonRetryableFailure`) : sans ce
  /// signal, un refus non rejouable (contrainte, RLS, personnage modifié
  /// ailleurs) resterait invisible au joueur après son retrait silencieux de
  /// la file. Le `SnackBar` global d'avant la tranche T2 a disparu : le
  /// message n'est plus jamais « consommé » à l'affichage, il vit dans la
  /// table jusqu'à ce que le joueur ferme l'alerte — l'app tuée avant
  /// l'affichage ne perd donc plus rien, et plus aucune garde sur le
  /// `ScaffoldMessenger` n'est nécessaire.
  ///
  /// Appelée après chaque [_sync] (démarrage et retour de connectivité) :
  /// une entrée déjà abandonnée lors d'un passage précédent est reprise ici.
  /// Consommation et insertion de l'alerte sont atomiques
  /// (`SyncAlertRecorder.recordAbandoned`).
  ///
  /// Best-effort (comme [_sync]) : une erreur ici (pas de session active,
  /// lecture locale en échec) ne doit jamais empêcher la synchro elle-même.
  Future<void> _recordAbandonedWrites() async {
    try {
      final ownerId = _ownerId;
      if (ownerId == null) return;
      final abandoned = await _ref
          .read(syncAlertRecorderProvider)
          .recordAbandoned(ownerId);
      for (final entry in abandoned) {
        // Aussi pour une entrée abandonnée lors d'un passage précédent (app
        // tuée avant l'enregistrement) : sa fiche doit être relue.
        _ref.invalidate(characterDetailProvider(entry.characterId));
      }
    } catch (_) {
      // Best-effort — voir la documentation de cette méthode.
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    unawaited(_conflicts.close());
  }
}
