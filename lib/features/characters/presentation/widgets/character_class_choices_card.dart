import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';

/// Carte compacte "CHOIX DE CLASSE" de l'onglet "Compétences" — même gabarit
/// que `character_appearance_card.dart` (`Wrap` de paires label/valeur) :
/// sous-classe(s) choisie(s) ([CharacterDetail.classes]`.subclassName`) et
/// choix résolus par niveau ("Style de combat"/"Ennemi juré",
/// [CharacterDetail.classChoices]) — gap de lecture trouvé en construisant
/// l'export XML (voir le README, section "Reste à faire") : ces 2 écritures
/// existaient déjà en base mais n'étaient jamais réaffichées sur la fiche.
///
/// N'affiche rien tant que [detail] n'a ni sous-classe choisie ni choix de
/// classe résolu — appelant responsable de ne pas monter cette carte dans ce
/// cas (voir [hasContent]/`character_skills_tab_body.dart`).
class CharacterClassChoicesCard extends StatelessWidget {
  const CharacterClassChoicesCard({required this.detail, super.key});

  final CharacterDetail detail;

  static bool hasContent(CharacterDetail detail) => _itemsOf(detail).isNotEmpty;

  static List<_ClassChoiceItem> _itemsOf(CharacterDetail detail) {
    final subclassRows = detail.classes.where(
      (row) => row.subclassName != null,
    );
    // Label désambiguïsé par nom de classe seulement si plus d'une classe a
    // une sous-classe choisie (multiclassage) — "Sous-classe" seul sinon,
    // cas de très loin le plus courant.
    final needsClassLabel = subclassRows.length > 1;

    return [
      for (final row in subclassRows)
        _ClassChoiceItem(
          needsClassLabel ? 'Sous-classe (${row.className})' : 'Sous-classe',
          row.subclassName!,
        ),
      for (final choice in detail.classChoices)
        _ClassChoiceItem(choice.featureName, choice.chosenValue),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsOf(detail);
    if (items.isEmpty) {
      // Ne devrait pas arriver en pratique : l'appelant est censé avoir déjà
      // vérifié [hasContent] avant d'insérer cette carte — même filet de
      // sécurité que `character_appearance_card.dart`.
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
          Text(
            'CHOIX DE CLASSE',
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
              for (final item in items) _ClassChoiceItemRow(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassChoiceItem {
  const _ClassChoiceItem(this.label, this.value);

  final String label;
  final String value;
}

class _ClassChoiceItemRow extends StatelessWidget {
  const _ClassChoiceItemRow({required this.item});

  final _ClassChoiceItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
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
