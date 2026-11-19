import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_failure.dart';

const String _networkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

/// Codes stables renvoyés dans `message` par les RPC et triggers DeepCore des
/// groupes (`become_group_game_master`, gardes « combat actif » de la
/// migration `20261119090000`), avec leur [GroupFailure] (message français de
/// diagnostic, le texte affiché vient de `group_failure_l10n.dart`).
const Map<String, GroupFailure> _failuresByServerCode = {
  'combat_active': GroupFailure(
    'Action impossible pendant un combat en cours.',
    code: GroupErrorCode.combatActive,
  ),
  'mj_already_assigned': GroupFailure(
    'Un autre membre est déjà MJ de ce groupe.',
    code: GroupErrorCode.mjAlreadyAssigned,
  ),
  'not_group_owner': GroupFailure(
    'Action réservée au créateur du groupe.',
    code: GroupErrorCode.notGroupOwner,
  ),
  'not_member': GroupFailure(
    "Vous n'êtes plus membre de ce groupe.",
    code: GroupErrorCode.notMember,
  ),
  'group_not_found': GroupFailure(
    'Groupe introuvable.',
    code: GroupErrorCode.groupNotFound,
  ),
  'not_authenticated': GroupFailure(
    'Session expirée. Reconnectez-vous pour continuer.',
    code: GroupErrorCode.sessionExpired,
  ),
};

/// Traduit une [PostgrestException] Supabase en [GroupFailure] — même
/// principe que `mapCharacterError`.
///
/// **Le `message` est lu avant le code** : les RPC et triggers DeepCore y
/// placent un code stable (`combat_active`, `not_member`...) alors que le
/// SQLSTATE peut être générique, et `not_member`/`group_not_found` peuvent
/// arriver en HTTP 500 (le code vaut alors `'500'` si le corps n'est pas du
/// JSON). Ensuite seulement : `42501` (RLS), `40P01`/`40001` (conflit
/// transitoire, « Réessayez »), `PGRST202` (fonction absente du serveur).
GroupFailure mapGroupError(PostgrestException error) {
  final fromServerCode = _failuresByServerCode[error.message.trim()];
  if (fromServerCode != null) return fromServerCode;

  switch (error.code) {
    case '42501':
      return const GroupFailure(
        "Vous n'avez pas accès à ce groupe.",
        code: GroupErrorCode.accessDenied,
      );
    case '40P01':
    case '40001':
      return const GroupFailure(
        "Le serveur était occupé, rien n'a été modifié. Réessayez.",
        code: GroupErrorCode.transientConflict,
      );
    case 'PGRST202':
      return const GroupFailure(
        "Cette action n'est pas encore disponible sur le serveur.",
        code: GroupErrorCode.serverOutdated,
      );
  }
  if (error.message.isEmpty) {
    return const GroupFailure(
      _networkErrorMessage,
      code: GroupErrorCode.network,
    );
  }
  return GroupFailure(error.message);
}

/// Message générique pour toute erreur qui n'est pas une [PostgrestException]
/// (ex. absence de réseau).
GroupFailure mapUnknownGroupError() =>
    const GroupFailure(_networkErrorMessage, code: GroupErrorCode.network);
