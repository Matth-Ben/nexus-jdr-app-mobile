import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/crash_reporting/crash_reporter.dart';
import '../../../core/utils/uuid_v4.dart';
import '../../characters/data/inventory_catalog_cache.dart';
import '../../characters/domain/character_inventory_item.dart';
import '../../characters/domain/currency_kind.dart';
import '../domain/created_group.dart';
import '../domain/group_character_reassignment_failure.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import '../domain/group_invite_code_generator.dart';
import '../domain/group_invite_failure.dart';
import '../domain/group_note_entry.dart';
import '../domain/group_preview.dart';
import '../domain/group_summary.dart';
import '../domain/group_treasure.dart';
import '../domain/group_treasure_item.dart';
import '../domain/group_treasure_items.dart';
import '../domain/joined_group.dart';
import 'group_character_reassignment_error_mapper.dart';
import 'group_error_mapper.dart';
import 'group_invite_error_mapper.dart';
import 'group_member_row_mapper.dart';
import 'group_treasure_inventory_adapter.dart';

/// Handle d'abonnement Realtime (`GroupRepository.subscribeToMemberUpdates`)
/// — un simple point d'extension pour fermer proprement l'abonnement à la
/// sortie de l'écran "Groupe" (voir `presentation/providers/group_providers.dart`),
/// sans exposer `RealtimeChannel`/`SupabaseClient` directement aux tests de
/// widget.
abstract class GroupRealtimeSubscription {
  Future<void> cancel();
}

/// Passerelle vers les groupes du joueur connecté — tables `groups`/
/// `group_members`/`group_treasure`/`group_notes` et 3 edge functions
/// (`create-group`, `preview-group-invite`, `join-group`), voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) — même
/// principe que `CharacterRepository`/`StoryInviteRepository`.
///
/// **Discipline de lecture des coéquipiers** : la RLS autorise un membre de
/// groupe à lire la ligne ENTIÈRE `characters`/`character_classes`/
/// `character_ability_scores`/`character_inventory`/`character_class_options`
/// d'un coéquipier (nécessaire pour que Supabase Realtime, qui ne diffuse que
/// depuis une vraie policy RLS ligne-par-ligne, fonctionne) — cette
/// implémentation ne sélectionne et n'expose jamais que le sous-ensemble
/// portrait/nom/race/classe/niveau/PV/PV temp./statut/CA (voir
/// [GroupMemberRowMapper]/[fetchGroupDetail]), même si la requête pourrait
/// techniquement lire plus, même discipline que l'app web pour le MJ. La CA
/// est le seul champ dérivé d'une lecture plus large
/// (`character_ability_scores`/`character_inventory`/
/// `character_class_options`, voir la doc de classe de
/// [GroupMemberRowMapper]) : jamais ces champs bruts eux-mêmes, seul l'entier
/// déjà calculé par [GroupMemberRowMapper] est exposé sur [GroupMember].
///
/// Contrairement à `CharacterRepository`, aucune écriture de ce fichier ne
/// passe par une file d'attente hors-ligne (`PendingCharacterWriteQueue`) :
/// le système de groupe n'a pas de mode hors-ligne dédié dans cette
/// itération (non demandé par la spec de la tâche) — un échec réseau lève
/// simplement une [GroupFailure].
abstract class GroupRepository {
  /// Groupes dont le joueur connecté est membre — bouton "groupes" de
  /// `character_list_screen.dart` (0/1/2+ groupes). Joint aussi la vue
  /// `group_character_status_overview` (`dead_count`/`low_hp_count`, voir
  /// la migration `20261106100000_create_group_character_status_overview.sql`
  /// du dépôt web) en une seule requête groupée (`inFilter` sur tous les
  /// `group_id` déjà résolus) — jamais une requête par groupe (voir
  /// `GroupListScreen::GroupStatusBadge` côté UI, qui affiche un badge
  /// priorisé "X mort(s)"/"X PV bas" sur chaque `_GroupRow`).
  ///
  /// Cette requête de statut est isolée dans son propre `try/catch` côté
  /// implémentation : si la vue est temporairement inaccessible, cette
  /// méthode retourne quand même la liste complète des groupes, avec
  /// `deadCount`/`lowHpCount` à 0 pour les groupes concernés — un badge
  /// accessoire en panne ne doit jamais faire échouer tout l'écran
  /// "Groupes".
  Future<List<GroupSummary>> fetchMyGroups();

  /// Identifiants des groupes dont le joueur connecté fait partie avec le
  /// personnage [characterId] (`group_members.character_id`) — une seule
  /// requête ciblée (aucune jointure, aucune écriture), utilisée pour retrouver
  /// le groupe d'un personnage depuis sa fiche (bandeau « Combat en cours »).
  /// Un personnage peut être dans plusieurs groupes ; liste vide s'il n'est
  /// dans aucun.
  Future<List<String>> fetchGroupIdsForCharacter(String characterId);

  /// `create-group` — écran "Créer un groupe" : crée le groupe, son
  /// `group_treasure` (côté serveur) et la ligne `group_members` du créateur
  /// (`role: 'owner'`). [characterId] `null`/vide : le créateur rejoint
  /// comme MJ sans personnage (voir `GroupMember.isGameMaster`) — au plus un
  /// MJ sans personnage par groupe, mais aucun risque de collision ici
  /// (groupe tout juste créé, par construction sans aucun autre membre).
  Future<CreatedGroup> createGroup({required String name, String? characterId});

