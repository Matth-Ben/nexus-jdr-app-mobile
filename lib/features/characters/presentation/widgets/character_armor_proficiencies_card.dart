import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'character_name_tag_chip.dart';

/// Carte compacte "MAÎTRISES D'ARMURES" de l'onglet "Compétences" : les
/// tokens de maîtrise d'armures fusionnés/dédupliqués sur toutes les classes
/// du personnage (multiclassage inclus, RAW 5e : une maîtrise n'est jamais
/// retirée une fois acquise) — voir
/// `data/character_detail_row_mapper.dart::mergeArmorProficiencyNames` pour
/// l'algorithme de fusion.
///
/// Même patron visuel que `CharacterToolProficienciesCard`/
/// `CharacterLanguagesCard` — dupliqué plutôt que factorisé en un widget
/// générique, choix d'architecture délibérément laissé hors de ce chantier
/// (limiter le risque de régression sur les cartes existantes).
///
/// N'affiche rien tant que [names] est vide — appelant responsable de ne pas
/// monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
class CharacterArmorProficienciesCard extends StatelessWidget {
  const CharacterArmorProficienciesCard({required this.names, super.key});

  final List<String> names;

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
          Text(
            "MAÎTRISES D'ARMURES",
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final name in names) CharacterNameTagChip(name: name),
            ],
          ),
        ],
      ),
    );
  }
}
