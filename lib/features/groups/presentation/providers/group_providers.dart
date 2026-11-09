import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/group_repository.dart';
import '../../domain/group_detail.dart';
import '../../domain/group_note_entry.dart';
import '../../domain/group_preview.dart';
import '../../domain/group_summary.dart';
import '../../domain/group_treasure.dart';

part 'group_providers.g.dart';

@Riverpod(keepAlive: true)
GroupRepository groupRepository(Ref ref) {
  return SupabaseGroupRepository(ref.watch(supabaseClientProvider));
}

/// Groupes du joueur connecté — bouton "groupes" de
/// `character_list_screen.dart` (0/1/2+ groupes). `autoDispose` (défaut du
/// générateur), `retry: null` : même rationale que `charactersProvider`.
@Riverpod(retry: _noRetry)
Future<List<GroupSummary>> myGroups(Ref ref) {
  return ref.watch(groupRepositoryProvider).fetchMyGroups();
}

/// Détail d'un groupe — écran "Groupe", famille par [groupId]. `autoDispose`,
/// `retry: null` : mêmes rationales que [myGroups].
@Riverpod(retry: _noRetry)
Future<GroupDetail> groupDetail(Ref ref, String groupId) {
  return ref.watch(groupRepositoryProvider).fetchGroupDetail(groupId);
}

/// Butin commun d'un groupe — onglet "Butin", famille par [groupId].
@Riverpod(retry: _noRetry)
Future<GroupTreasure> groupTreasure(Ref ref, String groupId) {
  return ref.watch(groupRepositoryProvider).fetchGroupTreasure(groupId);
}

/// Entrées du carnet de notes personnel d'un membre pour un groupe — onglet
/// "Notes", famille par [groupId]. `autoDispose`, `retry: null` : mêmes
/// rationales que [myGroups].
///
/// Remplace l'ancien `groupNoteProvider` (une unique note par membre) —
/// voir `GroupRepository.fetchGroupNoteEntries` : la RLS filtre déjà par
/// `auth.uid() = user_id`, donc un MJ sans personnage (voir
/// `GroupMember.isGameMaster`) a ici aussi son propre carnet, comme
/// n'importe quel membre (décision du comité de revue F02(a),
/// `docs/retours-utilisateurs.md`).
@Riverpod(retry: _noRetry)
Future<List<GroupNoteEntry>> groupNoteEntries(Ref ref, String groupId) {
  return ref.watch(groupRepositoryProvider).fetchGroupNoteEntries(groupId);
}

/// Aperçu d'un groupe (étape 2/3 "Confirmation" du flux "Rejoindre un
/// groupe"), en famille par [code] — même rationale que
/// `storyInvitePreviewProvider` (`features/join_story/presentation/
/// providers/join_story_providers.dart`) : `autoDispose`, `retry: null`
/// (l'écran expose son propre bouton "Réessayer"/"Modifier le code").
@Riverpod(retry: _noRetry)
Future<GroupPreview> groupInvitePreview(Ref ref, {required String code}) {
  return ref.watch(groupRepositoryProvider).previewGroupInvite(code);
}

Duration? _noRetry(int retryCount, Object error) => null;

