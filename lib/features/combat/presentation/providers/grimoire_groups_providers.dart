import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../groups/data/group_membership_repository.dart';
import '../../domain/grimoire_combat_session.dart';
import 'combat_callout_providers.dart';
import 'combat_providers.dart';
import 'grimoire_combat_providers.dart';

/// Lecture des groupes du joueur (surchargeable en test).
final groupMembershipRepositoryProvider = Provider<GroupMembershipRepository>(
  (ref) => SupabaseGroupMembershipRepository(ref.watch(supabaseClientProvider)),
);

/// Écart minimal entre deux relectures déclenchées par un écran qui montre un
/// groupe inconnu de [myGroupMembershipsProvider] (ou un autre personnage).
const Duration kGroupMembershipsSeenRefreshGap = Duration(seconds: 30);

/// Délai maximal du contrôle d'appartenance avant d'ouvrir un combat depuis
/// une notification ; au-delà, l'appartenance est inconnue.
const Duration kGroupMembershipCheckTimeout = Duration(seconds: 5);

/// Groupes du joueur connecté (groupe, nom, personnage courant) : **cache
/// mémoire** (jamais persisté), `null` tant qu'aucune lecture n'a abouti.
///
/// Relu au premier accès, au retour au premier plan, au retour du réseau, et
/// quand un écran montre un groupe absent de la liste (groupe créé ou
/// rejoint, personnage changé : [noteGroupSeen]). Hors ligne ou en erreur, la
/// dernière liste connue est gardée. Un groupe d'où le joueur est exclu
/// (`group_not_found` sur son canal) en est retiré tout de suite ([forget]).
/// Purgé au changement de compte.
final myGroupMembershipsProvider =
    NotifierProvider<MyGroupMembershipsNotifier, List<GroupMembership>?>(
      MyGroupMembershipsNotifier.new,
    );

class MyGroupMembershipsNotifier extends Notifier<List<GroupMembership>?> {
  Future<bool>? _inFlight;
  int _epoch = 0;
  final Map<String, DateTime> _seenRefreshAt = {};

