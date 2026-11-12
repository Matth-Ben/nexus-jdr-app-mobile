import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/character_creation_failure.dart';

/// Texte localisé d'une [CharacterCreationFailure] (D141) : la couche `data/`
/// ne produit qu'un [CharacterCreationFailure.code], traduit ici.
/// [CharacterCreationFailure.message] (français / brut serveur) n'est utilisé
/// que pour [CharacterCreationErrorCode.generic].
extension CharacterCreationFailureL10n on CharacterCreationFailure {
  /// Variante pour un appelant qui a déjà un [AppLocalizations].
  String localizedWith(AppLocalizations l10n) {
    switch (code) {
      case CharacterCreationErrorCode.accessDenied:
        return l10n.creationAccessDeniedErrorMessage;
      case CharacterCreationErrorCode.network:
        // Même texte que `CharacterErrorCode.network` (réseau indisponible).
        return l10n.characterNetworkErrorMessage;
      case CharacterCreationErrorCode.sessionExpiredCreate:
        return l10n.creationSessionExpiredCreateErrorMessage;
      case CharacterCreationErrorCode.sessionExpiredEdit:
        return l10n.creationSessionExpiredEditErrorMessage;
      case CharacterCreationErrorCode.sessionExpiredImport:
        return l10n.creationSessionExpiredImportErrorMessage;
      case CharacterCreationErrorCode.characterNotFound:
        return l10n.characterNotFoundErrorMessage;
      case CharacterCreationErrorCode.generic:
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