  /// `preview-group-invite` — étape 2/3 du flux "Rejoindre un groupe" :
  /// résout [code] en un aperçu pur (nom, nombre de membres et titre de la
  /// campagne, `null` sans campagne ou si le serveur ne le renvoie pas), sans
  /// jamais créer d'adhésion. Jamais le résumé (décision n° 33). Lève une
  /// [GroupInviteFailure].
  Future<GroupPreview> previewGroupInvite(String code);

  /// `join-group` — étape 3/3 : crée l'adhésion `group_members`
  /// (`role: 'membre'`) entre [characterId] et le groupe désigné par [code].
  /// [characterId] `null`/vide : le joueur rejoint comme MJ sans personnage
  /// (voir `GroupMember.isGameMaster`). Lève une [GroupInviteFailure], y
  /// compris [GroupInviteFailureKind.alreadyInGroup] et
  /// [GroupInviteFailureKind.mjAlreadyAssigned] (un autre membre a déjà
  /// rejoint ce groupe en tant que MJ sans personnage).
  Future<JoinedGroup> joinGroup({required String code, String? characterId});

  /// Détail complet d'un groupe (identité, campagne associée, membres) —
  /// écran "Groupe". `groups` n'est pas diffusée en temps réel : le titre et
  /// le résumé de la campagne sont relus à chaque lecture du détail
  /// (ouverture de l'écran, rafraîchissement).
  Future<GroupDetail> fetchGroupDetail(String groupId);

  /// "Renommer le groupe" (owner) — écriture directe `UPDATE groups`, RLS
  /// "Owner can update their groups" déjà en place côté serveur.
  Future<void> renameGroup({required String groupId, required String name});

  /// "Régénérer le code" (owner) — génère un nouveau code côté client
  /// ([GroupInviteCodeGenerator]) et l'écrit directement (`UPDATE groups`),
  /// en retentant une poignée de fois en cas de collision improbable sur la
  /// contrainte unique. Retourne le nouveau code.
  Future<String> regenerateInviteCode(String groupId);

  /// "Dissoudre le groupe" (owner) — supprime la ligne `groups`. DeepCore
  /// supprime en cascade `group_members`, `group_treasure`, `group_notes`,
  /// `group_journal_entries`, `combats` et `combat_participants` ; aucune
  /// table de personnages ne dépend de `groups` (les personnages restent
  /// intacts). Refusé par le serveur pendant un combat actif : lève une
  /// [GroupFailure] de code [GroupErrorCode.combatActive].
  Future<void> dissolveGroup(String groupId);

  /// "Quitter le groupe" — supprime la propre ligne `group_members` du
  /// joueur connecté pour ce groupe. Pour le **propriétaire**, refusé par le
  /// serveur pendant un combat actif ([GroupErrorCode.combatActive]) ; un
  /// autre membre peut toujours partir.
  Future<void> leaveGroup(String groupId);

  /// RPC `become_group_game_master` — « Devenir MJ » (propriétaire qui joue
  /// un personnage dans ce groupe) : sa ligne `group_members` passe en MJ
  /// sans personnage (`is_game_master = true`, `character_id = null`). Le
  /// personnage quitte le groupe et reste dans la liste du joueur ; rien
  /// n'est supprimé. Idempotente (déjà MJ : aucune écriture). Action serveur,
  /// jamais mise en file d'attente hors ligne.
  ///
  /// Lève une [GroupFailure] (le `message` du serveur est lu avant le code,
  /// voir `mapGroupError`) : [GroupErrorCode.combatActive],
  /// [GroupErrorCode.mjAlreadyAssigned] (un autre membre est déjà MJ, personne
  /// n'est rétrogradé), [GroupErrorCode.notGroupOwner],
  /// [GroupErrorCode.notMember], [GroupErrorCode.groupNotFound],
  /// [GroupErrorCode.sessionExpired], [GroupErrorCode.transientConflict]
  /// (`40P01`/`40001`), [GroupErrorCode.serverOutdated] (fonction absente :
  /// migration DeepCore `20261119090000` pas encore appliquée) ou
  /// [GroupErrorCode.network].
  Future<void> becomeGroupGameMaster(String groupId);

  /// "Exclure {membre}" (owner) — supprime la ligne `group_members` de
  /// [userId] pour ce groupe. Identifié par `(group_id, user_id)` — unique
  /// par construction (contrainte `unique (group_id, user_id)` posée à la
  /// création de la table, inchangée par PR #26) — plutôt que par
  /// `character_id`, qui est `null` pour un MJ sans personnage
  /// (`GroupMember.isGameMaster`) et ne permettrait donc jamais de l'exclure.
  Future<void> removeMember({required String groupId, required String userId});

