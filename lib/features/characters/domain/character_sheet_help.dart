import '../../../l10n/app_localizations.dart';
import '../../character_creation/domain/creation_step_help.dart';

/// Explications de la fiche personnage, affichées par le bouton ⓘ placé à
/// côté de "Partager" dans l'en-tête de l'onglet "Personnage" (demande
/// utilisateur, 2026-09-24) — même format et même ton (tutoiement) que
/// [CreationStepHelp], réutilise son panneau `showStepHelpSheet`.
///
/// [personnage] est une fonction plutôt qu'une constante (migration `.arb`,
/// chantier "traduction de l'app" Phase B) : le texte dépend désormais
/// d'[AppLocalizations], qui n'est disponible qu'avec un `BuildContext` —
/// même pattern que `ProfileLegalScreen._sections`
/// (`features/profile/presentation/profile_legal_screen.dart`). Ne couvre
/// que ce seul contenu : [CreationStepHelp] (les 10 aides de l'assistant de
/// création) reste hors périmètre de cette migration, voir D148 de
/// `docs/dette-technique.md`.
abstract final class CharacterSheetHelp {
  static StepHelpContent personnage(AppLocalizations l10n) => StepHelpContent(
    title: l10n.characterSheetHelpTitle,
    body: l10n.characterSheetHelpBody,
  );
}