/// Abonnement Realtime aux membres du groupe [groupId] (voir
/// `GroupRepository.subscribeToMemberUpdates`) — provider "à effet de bord
/// pur" (aucune valeur exploitée par l'appelant), à `ref.watch` depuis l'écran
/// "Groupe" pour que l'abonnement suive exactement son cycle de vie :
/// souscrit dès que [groupDetailProvider] résout une liste de membres non
/// vide, se désabonne (`ref.onDispose`) à la fermeture de l'écran — **jamais
/// `keepAlive`** (première utilisation de Supabase Realtime dans ce dépôt,
/// contrairement aux coordinateurs `keepAlive` existants comme
/// `CharacterWriteSyncCoordinator`, qui vivent toute la durée de l'app).
///
/// Volontairement **pas de `ref.watch(groupDetailProvider(groupId))`** :
/// `groupDetailProvider` transite loading→data à chaque simple mise à jour
/// de PV d'un coéquipier (via l'invalidation déclenchée par [onChanged]
/// lui-même), et un `ref.watch` reconstruirait ce provider — donc
/// désabonnerait/réabonnerait tout le channel Supabase — à chaque
/// transition, créant une fenêtre où un évènement pourrait être manqué
/// pendant le re-handshake WebSocket. Le cycle de vie du channel ne doit
/// dépendre QUE de la liste de `characterIds`, jamais du reste de l'état de
/// [groupDetailProvider] : on utilise donc `ref.listen` (effet de bord) et on
/// ne recrée l'abonnement que lorsque la liste de personnages à surveiller a
/// réellement changé (un membre rejoint/quitte le groupe).
///
/// Depuis les corrections des bugs F07/F08 (`docs/retours-utilisateurs.md`),
/// le même canal Realtime écoute aussi `group_members` (voir
/// `GroupRepository.subscribeToMemberUpdates`) : `INSERT` filtré sur
/// [groupId] (arrivée d'un membre, qui ne modifie jamais la table
/// `characters` déjà surveillée), et `DELETE` **sans filtre `group_id`**
/// (départ/exclusion). Pourquoi : `group_members` est en REPLICA IDENTITY
/// DEFAULT, l'ancienne ligne d'un `DELETE` ne contient que la clé primaire
/// `id`, donc un filtre `group_id` ne correspondrait jamais ; REPLICA
/// IDENTITY FULL est refusé car Realtime n'applique pas la RLS aux `DELETE`
/// (tout utilisateur authentifié lirait `user_id`/`character_id` des départs
/// d'autres groupes). Le tri se fait donc ici : un `DELETE` n'invalide
/// [groupDetailProvider] que si son `id` est celui d'un membre actuellement
/// affiché ([GroupDetail.memberRowIds]). **Effectif uniquement une fois la
/// migration web `fix/enable-realtime-group-members` déployée** (publication de
/// `group_members` sur `supabase_realtime`) — tant que ce n'est pas le cas,
/// ce flux ne reçoit simplement jamais d'évènement, sans régression.
@riverpod
void groupMembersRealtimeWatcher(Ref ref, String groupId) {
  final repository = ref.watch(groupRepositoryProvider);
  GroupRealtimeSubscription? subscription;
  List<String>? subscribedCharacterIds;

  void syncSubscription(List<String>? characterIds) {
    if (characterIds == null || characterIds.isEmpty) {
      final previousSubscription = subscription;
      subscription = null;
      subscribedCharacterIds = null;
      if (previousSubscription != null) {
        unawaited(previousSubscription.cancel());
      }
      return;
    }
    if (_sameCharacterIds(subscribedCharacterIds, characterIds)) return;

    final previousSubscription = subscription;
    subscribedCharacterIds = characterIds;
    subscription = repository.subscribeToMemberUpdates(
      groupId: groupId,
      characterIds: characterIds,
      isKnownMembershipId: (membershipId) =>
          ref
              .read(groupDetailProvider(groupId))
              .value
              ?.memberRowIds
              .contains(membershipId) ??
          false,
      onChanged: () {
        if (ref.mounted) ref.invalidate(groupDetailProvider(groupId));
      },
    );
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }
  }

  ref.listen(
    groupDetailProvider(groupId),
    (previous, next) => syncSubscription(next.value?.memberCharacterIds),
    fireImmediately: true,
  );

  ref.onDispose(() {
    unawaited(subscription?.cancel());
  });
}

/// Égalité "ensemble" (ordre indifférent) de deux listes d'identifiants —
/// évite de recréer l'abonnement Realtime pour un simple réordonnancement
/// de [GroupDetail.members] qui ne change pas la composition réelle du
/// groupe. `null` seulement si les deux le sont (voir
/// [groupMembersRealtimeWatcher]).
bool _sameCharacterIds(List<String>? a, List<String>? b) {
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  final setA = a.toSet();
  return setA.length == b.toSet().length && setA.containsAll(b);
}