  /// `set-group-character` — un membre ORPHELIN (voir
  /// `GroupMember.isAwaitingCharacter`) rattache un nouveau personnage à sa
  /// ligne `group_members` pour continuer à suivre ce groupe. Jamais
  /// utilisable autrement (jamais pour changer de personnage à volonté,
  /// jamais pour "devenir MJ") — voir la doc de l'edge function. Lève une
  /// [GroupCharacterReassignmentFailure].
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  });

  /// Butin commun du groupe — onglet "Butin".
  Future<GroupTreasure> fetchGroupTreasure(String groupId);

  /// Ajoute des objets au butin (tout membre, décision 91) : relit
  /// `group_treasure.items` juste avant d'écrire, fusionne [items] (voir
  /// `GroupTreasureItems.merge`) puis écrit le tableau complet. Donne un
  /// `entry_id` aux entrées anciennes au passage.
  Future<void> addTreasureItems({
    required String groupId,
    required List<GroupTreasureItem> items,
  });

  /// « Modifier » un objet du butin (tout membre, MJ sans personnage
  /// compris) : remplace [expected] (l'entrée telle que le joueur l'a vue) par
  /// [updated]. Relit `items` juste avant d'écrire : si [expected] a disparu ou
  /// changé entre-temps, **rien n'est écrit** et une [GroupFailure] de code
  /// [GroupErrorCode.treasureStale] est levée.
  Future<void> updateTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
    required GroupTreasureItem updated,
  });

  /// « Retirer du butin » (tous les exemplaires, tout membre) : même garde de
  /// concurrence que [updateTreasureItem].
  Future<void> removeTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
  });

  /// Monnaie du butin (ajout, ajustement, retrait, conversion ; tout membre) :
  /// écrit les soldes **absolus** [newTotals] seulement si les soldes touchés
  /// valent encore [expected] (mise à jour conditionnelle, atomique côté
  /// serveur). Sinon rien n'est écrit et une [GroupFailure] de code
  /// [GroupErrorCode.treasureStale] est levée.
  Future<void> setTreasureCurrency({
    required String groupId,
    required Map<CurrencyKind, int> expected,
    required Map<CurrencyKind, int> newTotals,
  });

  /// Fiche d'un objet du butin : [item] vu comme une ligne d'inventaire. Un
  /// objet du catalogue est relu par `item_id` (ligne `items` complète et
  /// description traduite) ; un objet personnalisé porte déjà tout (aucun
  /// appel réseau).
  Future<CharacterInventoryItem> fetchTreasureItemDetails(
    GroupTreasureItem item,
  );

  /// "S'attribuer de la monnaie" — appelle la fonction Postgres
  /// `claim_group_treasure_currency` (décrémentation atomique du butin ET
  /// crédit de `characters.currency_*` de [characterId], dans le même appel
  /// de fonction Postgres — donc atomique dans son ensemble : si le crédit
  /// échoue côté serveur, la décrémentation du butin est annulée avec). La
  /// fonction lève une exception si [characterId] n'appartient pas à
  /// l'appelant ; ce cas anormal (ne devrait jamais se produire depuis cette
  /// app, qui ne passe que le personnage du joueur connecté) est traité
  /// comme n'importe quelle autre erreur serveur par le `catch` ci-dessous,
  /// pas distingué côté UI. Retourne le résultat de la fonction Postgres :
  /// `false` signifie "solde insuffisant ou pas membre", aucune écriture
  /// n'a alors lieu.
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  });

  /// "S'attribuer" un objet du butin — relit `group_treasure.items` juste
  /// avant d'écrire : si [item] (l'entrée telle que le joueur l'a vue) a
  /// disparu ou changé entre-temps, **rien n'est écrit** et une
  /// [GroupFailure] de code [GroupErrorCode.treasureStale] est levée (voir
  /// `GroupTreasureItems.claim`). Sinon ajoute [quantity] exemplaires à
  /// l'inventaire personnel de [characterId] avec **toutes** les données de
  /// l'objet (description, dégâts, colonnes `custom_*`, voir
  /// `GroupTreasureInventoryAdapter.toInsertColumns`), puis écrit le tableau
  /// `items` mis à jour (l'entrée disparaît à 0). **Risque de course
  /// résiduel documenté et accepté** (pas de fonction atomique dédiée pour
  /// les objets, contrairement à [claimTreasureCurrency]) : la fenêtre entre
  /// la relecture et l'écriture reste ouverte.
  ///
  /// **Second mode de défaillance documenté** : les deux écritures (ajout à
  /// l'inventaire personnel, retrait du butin commun) ne sont pas
  /// transactionnelles (pas de fonction Postgres atomique équivalente à
  /// [claimTreasureCurrency] pour les objets, `items` étant un `jsonb`).
  /// L'ordre choisi ci-dessous (INSERT `character_inventory` D'ABORD, puis
  /// UPDATE `group_treasure.items` ENSUITE) est volontaire : si la seconde
  /// écriture échoue après le succès de la première, l'objet se retrouve
  /// dupliqué (visible à la fois dans l'inventaire personnel ET encore
  /// listé dans le butin commun) plutôt que perdu silencieusement (disparu
  /// des deux côtés). Une duplication visible et rattrapable est préférée
  /// à une perte invisible.
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  });

  /// Entrées du carnet de notes personnel du joueur connecté pour ce groupe
  /// (`group_journal_entries`) — onglet "Notes", triées du plus récent au
  /// plus ancien (même convention que
  /// `CharacterDetailRowMapper.parseJournalEntries`). Liste vide tant que
  /// rien n'a encore été enregistré, même repli que [fetchGroupTreasure].
  ///
  /// RLS `auth.uid() = user_id` sur `group_journal_entries` : jamais besoin
  /// de filtrer explicitement par personnage (contrairement à l'ancienne
  /// table `group_notes`) — un MJ sans personnage (voir
  /// `GroupMember.isGameMaster`) a son propre carnet comme n'importe quel
  /// membre (décision du comité de revue F02(a),
  /// `docs/retours-utilisateurs.md`), toujours vrai avec ce fractionnement.
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId);

  /// Insère une nouvelle entrée `group_journal_entries` — "Ajouter une
  /// note" de l'onglet "Notes" (sheet `group_note_entry_edit_sheet.dart`).
  /// [title] optionnel (`null`/vide : pas de titre pour cette entrée).
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  });

  /// Remplace le titre/corps d'une entrée déjà enregistrée — mode édition de
  /// [addGroupNoteEntry]. [title] `null` efface le titre existant (texte
  /// intégral envoyé, jamais un diff — même principe que [addTreasureItems]).
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  });

  /// Supprime une entrée du carnet de notes — action "Supprimer" de la
  /// sheet d'actions d'une ligne de l'onglet "Notes".
  Future<void> deleteGroupNoteEntry(String entryId);

  /// S'abonne (Supabase Realtime, `postgres_changes`) à deux sources sur le
  /// même canal — voir `presentation/providers/group_providers.dart` pour
  /// l'abonnement/désabonnement à l'entrée/la sortie de l'écran "Groupe" :
  /// - `UPDATE` sur `characters`, filtré à [characterIds] : mises à jour des
  ///   personnages déjà membres (PV, statut...) ;
  /// - `INSERT` sur `group_members`, filtré à [groupId] : arrivée d'un
  ///   membre (bug F07, `docs/retours-utilisateurs.md`) ;
  /// - `UPDATE` sur `group_members`, filtré à [groupId] : changement de rôle
  ///   d'un membre, en particulier « Devenir MJ » du propriétaire (étape 3b) ;
  /// - `DELETE` sur `group_members`, **sans filtre `group_id`** : départ/
  ///   exclusion d'un membre (bug F08). `group_members` est en REPLICA
  ///   IDENTITY DEFAULT : l'ancienne ligne d'un `DELETE` ne porte que la clé
  ///   primaire `id`, jamais `group_id`, donc un filtre sur `group_id` ne
  ///   correspond jamais et aucun évènement n'est délivré. Supabase Realtime
  ///   n'applique pas la RLS aux `DELETE` (la ligne n'existe plus) : passer
  ///   en REPLICA IDENTITY FULL laisserait n'importe quel utilisateur
  ///   authentifié lire `user_id`/`character_id` des joueurs qui partent
  ///   d'un autre groupe — refusé. On écoute donc tous les `DELETE` (seul
  ///   l'`id` est reçu, rien de sensible) et on ne déclenche [onChanged] que
  ///   si cet `id` satisfait [isKnownMembershipId] (voir
  ///   [shouldRefreshOnMemberDelete]).
  ///
  /// Les deux flux sur `group_members` exigent que la table soit publiée sur
  /// `supabase_realtime` (migration web `fix/enable-realtime-group-members`).
  ///
  /// [onChanged] est appelé sans argument à chaque évènement pertinent : c'est
  /// à l'appelant de rafraîchir sa propre source de vérité (jamais de mise à
  /// jour optimiste construite depuis le payload brut ici).
  /// [isKnownMembershipId] dit si un `group_members.id` appartient au groupe
  /// courant (évalué à chaque `DELETE`, donc toujours à jour).
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  });
}

