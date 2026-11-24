import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_failure.dart';
import 'group_error_mapper.dart';

/// Appartenance du joueur connecté à un groupe : le groupe, son nom, le
/// personnage courant du joueur dans ce groupe (`group_members.character_id`,
/// `null` pour un MJ sans personnage) et le lien avec Grimoire.
///
/// [grimoireLinked] : `groups.story_title` non nul. Grimoire écrit le titre de
/// la campagne sur le groupe à l'association et l'efface (`NULL`) à la
/// dissociation (contrat DeepCore `20261119120000`, Grimoire
/// `server/nexus/groups.ts`) ; un combat Grimoire exige ce lien. Seuls ces
/// groupes sont suivis en continu au premier plan (coût des canaux).
typedef GroupMembership = ({
  String groupId,
  String groupName,
  String? characterId,
  bool grimoireLinked,
});

/// Lecture légère des groupes du joueur connecté (une seule requête) : sert
/// au suivi des combats de **tous** ses groupes tant que l'app est au premier
/// plan (`docs/combat-grimoire-ui.md` §13, Q2) et au contrôle d'appartenance
/// avant d'ouvrir un combat depuis une notification (§8).
///
/// Séparée de `GroupRepository` (qui porte aussi les badges et compteurs de
/// l'écran « Groupes ») : lecture seule, aucune écriture, aucun cache
/// persistant.
abstract class GroupMembershipRepository {
  /// Lignes `group_members` du joueur connecté (RLS : ses propres lignes),
  /// avec le nom du groupe.
  Future<List<GroupMembership>> fetchMyMemberships();
}

class SupabaseGroupMembershipRepository implements GroupMembershipRepository {
  SupabaseGroupMembershipRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GroupMembership>> fetchMyMemberships() async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const GroupFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
        code: GroupErrorCode.sessionExpired,
      );
    }
    try {
      final rows = await _client
          .from('group_members')
          .select('group_id, character_id, groups(name, story_title)')
          .eq('user_id', ownerId);
      return [for (final row in rows) _membershipOf(row)];
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }

  GroupMembership _membershipOf(Map<String, dynamic> row) {
    final group = row['groups'] as Map<String, dynamic>?;
    return (
      groupId: row['group_id'] as String,
      groupName: (group?['name'] as String?) ?? '',
      characterId: row['character_id'] as String?,
      grimoireLinked: group?['story_title'] is String,
    );
  }
}
