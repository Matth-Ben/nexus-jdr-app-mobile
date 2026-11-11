import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/saving_throw_calculator.dart';
import '../../domain/signed_modifier_formatter.dart';
import 'dice_roll_sheet.dart';

/// "For"/"Dex"/"Con"/"Int"/"Sag"/"Cha" — dupliqué depuis
/// `character_creation/domain/race_summary_formatter.dart`
/// (`_abilityAbbreviations`, privée, non réutilisable telle quelle), même
/// rationale de duplication que `summary_step_screen.dart`. Résolution
/// localisée via les clés `.arb` partagées `characterAbilityAbbreviationXxx`
/// (chantier "traduction de l'app" Phase B, lot "Characters — fiche
/// (identité/statistiques)") — mêmes clés que `character_skills_card.dart`,
/// même principe que `characterLevelAbbreviation` (clé `.arb` réutilisée,
/// code Dart dupliqué).
Map<String, String> _abilityAbbreviations(AppLocalizations l10n) => {
  'str': l10n.characterAbilityAbbreviationStr,
  'dex': l10n.characterAbilityAbbreviationDex,
  'con': l10n.characterAbilityAbbreviationCon,
  'int': l10n.characterAbilityAbbreviationInt,
  'wis': l10n.characterAbilityAbbreviationWis,
  'cha': l10n.characterAbilityAbbreviationCha,
};

/// "Sauvegarde de Force" / "Strength saving throw" : libellé accessible d'une
/// ligne et titre de la feuille de dés qu'elle ouvre.
String _savingThrowLabel(AppLocalizations l10n, String abilityKey) =>
    switch (abilityKey) {
      'str' => l10n.characterSavingThrowLabelStr,
      'dex' => l10n.characterSavingThrowLabelDex,
      'con' => l10n.characterSavingThrowLabelCon,
      'int' => l10n.characterSavingThrowLabelInt,
      'wis' => l10n.characterSavingThrowLabelWis,
      'cha' => l10n.characterSavingThrowLabelCha,
      _ => l10n.characterSavingThrowsCardTitle,
    };

/// Carte "Jets de sauvegarde" de l'onglet "Personnage" : les 6
/// caractéristiques (pas 4, voir la spec de la tâche qui a produit ce
/// fichier), dans l'ordre canonique For/Dex/Con/Int/Sag/Cha.
class CharacterSavingThrowsCard extends StatelessWidget {
  const CharacterSavingThrowsCard({required this.results, super.key});

  /// Déjà calculés par l'appelant via `SavingThrowCalculator.computeAll` —
  /// widget purement présentationnel.
  final List<SavingThrowResult> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisplayText(
            AppLocalizations.of(context)!.characterSavingThrowsCardTitle,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final result in results) _SavingThrowItem(result: result),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingThrowItem extends StatelessWidget {
  const _SavingThrowItem({required this.result});

  final SavingThrowResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _savingThrowLabel(l10n, result.abilityKey);
    final bonusPhrase = result.bonus < 0
        ? l10n.diceRollSemanticsModifierMinus(-result.bonus)
        : l10n.diceRollSemanticsModifierPlus(result.bonus);
    final stateLabel = result.isProficient
        ? l10n.characterSavingThrowProficient
        : l10n.characterSavingThrowNotProficient;

    // Ligne tappable (comme les tuiles de caractéristique) : ouvre la feuille
    // de dés avec le bonus déjà calculé par `SavingThrowCalculator`, maîtrise
    // comprise. Zone de tap >= 44.
    return Semantics(
      button: true,
      label: label,
      // Bonus signé et état de maîtrise : sans `value`, `excludeSemantics`
      // masquerait « For +5 » et le point doré/vide aux lecteurs d'écran.
      value: '$bonusPhrase, $stateLabel',
      excludeSemantics: true,
      onTap: () => _roll(context, label),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => _roll(context, label),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProficiencyDot(isProficient: result.isProficient),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _abilityAbbreviations(l10n)[result.abilityKey] ??
                        result.abilityKey,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs / 2),
                  Text(
                    SignedModifierFormatter.format(result.bonus),
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      // `textPrimary` (pas `textSecondary`) : aligné sur
                      // `character_skills_card.dart::_SkillRow`, même rôle
                      // visuel (bonus final en gras) — incohérence entre les
                      // deux cartes signalée en revue direction-artistique.
                      color: result.bonus < 0
                          ? AppColors.accentBrick
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _roll(BuildContext context, String label) {
    showDiceRollSheet(context, label: label, modifier: result.bonus);
  }
}

class _ProficiencyDot extends StatelessWidget {
  const _ProficiencyDot({required this.isProficient});

  final bool isProficient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isProficient ? AppColors.goldEnd : Colors.transparent,
        border: isProficient
            ? null
            : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
    );
  }
}
