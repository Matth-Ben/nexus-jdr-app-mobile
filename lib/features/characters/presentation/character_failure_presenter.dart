import '../../../l10n/app_localizations.dart';
import '../domain/character_failure.dart';

/// Résout le texte final d'une [CharacterFailure] à afficher à l'écran.
///
/// Voir la doc de classe d'[CharacterErrorCode] (`domain/character_failure.dart`)
/// pour le choix architectural : [CharacterFailure.code] est résolu ici via
/// [AppLocalizations] pour les codes connus, [CharacterFailure.message]
/// (déjà construit par `data/character_error_mapper.dart`, ou fourni
/// directement par `CharacterRepository`/les tests) reste utilisé tel quel
/// pour [CharacterErrorCode.generic].
///
/// **Factorisation** (chantier "traduction de l'app" Phase B, lot
/// "Character sharing") : `character_card_action_sheet.dart` (lot
/// "Characters — liste") portait la seule copie de cette fonction
/// (`_resolveCharacterFailureMessage`, privée à ce fichier) ; ce lot ajoutant
/// un 2ᵉ/3ᵉ site de résolution (`character_sharing/presentation/
/// character_share_screen.dart`, `character_sharing/presentation/
/// shared_character_view_screen.dart`), même suggestion de code-reviewer déjà
/// appliquée côté `GroupFailure`/`presentation/group_failure_presenter.dart`
/// (lot "Groups — onglets du groupe") : une seule fonction partagée plutôt
/// qu'une 3ᵉ copie-coller, les 3 écrans l'important désormais.
String resolveCharacterFailureMessage(
  AppLocalizations l10n,
  CharacterFailure failure,
) {
  switch (failure.code) {
    case CharacterErrorCode.accessDenied:
      return l10n.characterAccessDeniedErrorMessage;
    case CharacterErrorCode.network:
      return l10n.characterNetworkErrorMessage;
    case CharacterErrorCode.generic:
      return failure.message;
  }
}
