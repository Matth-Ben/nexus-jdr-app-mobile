import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/connectivity_providers.dart';
import 'character_detail_provider.dart';
import 'character_providers.dart';

part 'character_write_sync_coordinator.g.dart';

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

  Future<void> _sync() async {
    final syncedCharacterIds = await _ref
        .read(pendingCharacterWriteSyncerProvider)
        .sync();
    for (final characterId in syncedCharacterIds) {
      _ref.invalidate(characterDetailProvider(characterId));
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel());
  }
}
