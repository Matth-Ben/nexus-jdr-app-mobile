/// Échec de soumission d'un signalement de bug (`report-bug`, voir
/// `data/bug_report_repository.dart`) — même patron que `CharacterFailure`
/// (`features/characters/domain/character_failure.dart`)/`AuthFailure`
/// (`features/auth/domain/auth_failure.dart`) : un message déjà porté par
/// l'exception plutôt qu'un code d'erreur typé.
///
/// Contrairement à `StoryInviteFailure`
/// (`features/join_story/domain/story_invite_failure.dart`), qui distingue
/// plusieurs [enum] de cas pour piloter des actions différentes à l'écran,
/// ce type reste un simple message : le contrat `report-bug`
/// (`invalid_body`/`unauthorized`/`internal_error`/`server_misconfigured`)
/// n'a besoin d'aucune branche dédiée côté UI — `report_bug_sheet.dart`
/// affiche un unique bandeau générique fixe pour toute erreur réseau/HTTP
/// (spec direction-artistique de la tâche), [message] n'étant conservé que
/// pour le diagnostic (`debugPrint`).
class BugReportFailure implements Exception {
  const BugReportFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is BugReportFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
