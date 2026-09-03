import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/bug_report_failure.dart';

/// Message générique — même texte affiché tel quel par
/// `report_bug_sheet.dart` pour toute erreur réseau/HTTP (spec
/// direction-artistique de la tâche), conservé ici comme valeur par défaut de
/// [BugReportFailure.message] quand le corps d'erreur serveur ne porte aucun
/// `message` exploitable.
const String genericBugReportErrorMessage =
    "Impossible d'envoyer le signalement. Réessayez.";

/// Traduit une exception levée par `SupabaseClient.functions.invoke` en
/// [BugReportFailure] — même principe que `mapStoryInviteError`
/// (`features/join_story/data/story_invite_error_mapper.dart`), mais sans
/// distinction de code d'erreur (`error: "invalid_body"/"unauthorized"/
/// "internal_error"/"server_misconfigured"` du contrat `report-bug`) :
/// [BugReportFailure] reste un simple message, voir sa documentation de
/// classe pour le rationale.
BugReportFailure mapBugReportError(Object error) {
  if (error is FunctionsHttpException) {
    final details = error.details;
    final message = details is Map ? details['message'] as Object? : null;
    return BugReportFailure(
      message is String && message.isNotEmpty
          ? message
          : genericBugReportErrorMessage,
    );
  }

  // `FunctionsFetchException` (pas de réponse reçue), `FunctionsRelayException`,
  // ou toute autre exception inattendue : aucun corps d'erreur exploitable.
  return const BugReportFailure(genericBugReportErrorMessage);
}
