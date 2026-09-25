import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/character_edit_session_provider.dart';

/// Texte de pied de page affiché sous la `Row` Retour/Suivant des étapes 1 à
/// 8 de l'assistant de création : "↻ Brouillon sauvegardé automatiquement ·
/// Abandonner" — correctif du recettage visuel `direction-artistique` du
/// 13/09 (voir `docs/cahier-des-charges/09-maquettes-captures.md`, sections
/// "Création 1" à "Création 8") : ces maquettes ne montrent aucune icône
/// croix dans le bandeau bois, mais ce texte de pied de page à la place.
///
/// "Abandonner" réutilise le même callback [onAbandon] que l'ancienne croix
/// du bandeau (voir `abandon_creation_flow.dart::abandonCharacterCreation`) —
/// seul le point d'appel visuel change, jamais la logique d'abandon
/// elle-même (confirmation puis reset du brouillon).
///
/// L'étape 9/9 ("Récapitulatif", `summary_step_screen.dart`) porte aussi ce
/// pied de page, malgré une maquette qui ne le montre pas explicitement :
/// décision du chef de projet (suite à une remarque `code-reviewer`) pour ne
/// jamais perdre silencieusement la capacité d'abandonner une création en
/// cours — voir la documentation de classe de `SummaryStepScreen`.
class DraftAutosaveFooter extends ConsumerWidget {
  const DraftAutosaveFooter({required this.onAbandon, super.key});

  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mode modification : rien n'est enregistré avant « Enregistrer les
    // modifications », d'où un libellé différent.
    final editing = ref.watch(characterEditSessionControllerProvider) != null;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            editing
                ? 'Modification en cours · '
                : '↻ Brouillon sauvegardé automatiquement · ',
            style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
          ),
          InkWell(
            onTap: onAbandon,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  editing ? 'Annuler les modifications' : 'Abandonner',
                  // `fontWeight.w600` : même convention que le lien tapable
                  // "‹ Retour" de `summary_step_screen.dart` (texte inline
                  // légèrement plus appuyé que le corps de texte qui
                  // l'entoure, seul indice visuel d'affordance ici, faute de
                  // précision explicite sur la graisse dans la consigne
                  // d'origine — qui ne fixe que la couleur `accentBrick`).
                  style: AppTypography.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBrick,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
