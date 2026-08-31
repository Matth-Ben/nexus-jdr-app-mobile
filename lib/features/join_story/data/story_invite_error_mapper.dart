import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/story_invite_failure.dart';

/// Traduit une exception levée par `SupabaseClient.functions.invoke` en
/// [StoryInviteFailure] typé — voir la documentation de
/// [StoryInviteFailureKind] pour le détail des codes reconnus.
///
/// Extraite en fonction pure (testable sans réseau, `FunctionsHttpException`
/// se construit directement) plutôt qu'inline dans
/// `data/story_invite_repository.dart` — même principe que
/// `features/characters/data/character_error_mapper.dart`.
StoryInviteFailure mapStoryInviteError(Object error) {
  if (error is FunctionsHttpException) {
    final details = error.details;
    final code = details is Map ? details['error'] as Object? : null;
    final message = details is Map ? details['message'] as Object? : null;
    final serverMessage = message is String ? message : null;

    return switch (code) {
      'invalid_code' => StoryInviteFailure(
        StoryInviteFailureKind.invalidCode,
        serverMessage: serverMessage,
      ),
      'invite_disabled' => StoryInviteFailure(
        StoryInviteFailureKind.inviteDisabled,
        serverMessage: serverMessage,
      ),
      'character_not_owned' => StoryInviteFailure(
        StoryInviteFailureKind.characterNotOwned,
        serverMessage: serverMessage,
      ),
      'already_joined' => StoryInviteFailure(
        StoryInviteFailureKind.alreadyJoined,
        serverMessage: serverMessage,
      ),
      _ => StoryInviteFailure(
        StoryInviteFailureKind.generic,
        serverMessage: serverMessage,
      ),
    };
  }

  // `FunctionsFetchException` (pas de réponse reçue, ex. hors ligne),
  // `FunctionsRelayException`, ou toute autre exception inattendue : aucun
  // code d'erreur exploitable, traité comme générique.
  return const StoryInviteFailure(StoryInviteFailureKind.generic);
}