  @override
  List<GroupMembership>? build() {
    _epoch++;
    _inFlight = null;
    _seenRefreshAt.clear();
    ref
      ..listen<String?>(currentUserProvider.select((user) => user?.id), (
        previous,
        next,
      ) {
        if (previous != next) ref.invalidateSelf();
      })
      ..listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
        if (previous?.value == false && next.value == true) {
          unawaited(refresh());
        }
      });
    final observer = _ResumeObserver(() => unawaited(refresh()));
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return null;
  }

  /// Relit les groupes (une seule lecture à la fois). `true` si la lecture a
  /// abouti, `false` sinon (hors ligne, erreur, déconnecté) : la dernière
  /// liste connue est alors gardée.
  Future<bool> refresh() {
    final running = _inFlight;
    if (running != null) return running;
    final epoch = _epoch;
    final future = _fetch(epoch);
    _inFlight = future;
    return future.whenComplete(() {
      if (epoch == _epoch) _inFlight = null;
    });
  }

  Future<bool> _fetch(int epoch) async {
    try {
      if (ref.read(currentUserProvider) == null) return false;
      final memberships = await ref
          .read(groupMembershipRepositoryProvider)
          .fetchMyMemberships();
      if (!ref.mounted || epoch != _epoch) return false;
      // Même contenu : aucune notification (le suivi des groupes ne se
      // reconstruit pas à chaque retour au premier plan).
      if (!listEquals(state, memberships)) {
        state = List.unmodifiable(memberships);
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Le joueur est-il membre de [groupId] ? Relecture d'abord ; `null` si
  /// elle n'aboutit pas (hors ligne, délai) : l'appartenance est inconnue,
  /// jamais supposée perdue.
  Future<bool?> isMember(String groupId) async {
    final fresh = await refresh().timeout(
      kGroupMembershipCheckTimeout,
      onTimeout: () => false,
    );
    if (!fresh || !ref.mounted) return null;
    return state?.any((membership) => membership.groupId == groupId) ?? false;
  }

  /// Un écran montre le groupe [groupId] (le joueur en est membre) avec le
  /// personnage [characterId] : relecture si ce groupe est inconnu ou si le
  /// personnage a changé (au plus toutes les 30 s par groupe). Sans effet
  /// avant la première lecture.
  void noteGroupSeen(String groupId, {required String? characterId}) {
    final current = state;
    if (current == null) return;
    for (final membership in current) {
      if (membership.groupId == groupId &&
          membership.characterId == characterId) {
        return;
      }
    }
    _refreshForGroup(groupId);
  }

  /// Une notification parle du groupe [groupId] : relecture s'il est absent
  /// de la liste (au plus toutes les 30 s par groupe), pour afficher son nom.
  void ensureKnown(String groupId) {
    final current = state;
    if (current == null ||
        current.any((membership) => membership.groupId == groupId)) {
      return;
    }
    _refreshForGroup(groupId);
  }

  void _refreshForGroup(String groupId) {
    final now = ref.read(combatClockProvider)();
    final last = _seenRefreshAt[groupId];
    if (last != null &&
        now.difference(last) < kGroupMembershipsSeenRefreshGap) {
      return;
    }
    _seenRefreshAt[groupId] = now;
    unawaited(refresh());
  }

  /// Le joueur ne fait plus partie de [groupId] (exclusion vue sur son
  /// canal) : retiré de la liste sans attendre la prochaine relecture.
  void forget(String groupId) {
    final current = state;
    if (current == null ||
        !current.any((membership) => membership.groupId == groupId)) {
      return;
    }
    state = List.unmodifiable([
      for (final membership in current)
        if (membership.groupId != groupId) membership,
    ]);
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// Suit le combat Grimoire de **tous** les groupes du joueur tant que l'app
/// est au premier plan (`docs/combat-grimoire-ui.md` §13, arbitrage Q2) :
/// sans lui, aucun signal hors de l'écran du groupe.
///
/// - **Un canal par groupe**, celui de [grimoireCombatWatcherProvider],
///   partagé avec les écrans (Groupe, Combat, fiche) : le même contrôleur
///   sérialisé, les mêmes garanties. En arrière-plan, chaque canal est
///   quitté (aucun canal, aucune présence) ; au retour, réabonnement et
///   `state_request`.
/// - **Aucune connexion de plus** : le client Realtime multiplexe tous les
///   canaux sur un seul WebSocket.
/// - Identité du joueur transmise à chaque suivi (personnage courant du
///   groupe) : une demande d'initiative est reconnue sans ouvrir l'écran.
/// - Évènements reçus transmis à [combatCalloutControllerProvider] (signal
///   global) ; exclusion d'un groupe : retiré de la liste.
/// - Changement de compte : liste relue, anciens canaux fermés, signal
///   effacé.
///
/// Décision 61 : seul le combat Grimoire produit un signal ; l'écran ouvert
/// depuis le signal l'affiche en priorité sur un combat natif.
///
/// `autoDispose`, observé par `NexusJdrApp` (vit tant que l'app est montée).
final grimoireGroupsFollowerProvider = Provider.autoDispose<void>((ref) {
  final callouts = ref.read(combatCalloutControllerProvider.notifier);
  ref.listen<String?>(currentUserProvider.select((user) => user?.id), (
    previous,
    next,
  ) {
    if (previous != next) callouts.reset();
  });
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return;
  final memberships = ref.watch(myGroupMembershipsProvider);
  if (memberships == null) return;
  final membershipsNotifier = ref.read(myGroupMembershipsProvider.notifier);
  ref.listen<List<GroupMembership>?>(myGroupMembershipsProvider, (
    previous,
    next,
  ) {
    final kept = {
      for (final membership in next ?? const []) membership.groupId,
    };
    for (final membership in previous ?? const <GroupMembership>[]) {
      if (!kept.contains(membership.groupId)) {
        callouts.groupGone(membership.groupId);
      }
    }
  });
  for (final membership in memberships) {
    final groupId = membership.groupId;
    final me = (userId: userId, characterId: membership.characterId);
    ref
      ..watch(grimoireCombatWatcherProvider(groupId))
      ..listen<GrimoireCombatSession>(grimoireCombatProvider(groupId), (
        previous,
        next,
      ) {
        if (next.isExcluded && previous?.isExcluded != true) {
          membershipsNotifier.forget(groupId);
        }
        callouts.onSession(groupId, previous, next, me: me);
      });
  }
  // Jamais d'écriture dans un autre fournisseur pendant cette construction.
  Future.microtask(() {
    if (!ref.mounted) return;
    for (final membership in memberships) {
      ref.read(grimoireCombatProvider(membership.groupId).notifier).setIdentity(
        (userId: userId, characterId: membership.characterId),
      );
    }
  });
});
