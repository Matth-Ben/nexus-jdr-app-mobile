import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';

/// Carte compacte "CHOIX DE RACE" de l'onglet "Compétences" — même gabarit
/// que `character_class_choices_card.dart` (`Wrap` de paires label/valeur) :
/// compétence(s)/outil(s) accordé(s) par le trait racial à choix
/// ([CharacterDetail.raceSkillChoiceNames]/[CharacterDetail.raceToolChoiceNames]),
/// qu'ils viennent d'un vrai choix fait à la création (ex. Changelin) ou
/// d'un octroi automatique (Satyre) — les deux écrivent une ligne
/// `character_race_choices`, voir la documentation de classe de ces champs.
///
/// Indispensable pour les races à choix LIBRE (Demi-elfe/Forgelier/Kenku) où
/// `character_skill_proficiencies`/`character_tool_proficiencies` seules ne
/// permettent pas de déduire après coup laquelle de leurs entrées vient de
/// la race plutôt que de la classe/l'historique.
///
/// N'affiche rien tant que [detail] n'a ni compétence ni outil de race —
/// appelant responsable de ne pas monter cette carte dans ce cas (voir
/// [hasContent]/`character_skills_tab_body.dart`).
class CharacterRaceChoicesCard extends StatelessWidget {
  const CharacterRaceChoicesCard({required this.detail, super.key});

  final CharacterDetail detail;

  static bool hasContent(CharacterDetail detail) =>
      detail.raceSkillChoiceNames.isNotEmpty ||
      detail.raceToolChoiceNames.isNotEmpty;

  static List<_RaceChoiceItem> _itemsOf(
    CharacterDetail detail,
    AppLocalizations l10n,
  ) => [
    for (final name in detail.raceSkillChoiceNames)
      _RaceChoiceItem(l10n.characterRaceChoicesCardSkillLabel, name),
    for (final name in detail.raceToolChoiceNames)
      _RaceChoiceItem(l10n.characterRaceChoicesCardToolLabel, name),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _itemsOf(detail, l10n);
    if (items.isEmpty) {
      // Ne devrait pas arriver en pratique : l'appelant est censé avoir déjà
      // vérifié [hasContent] avant d'insérer cette carte — même filet de
      // sécurité que `character_class_choices_card.dart`.
      return const SizedBox.shrink();
    }

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
            l10n.characterRaceChoicesCardTitle,
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
              for (final item in items) _RaceChoiceItemRow(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _RaceChoiceItem {
  const _RaceChoiceItem(this.label, this.value);

  final String label;
  final String value;
}

class _RaceChoiceItemRow extends StatelessWidget {
  const _RaceChoiceItemRow({required this.item});

  final _RaceChoiceItem item;

  @override
  Widget build(BuildContext context) {
    // `Wrap` : à grande taille de police, la valeur passe sous son libellé au
    // lieu de déborder de la carte.
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DisplayText(
          item.label,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          item.value,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
