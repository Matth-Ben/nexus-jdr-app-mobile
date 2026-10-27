/// Catégorie d'échec d'un signalement de bug — seule distinction dont
/// `report_bug_sheet.dart` a besoin pour choisir son bandeau d'erreur (spec
/// direction-artistique de la tâche "Capture d'écran du signalement").
enum BugReportFailureKind {
  /// La capture d'écran jointe n'a pas pu être envoyée : échec du
  /// téléversement Storage (`bug-report-screenshots`), ou réponse
  /// `400 screenshot_not_found` de `report-bug` (objet absent du bucket,
  /// aucune ligne créée). Le signalement n'est pas envoyé sans sa capture
  /// (décision produit) : l'écran propose de réessayer ou de la retirer.
  screenshotUpload,

  /// Tout le reste : erreur réseau, `invalid_body`/`unauthorized`/
  /// `internal_error`/`server_misconfigured`, exception inattendue.
  generic,
}

/// Échec de soumission d'un signalement de bug (`report-bug`, voir
/// `data/bug_report_repository.dart`) — même patron que `CharacterFailure`
/// (`features/characters/domain/character_failure.dart`)/`AuthFailure`
/// (`features/auth/domain/auth_failure.dart`) pour [message], complété d'un
/// [kind] à la manière de `StoryInviteFailure`
/// (`features/join_story/domain/story_invite_failure.dart`), réduit à la
/// seule distinction affichée différemment à l'écran
/// ([BugReportFailureKind.screenshotUpload]).
///
/// [message] n'est conservé que pour le diagnostic (`debugPrint`) :
/// `report_bug_sheet.dart` affiche toujours un texte fixe choisi d'après
/// [kind], jamais le message serveur.
class BugReportFailure implements Exception {
  const BugReportFailure(
    this.message, {
    this.kind = BugReportFailureKind.generic,
  });

  final String message;
  final BugReportFailureKind kind;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is BugReportFailure &&
      other.message == message &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(message, kind);
}
