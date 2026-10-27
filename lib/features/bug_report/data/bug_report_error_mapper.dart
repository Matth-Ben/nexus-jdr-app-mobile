import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/bug_report_failure.dart';
import '../domain/bug_report_screenshot.dart';

/// Message générique — même texte affiché tel quel par
/// `report_bug_sheet.dart` pour toute erreur réseau/HTTP (spec
/// direction-artistique de la tâche), conservé ici comme valeur par défaut de
/// [BugReportFailure.message] quand le corps d'erreur serveur ne porte aucun
/// `message` exploitable.
const String genericBugReportErrorMessage =
    "Impossible d'envoyer le signalement. Réessayez.";

/// Message de diagnostic par défaut d'une
/// [BugReportFailureKind.screenshotUpload] (jamais affiché tel quel :
/// `report_bug_sheet.dart` a son propre texte fixe pour ce cas).
const String screenshotUploadBugReportErrorMessage =
    "Impossible d'envoyer la capture d'écran.";

/// Code `error` du contrat `report-bug` renvoyé (400) quand `screenshotPath`
/// est bien formé mais que l'objet est absent du bucket — aucune ligne
/// `bug_reports` n'est alors créée.
const String _screenshotNotFoundCode = 'screenshot_not_found';

/// Traduit une exception levée par `SupabaseClient.functions.invoke` en
/// [BugReportFailure] — même principe que `mapStoryInviteError`
/// (`features/join_story/data/story_invite_error_mapper.dart`). Seul
/// `error: "screenshot_not_found"` a sa propre catégorie
/// ([BugReportFailureKind.screenshotUpload]) ; `invalid_body`/
/// `unauthorized`/`internal_error`/`server_misconfigured` restent
/// [BugReportFailureKind.generic].
BugReportFailure mapBugReportError(Object error) {
  if (error is FunctionsHttpException) {
    final details = error.details;
    final code = details is Map ? details['error'] as Object? : null;
    final message = details is Map ? details['message'] as Object? : null;
    final hasMessage = message is String && message.isNotEmpty;

    if (code == _screenshotNotFoundCode) {
      return BugReportFailure(
        hasMessage ? message : screenshotUploadBugReportErrorMessage,
        kind: BugReportFailureKind.screenshotUpload,
      );
    }
    return BugReportFailure(
      hasMessage ? message : genericBugReportErrorMessage,
    );
  }

  // `FunctionsFetchException` (pas de réponse reçue), `FunctionsRelayException`,
  // ou toute autre exception inattendue : aucun corps d'erreur exploitable.
  return const BugReportFailure(genericBugReportErrorMessage);
}

/// Traduit un échec du téléversement de la capture dans le bucket
/// `bug-report-screenshots` (`StorageException` — RLS, type ou taille
/// refusés — ou erreur réseau) : toujours
/// [BugReportFailureKind.screenshotUpload], le signalement n'étant jamais
/// envoyé sans sa capture (décision produit).
BugReportFailure mapBugReportScreenshotUploadError(Object error) {
  final message = error is StorageException && error.message.isNotEmpty
      ? error.message
      : screenshotUploadBugReportErrorMessage;
  return BugReportFailure(message, kind: BugReportFailureKind.screenshotUpload);
}

/// Codes `PlatformException` d'`image_picker` signalant un accès refusé ou
/// restreint (iOS : photothèque et appareil photo ; Android : appareil
/// photo — la galerie passe par le sélecteur système, sans permission).
const Set<String> _accessDeniedPickerCodes = {
  'photo_access_denied',
  'photo_access_restricted',
  'camera_access_denied',
  'camera_access_restricted',
};

/// Traduit une exception levée par `ImagePicker.pickImage` en
/// [BugReportScreenshotFailure], ou `null` quand l'erreur ne correspond à
/// aucun texte de la spec (ex. `no_available_camera`) — l'appelant la traite
/// alors comme une annulation.
BugReportScreenshotFailure? mapBugReportScreenshotPickError(Object error) {
  if (error is! PlatformException) return null;
  if (_accessDeniedPickerCodes.contains(error.code)) {
    return const BugReportScreenshotFailure(
      BugReportScreenshotFailureKind.accessDenied,
    );
  }
  if (error.code == 'invalid_image') {
    return const BugReportScreenshotFailure(
      BugReportScreenshotFailureKind.unsupportedFormat,
    );
  }
  return null;
}
