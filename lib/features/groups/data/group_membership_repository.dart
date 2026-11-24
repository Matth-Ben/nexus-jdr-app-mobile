import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_failure.dart';
import 'group_error_mapper.dart';

/// Appartenance du joueur connecté à un groupe : le groupe, son nom et le
/// personnage courant du joueur dans ce groupe (`group_members.character_id`,
/// `null` pour un MJ sans personnage).
typedef GroupMembership = ({
  String groupId,
  String groupName,
  String? characterId,
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
          .select('group_id, character_id, groups(name)')
          .eq('user_id', ownerId);
      return [
        for (final row in rows)
          (
            groupId: row['group_id'] as String,
            groupName:
                ((row['groups'] as Map<String, dynamic>?)?['name']
                    as String?) ??
                '',
            characterId: row['character_id'] as String?,
          ),
      ];
    } on PostgrestException catch (error) {
      throw mapGroupError(error);
    } catch (_) {
      throw mapUnknownGroupError();
    }
  }
}
