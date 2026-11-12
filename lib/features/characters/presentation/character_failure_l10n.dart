import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/character_failure.dart';

/// Texte localisé d'une [CharacterFailure] (D141).
///
/// La couche `data/` ne connaît ni `BuildContext` ni `AppLocalizations` : elle
/// ne produit qu'un [CharacterFailure.code] stable. C'est ici, côté
/// présentation, que le code est traduit dans la langue de l'app.
/// [CharacterFailure.message] (français, produit en parallèle) n'est utilisé
/// que pour [CharacterErrorCode.generic] : message brut renvoyé par le serveur
/// ou texte construit par un appelant (non traduit, voir D141).
extension CharacterFailureL10n on CharacterFailure {
  /// Variante pour un appelant qui a déjà un [AppLocalizations].
  String localizedWith(AppLocalizations l10n) {
    switch (code) {
      case CharacterErrorCode.accessDenied:
        return l10n.characterAccessDeniedErrorMessage;
      case CharacterErrorCode.network:
        return l10n.characterNetworkErrorMessage;
      case CharacterErrorCode.loadFailed:
        return l10n.characterLoadFailedErrorMessage;
      case CharacterErrorCode.characterNotFound:
        return l10n.characterNotFoundErrorMessage;
      case CharacterErrorCode.itemNotFound:
        return l10n.characterItemNotFoundErrorMessage;
      case CharacterErrorCode.invalidQuantity:
        return l10n.characterInvalidQuantityErrorMessage;
      case CharacterErrorCode.noteAlreadyDeleted:
        return l10n.characterNoteAlreadyDeletedErrorMessage;
      case CharacterErrorCode.characterNotOwned:
        return l10n.characterNotOwnedErrorMessage;
      case CharacterErrorCode.sessionExpired:
        return l10n.characterSessionExpiredErrorMessage;
      case CharacterErrorCode.generic:
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
