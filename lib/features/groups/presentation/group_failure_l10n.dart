import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/group_failure.dart';

/// Texte localisé d'une [GroupFailure] (D141) : la couche `data/` ne produit
/// qu'un [GroupFailure.code], traduit ici. [GroupFailure.message] (français /
/// brut serveur) n'est utilisé que pour [GroupErrorCode.generic].
extension GroupFailureL10n on GroupFailure {
  /// Variante pour un appelant qui a déjà un [AppLocalizations].
  String localizedWith(AppLocalizations l10n) {
    switch (code) {
      case GroupErrorCode.accessDenied:
        return l10n.groupAccessDeniedErrorMessage;
      case GroupErrorCode.network:
        // Même texte que `CharacterErrorCode.network` (réseau indisponible).
        return l10n.characterNetworkErrorMessage;
      case GroupErrorCode.groupNotFound:
        return l10n.groupNotFoundErrorMessage;
      case GroupErrorCode.sessionExpired:
        return l10n.groupSessionExpiredErrorMessage;
      case GroupErrorCode.inviteCodeGenerationFailed:
        return l10n.groupInviteCodeGenerationFailedErrorMessage;
      case GroupErrorCode.generic:
        return message;
    }
  }

  /// Texte localisé selon la langue courante de [context]. Sans délégué de
  /// localisation dans l'arbre (jamais le cas dans l'app, seulement dans un
  /// widget de test minimal), retombe sur [message].
  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n == null ? message : localizedWith(l10n);
  }
}
