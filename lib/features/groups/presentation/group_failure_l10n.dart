import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/group_failure.dart';

/// Texte localisé d'une [GroupFailure] (D141) : la couche `data/` ne produit
/// qu'un [GroupFailure.code], traduit ici. [GroupFailure.message] (français /
/// brut serveur) n'est utilisé que pour [GroupErrorCode.generic].
extension GroupFailureL10n on GroupFailure {
  /// Variante pour un appelant qui a déjà un [AppLocalizations].
  ///
  /// [combatActiveMessage] : texte propre à l'action refusée pendant un combat
  /// actif (départ, dissolution, « Devenir MJ ») ; à défaut, texte générique
  /// de [GroupErrorCode.combatActive].
  String localizedWith(AppLocalizations l10n, {String? combatActiveMessage}) {
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
      case GroupErrorCode.combatActive:
        return combatActiveMessage ?? l10n.groupCombatActiveErrorMessage;
      case GroupErrorCode.mjAlreadyAssigned:
        return l10n.groupMjAlreadyAssignedErrorMessage;
      case GroupErrorCode.notGroupOwner:
        return l10n.groupNotGroupOwnerErrorMessage;
      case GroupErrorCode.notMember:
        return l10n.groupNotMemberErrorMessage;
      case GroupErrorCode.transientConflict:
        return l10n.groupTransientConflictErrorMessage;
      case GroupErrorCode.serverOutdated:
        return l10n.groupServerOutdatedErrorMessage;
      case GroupErrorCode.treasureStale:
        return l10n.groupTreasureStaleError;
      case GroupErrorCode.generic:
        return message;
    }
  }

  /// Texte localisé selon la langue courante de [context]. Sans délégué de
  /// localisation dans l'arbre (jamais le cas dans l'app, seulement dans un
  /// widget de test minimal), retombe sur [message]. [combatActiveMessage] :
  /// voir [localizedWith].
  String localized(BuildContext context, {String? combatActiveMessage}) {
    final l10n = AppLocalizations.of(context);
    return l10n == null
        ? message
        : localizedWith(l10n, combatActiveMessage: combatActiveMessage);
  }
}
