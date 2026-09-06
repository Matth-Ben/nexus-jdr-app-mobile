import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_invite_failure.dart';

/// Traduit une exception levée par `SupabaseClient.functions.invoke` en
/// [GroupInviteFailure] typé — même principe que `mapStoryInviteError`
/// (`features/join_story/data/story_invite_error_mapper.dart`).
GroupInviteFailure mapGroupInviteError(Object error) {
  if (error is FunctionsHttpException) {
    final details = error.details;
    final code = details is Map ? details['error'] as Object? : null;
    final message = details is Map ? details['message'] as Object? : null;
    final serverMessage = message is String ? message : null;

    return switch (code) {
      'invalid_code' => GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
        serverMessage: serverMessage,
      ),
      'already_in_group' => GroupInviteFailure(
        GroupInviteFailureKind.alreadyInGroup,
        serverMessage: serverMessage,
      ),
      _ => GroupInviteFailure(
        GroupInviteFailureKind.generic,
        serverMessage: serverMessage,
      ),
    };
  }
  return const GroupInviteFailure(GroupInviteFailureKind.generic);
}
