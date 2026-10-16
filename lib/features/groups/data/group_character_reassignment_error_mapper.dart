import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_character_reassignment_failure.dart';

/// Traduit une exception levée par `SupabaseClient.functions.invoke` (appel
/// de `set-group-character`) en [GroupCharacterReassignmentFailure] typé —
/// même principe que `mapGroupInviteError`.
GroupCharacterReassignmentFailure mapGroupCharacterReassignmentError(
  Object error,
) {
  if (error is FunctionsHttpException) {
    final details = error.details;
    final code = details is Map ? details['error'] as Object? : null;
    final message = details is Map ? details['message'] as Object? : null;
    final serverMessage = message is String ? message : null;

    return switch (code) {
      'character_not_owned' => GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.characterNotOwned,
        serverMessage: serverMessage,
      ),
      'not_member' => GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.notMember,
        serverMessage: serverMessage,
      ),
      'not_eligible' => GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.notEligible,
        serverMessage: serverMessage,
      ),
      'already_in_group' => GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.alreadyInGroup,
        serverMessage: serverMessage,
      ),
      _ => GroupCharacterReassignmentFailure(
        GroupCharacterReassignmentFailureKind.generic,
        serverMessage: serverMessage,
      ),
    };
  }
  return const GroupCharacterReassignmentFailure(
    GroupCharacterReassignmentFailureKind.generic,
  );
}
