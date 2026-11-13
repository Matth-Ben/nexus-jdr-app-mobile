import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../data/combat_error_mapper.dart';
import '../../data/combat_repository.dart';
import '../../domain/combat.dart';
import '../../domain/combat_enums.dart';
import '../../domain/combat_failure.dart';
import '../../domain/combat_participant.dart';
import '../../domain/combat_snapshot.dart';
import '../../domain/combat_view_state.dart';

part 'combat_providers.g.dart';

@Riverpod(keepAlive: true)
CombatRepository combatRepository(Ref ref) {
  return SupabaseCombatRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(connectivityCheckerProvider),
  );
}

/// Délai de debounce des refetchs déclenchés par Realtime (une rafale
/// d'évènements — ex. `add_npc_participants` ×20 — ne produit qu'un refetch).
/// Surchargeable en test.
@Riverpod(keepAlive: true)
Duration combatRefetchDebounce(Ref ref) => const Duration(milliseconds: 300);

/// Horloge injectée (horodatage du dernier état connu). Surchargeable en test.
@Riverpod(keepAlive: true)
DateTime Function() combatClock(Ref ref) => DateTime.now;

Duration? _noRetry(int retryCount, Object error) => null;

/// État du combat du groupe [groupId] : chargement / aucun combat / actif /
/// terminé récemment / erreur, avec horodatage du dernier état connu et
/// drapeau « périmé / lecture seule » quand le dernier refetch a échoué (hors
/// ligne...).
///
/// `keepAlive` : le dernier état est gardé **en mémoire** (jamais persisté,
/// pas de cache drift) pour que l'écran Groupe et la fiche l'affichent
/// immédiatement. Limite connue : il n'est pas purgé à la déconnexion tant que
/// le conteneur vit (voir le rapport de la PR1).
///
/// Stratégie Realtime : « notification de changement puis refetch complet »
/// ([scheduleRefresh] debouncé, [refresh] immédiat). Un seul refetch à la
/// fois : un évènement reçu pendant un refetch en marque un suivant, il n'en
/// lance jamais un second en parallèle. Le tour en cours vient toujours du
/// serveur.
@Riverpod(keepAlive: true, name: 'combatProvider', retry: _noRetry)
class CombatNotifier extends _$CombatNotifier {
  Future<void>? _inFlight;
  bool _dirty = false;
  Timer? _debounce;

  @override
  CombatViewState build(String groupId) {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return CombatViewState.loading;
  }

  CombatRepository get _repository => ref.read(combatRepositoryProvider);

  /// Refetch complet immédiat. Si un refetch est déjà en cours, en programme
  /// un seul suivant (jamais deux en parallèle) et rend le futur en cours.
  Future<void> refresh() {
    final running = _inFlight;
    if (running != null) {
      _dirty = true;
      return running;
    }
    final future = _runRefresh();
    _inFlight = future;
    return future;
  }

  Future<void> _runRefresh() async {
    try {
      do {
        _dirty = false;
        await _fetchOnce();
      } while (_dirty && ref.mounted);
    } finally {
      _inFlight = null;
    }
  }

  /// Refetch debouncé (appelé à chaque notification Realtime).
  void scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(ref.read(combatRefetchDebounceProvider), () {
      if (ref.mounted) unawaited(refresh());
    });
  }

  Future<void> _fetchOnce() async {
    try {
      final snapshot = await _repository.fetchActiveCombat(groupId);
      if (!ref.mounted) return;
      final now = ref.read(combatClockProvider)();
      final previous = state;
      if (snapshot != null) {
        state = CombatViewState(
          phase: CombatPhase.active,
          snapshot: snapshot,
          lastKnownAt: now,
        );
      } else if (previous.phase == CombatPhase.active &&
          previous.snapshot != null) {
        final last = previous.snapshot!;
        state = CombatViewState(
          phase: CombatPhase.ended,
          snapshot: last.copyWith(
            combat: last.combat.copyWith(
              status: CombatStatus.ended,
              endedAt: last.combat.endedAt ?? now,
            ),
          ),
          lastKnownAt: now,
        );
      } else if (previous.phase == CombatPhase.ended) {
        state = previous.copyWith(
          lastKnownAt: now,
          isStale: false,
          failure: null,
        );
      } else {
        state = CombatViewState(phase: CombatPhase.none, lastKnownAt: now);
      }
    } catch (error) {
      if (!ref.mounted) return;
      final failure = mapCombatUnknownError(error);
      final previous = state;
      state = previous.phase == CombatPhase.loading
          ? CombatViewState(phase: CombatPhase.error, failure: failure)
          : previous.copyWith(isStale: true, failure: failure);
    }
  }

  /// Lance un combat (MJ) puis resynchronise.
  Future<Combat> startCombat() => _act(() => _repository.startCombat(groupId));

  /// Termine le combat actif (propriétaire) puis resynchronise.
  Future<Combat> endCombat() =>
      _act(() => _repository.endCombat(_requireActive().combat.id));

  /// Saisit/corrige **sa** propre initiative.
  Future<CombatParticipant> setMyInitiative(int initiative) => _act(
    () => _repository.setMyInitiative(
      combatId: _requireActive().combat.id,
      initiative: initiative,
    ),
  );

  /// MJ : fixe (ou efface avec `null`) l'initiative d'un participant.
  Future<CombatParticipant> setParticipantInitiative(
    String participantId,
    int? initiative,
  ) => _act(
    () => _repository.setParticipantInitiative(
      participantId: participantId,
      initiative: initiative,
    ),
  );

  /// MJ : ajoute [count] PNJ (nom + initiative, sans PV).
  Future<List<CombatParticipant>> addNpcParticipants({
    required String baseName,
    int? initiative,
    int count = 1,
  }) => _act(
    () => _repository.addNpcParticipants(
      combatId: _requireActive().combat.id,
      baseName: baseName,
      initiative: initiative,
      count: count,
    ),
  );

  /// MJ : retire un participant (retrait logique).
  Future<CombatParticipant> removeParticipant(String participantId) =>
      _act(() => _repository.removeParticipant(participantId));

  /// MJ : déplace un participant (départage une égalité).
  Future<List<CombatParticipant>> reorderParticipant({
    required String participantId,
    required int newSortOrder,
  }) => _act(
    () => _repository.reorderParticipant(
      participantId: participantId,
      newSortOrder: newSortOrder,
    ),
  );

  CombatSnapshot _requireActive() {
    final snapshot = state.snapshot;
    if (state.phase != CombatPhase.active || snapshot == null) {
      throw const CombatFailure(CombatFailureKind.combatNotFound);
    }
    return snapshot;
  }

  /// Appelle le dépôt puis refetch complet. Un échec métier (état serveur
  /// différent de celui affiché) déclenche aussi un refetch pour réaligner
  /// l'écran, puis est relancé tel quel (jamais pour un échec de connexion).
  Future<T> _act<T>(Future<T> Function() call) async {
    final T result;
    try {
      result = await call();
    } on CombatFailure catch (failure) {
      if (!failure.isConnectivity && ref.mounted) unawaited(refresh());
      rethrow;
    }
    if (ref.mounted) await refresh();
    return result;
  }
}

