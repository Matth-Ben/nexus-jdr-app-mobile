import '../../../l10n/app_localizations.dart';
import '../domain/group_failure.dart';

/// Résout le texte final d'une [GroupFailure] à afficher à l'écran.
///
/// Voir la doc de classe d'[GroupErrorCode] (`domain/group_failure.dart`)
/// pour le choix architectural : [GroupFailure.code] est résolu ici via
/// [AppLocalizations] pour les codes connus, [GroupFailure.message] (déjà
/// construit par `data/group_error_mapper.dart`, ou fourni directement par
/// `GroupRepository`/les tests) reste utilisé tel quel pour
/// [GroupErrorCode.generic].
///
/// **Factorisation** (chantier "traduction de l'app" Phase B, lot "Groups —
/// écran principal") : `group_list_screen.dart` et `group_create_screen.dart`
/// (lot "Groups — rejoindre/créer") portaient chacun une copie privée
/// identique de cette fonction (`_resolveGroupFailureMessage`) ; ce lot
/// ajoutant un 3ᵉ/4ᵉ/5ᵉ site de résolution (`group_screen.dart`,
/// `group_settings_screen.dart`, `group_character_reassignment_screen.dart`),
/// suggestion du code-reviewer du lot précédent appliquée : une seule
/// fonction partagée plutôt qu'une 3ᵉ copie-coller, les 5 écrans l'important
/// désormais.
String resolveGroupFailureMessage(AppLocalizations l10n, GroupFailure failure) {
  switch (failure.code) {
    case GroupErrorCode.accessDenied:
      return l10n.groupAccessDeniedErrorMessage;
    case GroupErrorCode.network:
      return l10n.groupNetworkErrorMessage;
    case GroupErrorCode.generic:
      return failure.message;
  }
}
