import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

/// Issue d'une tentative de mise à jour intégrée Google Play.
enum InAppUpdateOutcome {
  /// Google Play a installé la nouvelle version (l'app redémarre
  /// généralement avant que ce résultat ne soit lu).
  updated,

  /// Google Play indique qu'aucune version plus récente n'existe.
  upToDate,

  /// Le joueur a refusé ou annulé la mise à jour.
  declined,

  /// La mise à jour a échoué en cours de route.
  failed,

  /// Mise à jour intégrée impossible : iOS, app non installée depuis le
  /// Play Store (build de dev, APK), services Google Play absents... —
  /// l'appelant se rabat alors sur la table `app_versions` et la fiche store.
  unavailable,
}

/// Mise à jour intégrée Google Play (« in-app update », mode immédiat :
/// téléchargement, installation et redémarrage pris en charge par Google
/// Play). Abstraction pour les tests, même principe que
/// `AppVersionRepository`.
abstract class InAppUpdateGateway {
  Future<InAppUpdateOutcome> tryImmediateUpdate();
}

class PlayInAppUpdateGateway implements InAppUpdateGateway {
  const PlayInAppUpdateGateway();

  @override
  Future<InAppUpdateOutcome> tryImmediateUpdate() async {
    if (!Platform.isAndroid) return InAppUpdateOutcome.unavailable;
    try {
      final info = await InAppUpdate.checkForUpdate();
      switch (info.updateAvailability) {
        case UpdateAvailability.updateNotAvailable:
          return InAppUpdateOutcome.upToDate;
        case UpdateAvailability.updateAvailable:
        case UpdateAvailability.developerTriggeredUpdateInProgress:
          if (!info.immediateUpdateAllowed) {
            return InAppUpdateOutcome.unavailable;
          }
          final result = await InAppUpdate.performImmediateUpdate();
          return switch (result) {
            AppUpdateResult.success => InAppUpdateOutcome.updated,
            AppUpdateResult.userDeniedUpdate => InAppUpdateOutcome.declined,
            AppUpdateResult.inAppUpdateFailed => InAppUpdateOutcome.failed,
          };
        case UpdateAvailability.unknown:
          return InAppUpdateOutcome.unavailable;
      }
    } catch (_) {
      // Ex. app non installée depuis le Play Store : l'API refuse l'appel.
      return InAppUpdateOutcome.unavailable;
    }
  }
}