/// Décide si un `DELETE` Realtime sur `group_members` concerne le groupe
/// courant : [oldRecord] (REPLICA IDENTITY DEFAULT) ne contient que `id`, qui
/// doit satisfaire [isKnownMembershipId]. Un `id` absent/non textuel ou
/// inconnu est ignoré (suppression sans rapport, d'un autre groupe).
bool shouldRefreshOnMemberDelete(
  Map<String, dynamic> oldRecord,
  bool Function(String membershipId) isKnownMembershipId,
) {
  final id = oldRecord['id'];
  return id is String && isKnownMembershipId(id);
}

class SupabaseGroupRepository implements GroupRepository {
  SupabaseGroupRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async {
    final ownerId = _requireOwnerId();
    try {
      final rows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', ownerId)
          .eq('character_id', characterId);
      return [for (final row in rows) row['group_id'] as String];
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() async {
    final ownerId = _requireOwnerId();

    try {
      final memberRows = await _client
          .from('group_members')
          .select('group_id, groups(id, name, owner_id)')
          .eq('user_id', ownerId);

      final namesById = <String, String>{};
      final founderIdsById = <String, String>{};
      for (final row in memberRows) {
        final group = row['groups'] as Map<String, dynamic>?;
        if (group == null) continue;
        final id = group['id'] as String;
        namesById[id] = (group['name'] as String?) ?? '';
        founderIdsById[id] = (group['owner_id'] as String?) ?? '';
      }
      if (namesById.isEmpty) return const [];

      final groupIds = namesById.keys.toList();

      final allMemberRows = await _client
          .from('group_members')
          .select('group_id')
          .inFilter('group_id', groupIds);
      final counts = <String, int>{};
      for (final row in allMemberRows) {
        final id = row['group_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      // Repli silencieux dédié (badge accessoire) : un échec de CETTE
      // requête (ex. vue temporairement inaccessible) ne doit jamais faire
      // basculer tout l'écran "Groupes" en erreur — seuls les badges
      // dead/lowHp restent à 0/0 pour les groupes concernés, le reste de la
      // liste (déjà résolu ci-dessus) continue de s'afficher normalement.
      final deadCounts = <String, int>{};
      final lowHpCounts = <String, int>{};
      try {
        final statusRows = await _client
            .from('group_character_status_overview')
            .select('group_id, dead_count, low_hp_count')
            .inFilter('group_id', groupIds);
        for (final row in statusRows) {
          final id = row['group_id'] as String;
          deadCounts[id] = (row['dead_count'] as num?)?.toInt() ?? 0;
          lowHpCounts[id] = (row['low_hp_count'] as num?)?.toInt() ?? 0;
        }
      } catch (error) {
        debugPrint(
          'SupabaseGroupRepository.fetchMyGroups: statut multi-groupes '
          'ignoré (badges à 0/0) : $error',
        );
      }

      return [
        for (final entry in namesById.entries)
          GroupSummary(
            id: entry.key,
            name: entry.value,
            memberCount: counts[entry.key] ?? 0,
            founderId: founderIdsById[entry.key] ?? '',
            deadCount: deadCounts[entry.key] ?? 0,
            lowHpCount: lowHpCounts[entry.key] ?? 0,
          ),
      ];
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    String? characterId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-group',
        body: {
          'name': name,
          if (characterId != null && characterId.isNotEmpty)
            'character_id': characterId,
        },
      );
      final data = _asMap(response.data);
      return CreatedGroup(
        id: (data['id'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        inviteCode: (data['invite_code'] as String?) ?? '',
      );
    } on FunctionException catch (error) {
      throw _mapEdgeFunctionError(error);
    } on GroupFailure {
      rethrow;
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<GroupPreview> previewGroupInvite(String code) async {
    try {
      final response = await _client.functions.invoke(
        'preview-group-invite',
        body: {'code': code},
      );
      final data = _asMap(response.data);
      return GroupPreview(
        name: (data['name'] as String?) ?? '',
        memberCount: (data['member_count'] as num?)?.toInt() ?? 0,
        // Absent (fonction antérieure à l'étape 4) : traité comme `null`.
        storyTitle: _optionalString(data['story_title']),
      );
    } on FunctionException catch (error) {
      throw mapGroupInviteError(error);
    } on GroupInviteFailure {
      rethrow;
    } catch (_) {
      throw const GroupInviteFailure(GroupInviteFailureKind.generic);
    }
  }

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    String? characterId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'join-group',
        body: {
          'code': code,
          if (characterId != null && characterId.isNotEmpty)
            'character_id': characterId,
        },
      );
      final data = _asMap(response.data);
      return JoinedGroup(
        groupId: (data['group_id'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
      );
    } on FunctionException catch (error) {
      throw mapGroupInviteError(error);
    } on GroupInviteFailure {
      rethrow;
    } catch (_) {
      throw const GroupInviteFailure(GroupInviteFailureKind.generic);
    }
  }

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    final currentUserId = _requireOwnerId();

    try {
      final groupRow = await _selectGroupRow(groupId);
      if (groupRow == null) {
        throw const GroupFailure(
          'Groupe introuvable.',
          code: GroupErrorCode.groupNotFound,
        );
      }

      final memberRows = await _client
          .from('group_members')
          .select('''
            id,
            character_id,
            user_id,
            role,
            is_game_master,
            display_name:group_members_display_name,
            characters(
              id, name, portrait_url, current_hp, max_hp, temporary_hp,
              is_dead, race_id, armor_class_bonus, conditions,
              character_classes(class_id, subclass_id, level, is_primary),
              character_ability_scores(ability_id, score),
              character_class_options(class_feature_id, chosen_value),
              character_inventory(
                id, item_id, quantity, equipped, is_attuned,
                custom_kind, custom_magic_bonus, custom_ac_base,
                custom_armor_category, custom_weight,
                custom_requires_attunement, custom_weapon_category,
                custom_weapon_range,
                items(
                  category, requires_attunement, ac_bonus, ac_bonus_kind,
                  armor_properties(ac_base, ac_dex_bonus, slot)
                )
              )
            )
          ''')
          .eq('group_id', groupId);

      final raceNames = await _fetchTranslatedNames(
        entityType: 'race',
        entityIds: GroupMemberRowMapper.collectRaceIds(memberRows),
      );
      final classNames = await _fetchTranslatedNames(
        entityType: 'class',
        entityIds: GroupMemberRowMapper.collectClassIds(memberRows),
      );
      // Pour `ArmorClassCalculator.compute` uniquement (Résilience
      // draconique/style de combat Défense) — voir la doc de classe de
      // [GroupMemberRowMapper] pour le rationale de cette exception à la
      // discipline "sous-ensemble restreint".
      final subclassNames = await _fetchTranslatedNames(
        entityType: 'subclass',
        entityIds: GroupMemberRowMapper.collectSubclassIds(memberRows),
      );
      final classFeatureNames = await _fetchTranslatedNames(
        entityType: 'class_feature',
        entityIds: GroupMemberRowMapper.collectClassFeatureIds(memberRows),
      );

      final members = memberRows
          .map(
            (row) => GroupMemberRowMapper.toGroupMember(
              row,
              raceNames: raceNames,
              classNames: classNames,
              subclassNames: subclassNames,
              classFeatureNames: classFeatureNames,
            ),
          )
          .toList();

      return GroupDetail(
        id: groupRow['id'] as String,
        name: (groupRow['name'] as String?) ?? '',
        ownerId: groupRow['owner_id'] as String,
        inviteCode: (groupRow['invite_code'] as String?) ?? '',
        currentUserId: currentUserId,
        members: members,
        storyTitle: _optionalString(groupRow['story_title']),
        storySummaryPublic: _optionalString(groupRow['story_summary_public']),
      );
    } on GroupFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  /// Lit la ligne `groups` avec la campagne associée (`story_title`,
  /// `story_summary_public`, migration DeepCore `20261119120000`).
  /// Tolérance de schéma, même patron que `_selectFeatsWithTags` du dépôt
  /// des personnages : sur une base sans ces colonnes (retour arrière de
  /// DeepCore, SQLSTATE 42703 ou PGRST204), relit sans elles ; l'écran
  /// s'affiche alors sans carte « Campagne ».
  Future<Map<String, dynamic>?> _selectGroupRow(String groupId) async {
    try {
      return await _selectFirstGroupRow(
        groupId,
        'id, name, owner_id, invite_code, story_title, story_summary_public',
      );
    } on PostgrestException catch (error) {
      if (error.code != '42703' && error.code != 'PGRST204') rethrow;
      return _selectFirstGroupRow(groupId, 'id, name, owner_id, invite_code');
    }
  }

  /// `limit(1)` plutôt que `maybeSingle()` : avec `maybeSingle`, postgrest
  /// (2.9) remplace le code SQLSTATE d'une erreur par le statut HTTP
  /// (`'400'`), ce qui empêcherait de reconnaître 42703 ci-dessus.
  Future<Map<String, dynamic>?> _selectFirstGroupRow(
    String groupId,
    String columns,
  ) async {
    final rows = await _client
        .from('groups')
        .select(columns)
        .eq('id', groupId)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    try {
      await _client.from('groups').update({'name': name}).eq('id', groupId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<String> regenerateInviteCode(String groupId) async {
    const maxAttempts = 5;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final code = GroupInviteCodeGenerator.generate();
      try {
        await _client
            .from('groups')
            .update({'invite_code': code})
            .eq('id', groupId);
        return code;
      } on PostgrestException catch (error) {
        // '23505' : violation de contrainte unique (collision improbable) —
        // retente avec un nouveau code tant qu'il reste des tentatives.
        if (error.code == '23505' && attempt < maxAttempts) continue;
        throw mapGroupError(error);
      } catch (_) {
        throw mapUnknownGroupError();
      }
    }
    throw const GroupFailure(
      'Impossible de générer un nouveau code. Réessayez.',
      code: GroupErrorCode.inviteCodeGenerationFailed,
    );
  }

  @override
  Future<void> dissolveGroup(String groupId) async {
    try {
      await _client.from('groups').delete().eq('id', groupId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final ownerId = _requireOwnerId();
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', ownerId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> becomeGroupGameMaster(String groupId) async {
    try {
      // La ligne `group_members` renvoyée n'est pas exploitée : l'appelant
      // relit le détail du groupe (source de vérité unique de l'écran).
      await _client.rpc(
        'become_group_game_master',
        params: {'p_group_id': groupId},
      );
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  }) async {
    try {
      await _client.functions.invoke(
        'set-group-character',
        body: {'group_id': groupId, 'character_id': characterId},
      );
    } on FunctionException catch (error) {
      throw mapGroupCharacterReassignmentError(error);
    } on GroupCharacterReassignmentFailure {
      rethrow;
    } catch (_) {
      throw const GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.generic,
      );
    }
  }

  @override
  Future<GroupTreasure> fetchGroupTreasure(String groupId) async {
    try {
      final row = await _client
          .from('group_treasure')
          .select(
            'group_id, currency_gp, currency_pp, currency_ep, currency_sp, '
            'currency_cp, items',
          )
          .eq('group_id', groupId)
          .maybeSingle();
      if (row == null) {
        return GroupTreasure(groupId: groupId);
      }
      return GroupTreasure(
        groupId: groupId,
        currencyGp: (row['currency_gp'] as num?)?.toInt() ?? 0,
        currencyPp: (row['currency_pp'] as num?)?.toInt() ?? 0,
        currencyEp: (row['currency_ep'] as num?)?.toInt() ?? 0,
        currencySp: (row['currency_sp'] as num?)?.toInt() ?? 0,
        currencyCp: (row['currency_cp'] as num?)?.toInt() ?? 0,
        items: _parseItems(row['items']),
      );
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  /// Tableau jsonb `items` -> entrées ; un élément qui n'est pas un objet
  /// est ignoré (jamais d'exception sur une donnée inattendue).
  static List<GroupTreasureItem> _parseItems(Object? raw) => [
    if (raw is List)
      for (final entry in raw)
        if (entry is Map)
          GroupTreasureItem.fromJson(Map<String, dynamic>.from(entry)),
  ];

  /// Relit `group_treasure.items` juste avant une écriture (garde de
  /// concurrence, décision 91).
  Future<List<GroupTreasureItem>> _readTreasureItems(String groupId) async {
    final row = await _client
        .from('group_treasure')
        .select('items')
        .eq('group_id', groupId)
        .maybeSingle();
    return _parseItems(row?['items']);
  }

  /// Écrit `items` et vérifie qu'une ligne a bien été modifiée : sans ligne
  /// renvoyée (membre retiré du groupe entre la lecture et l'écriture, RLS,
  /// ou groupe dissous), rien n'a été écrit et une [GroupFailure] de code
  /// [GroupErrorCode.notMember] est levée plutôt qu'un faux succès.
  Future<void> _writeTreasureItems(
    String groupId,
    List<GroupTreasureItem> items,
  ) async {
    final rows = await _client
        .from('group_treasure')
        .update({'items': items.map((item) => item.toJson()).toList()})
        .eq('group_id', groupId)
        .select('group_id');
    if (rows.isEmpty) throw _treasureNotWritten;
  }

  static const GroupFailure _treasureNotWritten = GroupFailure(
    "Le butin n'a pas été modifié : tu ne fais peut-être plus partie de ce "
    'groupe.',
    code: GroupErrorCode.notMember,
  );

  static const GroupFailure _treasureStale = GroupFailure(
    'Le butin a été modifié entre-temps par un autre membre.',
    code: GroupErrorCode.treasureStale,
  );

  /// Lit, transforme puis écrit `items` ; [transform] renvoie `null` quand
  /// l'entrée visée a disparu ou changé (rien n'est alors écrit).
  Future<void> _editTreasureItems(
    String groupId,
    List<GroupTreasureItem>? Function(List<GroupTreasureItem> items) transform,
  ) async {
    try {
      final next = transform(await _readTreasureItems(groupId));
      if (next == null) throw _treasureStale;
      await _writeTreasureItems(groupId, next);
    } on GroupFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> addTreasureItems({
    required String groupId,
    required List<GroupTreasureItem> items,
  }) {
    if (items.isEmpty) return Future<void>.value();
    return _editTreasureItems(
      groupId,
      (current) => GroupTreasureItems.merge(current, items),
    );
  }

  @override
  Future<void> updateTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
    required GroupTreasureItem updated,
  }) => _editTreasureItems(
    groupId,
    (current) => GroupTreasureItems.replace(current, expected, updated),
  );

  @override
  Future<void> removeTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
  }) => _editTreasureItems(
    groupId,
    (current) => GroupTreasureItems.remove(current, expected),
  );

  @override
  Future<void> setTreasureCurrency({
    required String groupId,
    required Map<CurrencyKind, int> expected,
    required Map<CurrencyKind, int> newTotals,
  }) async {
    if (newTotals.isEmpty) return;
    try {
      var query = _client
          .from('group_treasure')
          .update({
            for (final entry in newTotals.entries)
              entry.key.columnName: entry.value,
          })
          .eq('group_id', groupId);
      // Mise à jour conditionnelle : seulement si les soldes vus par le
      // joueur n'ont pas changé (aucune ligne renvoyée sinon).
      for (final entry in expected.entries) {
        query = query.eq(entry.key.columnName, entry.value);
      }
      final rows = await query.select('group_id');
      if (rows.isEmpty) throw _treasureStale;
    } on GroupFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<CharacterInventoryItem> fetchTreasureItemDetails(
    GroupTreasureItem item,
  ) async {
    final itemId = item.itemId;
    if (itemId == null) {
      return GroupTreasureInventoryAdapter.toInventoryItem(item);
    }
    try {
      final rows = await _client
          .from('items')
          .select(inventoryCatalogItemColumns)
          .eq('id', itemId)
          .limit(1);
      final descriptions = await _fetchTranslatedValues(
        entityType: 'item',
        fieldName: 'description',
        entityIds: {'$itemId'},
      );
      return GroupTreasureInventoryAdapter.toInventoryItem(
        item,
        itemRow: rows.isEmpty ? null : rows.first,
        description: descriptions['$itemId'],
      );
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  }) async {
    try {
      final result = await _client.rpc(
        'claim_group_treasure_currency',
        params: {
          'p_group_id': groupId,
          'p_character_id': characterId,
          'p_currency': _rpcCurrencyName(currency),
          'p_amount': amount,
        },
      );
      return result == true;
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  }) async {
    try {
      // Entrée disparue ou changée entre-temps (attribuée, modifiée ou
      // retirée par un autre membre) : rien n'est écrit, voir la
      // documentation de [GroupRepository.claimTreasureItem].
      final claim = GroupTreasureItems.claim(
        await _readTreasureItems(groupId),
        item,
        quantity,
      );
      if (claim == null) throw _treasureStale;

      // Ordre volontaire (voir la documentation de [claimTreasureItem]) :
      // l'ajout à l'inventaire personnel D'ABORD, le retrait du butin commun
      // ENSUITE, pour qu'un échec de la seconde écriture produise une
      // duplication visible plutôt qu'une perte silencieuse.
      await _client
          .from('character_inventory')
          .insert(
            GroupTreasureInventoryAdapter.toInsertColumns(
              claim.claimed,
              characterId: characterId,
              inventoryId: generateUuidV4(),
            ),
          );

      await _writeTreasureItems(groupId, claim.items);
    } on GroupFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (error, stackTrace) {
      // Remonté à Crashlytics (dette D13) : transfert d'objet du butin
      // commun vers l'inventaire personnel en deux écritures distinctes
      // (voir le commentaire plus haut dans cette méthode) — un bug
      // silencieux ici est exactement le scénario de duplication/perte
      // documenté, jamais signalé jusqu'ici.
      reportNonFatal(error, stackTrace);
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) async {
    try {
      final rows = await _client
          .from('group_journal_entries')
          .select('id, title, body, created_at')
          .eq('group_id', groupId)
          .order('created_at', ascending: false);
      return [
        for (final row in rows)
          GroupNoteEntry(
            id: row['id'] as String,
            title: row['title'] as String?,
            body: (row['body'] as String?) ?? '',
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
      ];
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) async {
    final userId = _requireOwnerId();
    try {
      await _client.from('group_journal_entries').insert({
        'group_id': groupId,
        'user_id': userId,
        if (title != null && title.isNotEmpty) 'title': title,
        'body': body,
      });
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  }) async {
    try {
      await _client
          .from('group_journal_entries')
          .update({
            'title': (title != null && title.isNotEmpty) ? title : null,
            'body': body,
          })
          .eq('id', entryId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  Future<void> deleteGroupNoteEntry(String entryId) async {
    try {
      await _client.from('group_journal_entries').delete().eq('id', entryId);
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  }) {
    // Pas de retour anticipé sur `characterIds` vide ici : en pratique ce
    // cas n'est jamais atteint. L'unique appelant, `groupMembersRealtimeWatcher`
    // (`group_providers.dart`), retourne lui-même avant d'appeler cette
    // méthode dès que `characterIds` est null ou vide, et `GroupDetail`
    // ne peut de toute façon jamais exposer de liste vide une fois chargé
    // (le créateur du groupe en est toujours membre). Le bloc
    // `if (characterIds.isNotEmpty)` ci-dessous reste donc une garde
    // défensive, pas un cas réellement exercé.

    // Nom de canal unique par abonnement (horodaté) : évite toute collision
    // si un abonnement précédent n'a pas encore fini de se désabonner (ex.
    // navigation rapide entrée/sortie de l'écran "Groupe").
    final channel = _client.channel(
      'group-members-${DateTime.now().microsecondsSinceEpoch}',
    );
    if (characterIds.isNotEmpty) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'characters',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.inFilter,
          column: 'id',
          value: characterIds,
        ),
        callback: (payload) => onChanged(),
      );
    }
    // Bug F07 (`docs/retours-utilisateurs.md`) : l'arrivée d'un membre n'est
    // détectable que sur `group_members` elle-même — un `INSERT` ne touche
    // jamais la table `characters` déjà surveillée ci-dessus. « Devenir MJ »
    // (étape 3b, RPC `become_group_game_master`) est un `UPDATE` de la ligne
    // du propriétaire (`character_id` à null, `is_game_master` à true), lui
    // aussi invisible sur `characters` : sans cet abonnement, les écrans
    // Groupe des coéquipiers restaient périmés. Le nouvel enregistrement
    // porte `group_id` dans les deux cas : filtre serveur possible (et RLS
    // SELECT appliquée par Realtime).
    for (final event in const [
      PostgresChangeEvent.insert,
      PostgresChangeEvent.update,
    ]) {
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (payload) => onChanged(),
      );
    }
    // Bug F08 : le départ (DELETE) ne peut PAS être filtré sur `group_id`.
    // `group_members` est en REPLICA IDENTITY DEFAULT : `oldRecord` ne
    // contient que la PK `id`, donc un filtre `group_id=eq.…` ne correspond
    // jamais et rien n'est délivré. REPLICA IDENTITY FULL est refusé : Realtime
    // n'applique pas la RLS aux DELETE, tout utilisateur authentifié pourrait
    // alors lire `user_id`/`character_id` des départs d'un autre groupe. On
    // écoute donc tous les DELETE (seul `id` transite) et on filtre côté
    // client sur les `id` des membres du groupe courant.
    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'group_members',
      callback: (payload) {
        if (shouldRefreshOnMemberDelete(
          payload.oldRecord,
          isKnownMembershipId,
        )) {
          onChanged();
        }
      },
    );
    channel.subscribe();
    return _RealtimeChannelSubscription(_client, channel);
  }

  /// `'gp'`/`'pp'`/`'ep'`/`'sp'`/`'cp'` — nom attendu par le paramètre
  /// `p_currency` de la fonction Postgres `claim_group_treasure_currency`,
  /// dérivé de `CurrencyKind.columnName` (`'currency_gp'` -> `'gp'`) plutôt
  /// que dupliqué en dur.
  String _rpcCurrencyName(CurrencyKind currency) =>
      currency.columnName.replaceFirst('currency_', '');

  GroupFailure _mapEdgeFunctionError(FunctionException error) {
    if (error is FunctionsHttpException) {
      final details = error.details;
      final message = details is Map ? details['message'] as Object? : null;
      if (message is String && message.isNotEmpty) {
        return GroupFailure(message);
      }
    }
    return mapUnknownGroupError();
  }

  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const GroupFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
        code: GroupErrorCode.sessionExpired,
      );
    }
    return ownerId;
  }

  /// Récupère `{entity_id: name}` pour toutes les traductions [entityType]
  /// dont l'identifiant est dans [entityIds] — même principe que
  /// `SupabaseCharacterRepository._fetchTranslatedNames`, dupliqué ici (voir
  /// le rationale de `RaceRowMapper` pour cette duplication systématique).
  Future<Map<String, String>> _fetchTranslatedNames({
    required String entityType,
    required Set<String> entityIds,
  }) => _fetchTranslatedValues(
    entityType: entityType,
    fieldName: 'name',
    entityIds: entityIds,
  );

  /// `{entity_id: value}` des traductions françaises [fieldName] de
  /// [entityType] (nom, description...).
  Future<Map<String, String>> _fetchTranslatedValues({
    required String entityType,
    required String fieldName,
    required Set<String> entityIds,
  }) async {
    if (entityIds.isEmpty) return const {};

    final rows = await _client
        .from('translations')
        .select('entity_id, value')
        .eq('entity_type', entityType)
        .eq('field_name', fieldName)
        .eq('locale', 'fr')
        .inFilter('entity_id', entityIds.toList());

    return {
      for (final row in rows)
        (row['entity_id'] as String): (row['value'] as String? ?? ''),
    };
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  /// Valeur textuelle facultative : clé absente, `null` ou d'un autre type
  /// donnent `null` (un retour arrière de DeepCore ne casse rien).
  String? _optionalString(Object? value) => value is String ? value : null;
}

class _RealtimeChannelSubscription implements GroupRealtimeSubscription {
  _RealtimeChannelSubscription(this._client, this._channel);

  final SupabaseClient _client;
  final RealtimeChannel _channel;

  @override
  Future<void> cancel() async {
    await _client.removeChannel(_channel);
  }
}