/// Abonnement Realtime du combat du groupe [groupId] — provider à effet de
/// bord pur, à `ref.watch` depuis l'écran Groupe ou la fiche : il ne vit que
/// tant qu'ils l'observent (`autoDispose`) ET que l'app est au premier plan
/// (`WidgetsBindingObserver` : désabonnement en arrière-plan, réabonnement +
/// resync complet au retour). Un resync complet a aussi lieu à chaque
/// (re)connexion du canal et au retour du réseau.
///
/// Ne dépend que de dépôts `keepAlive` stables : il n'est jamais reconstruit
/// par les changements de l'état du combat (pas de désabonnement/réabonnement
/// parasite).
@riverpod
void combatRealtimeWatcher(Ref ref, String groupId) {
  final repository = ref.watch(combatRepositoryProvider);
  final connectivity = ref.watch(connectivityCheckerProvider);
  CombatRealtimeSubscription? subscription;

  CombatNotifier notifier() => ref.read(combatProvider(groupId).notifier);

  void subscribe() {
    if (subscription != null) return;
    subscription = repository.subscribeToCombatUpdates(
      groupId: groupId,
      onChanged: () {
        if (ref.mounted) notifier().scheduleRefresh();
      },
      onSubscribed: () {
        if (ref.mounted) unawaited(notifier().refresh());
      },
    );
  }

  void unsubscribe() {
    final current = subscription;
    subscription = null;
    if (current != null) unawaited(current.cancel());
  }

  final observer = _CombatLifecycleObserver(
    onForeground: () {
      subscribe();
      unawaited(notifier().refresh());
    },
    onBackground: unsubscribe,
  );
  final binding = WidgetsBinding.instance..addObserver(observer);
  final lifecycle = binding.lifecycleState;
  if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
    subscribe();
  }

  final restoredSub = connectivity.onConnectivityRestored.listen((_) {
    if (subscription != null && ref.mounted) unawaited(notifier().refresh());
  });

  ref.onDispose(() {
    binding.removeObserver(observer);
    unawaited(restoredSub.cancel());
    unsubscribe();
  });
}

class _CombatLifecycleObserver with WidgetsBindingObserver {
  _CombatLifecycleObserver({
    required this.onForeground,
    required this.onBackground,
  });

  final void Function() onForeground;
  final void Function() onBackground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onForeground();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        onBackground();
      case AppLifecycleState.inactive:
        break;
    }
  }
}

/// Informations minimales du bandeau « Combat en cours · round N » (écran
/// Groupe, fiche du personnage). Un record : égalité structurelle, donc
/// `select` ne reconstruit le bandeau que si l'un de ces champs change.
typedef CombatBannerInfo = ({String combatId, int round, bool isStale});

/// Combat actif du groupe [groupId], pour le bandeau de la fiche : `null` si
/// aucun combat actif. **Rebuild ciblé** (`select`) : les changements sans
/// rapport (ex. initiative d'un participant) ne reconstruisent pas le bandeau
/// ni la fiche. Maintient aussi l'abonnement Realtime tant qu'il est observé.
///
/// Retrouver le groupe d'un personnage n'existe pas encore dans `groups`
/// (`myGroups` ne liste pas les personnages des groupes) : la PR3 devra
/// fournir ce `groupId`, par exemple une requête `group_members` filtrée sur
/// `character_id` (aucune requête réseau supplémentaire n'est inventée ici).
@riverpod
CombatBannerInfo? combatBanner(Ref ref, String groupId) {
  ref.watch(combatRealtimeWatcherProvider(groupId));
  return ref.watch(
    combatProvider(groupId).select((state) {
      final snapshot = state.snapshot;
      if (state.phase != CombatPhase.active || snapshot == null) return null;
      return (
        combatId: snapshot.combat.id,
        round: snapshot.combat.round,
        isStale: state.isStale,
      );
    }),
  );
}
