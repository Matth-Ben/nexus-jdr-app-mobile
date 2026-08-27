import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/inventory_stat_box.dart';

/// Rangée de "stat boxes" en tête de l'onglet "Inventaire" — voir
/// `domain/inventory_stat_boxes_resolver.dart` pour leur construction.
///
/// Défilable horizontalement (`SingleChildScrollView`) plutôt qu'un `Row`
/// simple : [boxes] peut compter jusqu'à 6 entrées (platine et électrum
/// affichées en plus des 4 boxes de la maquette quand non nulles), qui ne
/// tiendraient pas toutes sur la largeur d'un écran de téléphone.
class CharacterInventoryStatBoxesRow extends StatelessWidget {
  const CharacterInventoryStatBoxesRow({required this.boxes, super.key});

  final List<InventoryStatBox> boxes;

  static const double _boxWidth = 76;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < boxes.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _StatBox(box: boxes[i]),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.box});

  final InventoryStatBox box;

  @override
  Widget build(BuildContext context) {
    // Seule la box "PO" (pièces d'or) reprend la bordure dorée d'emphase de
    // la maquette : l'or est la monnaie de référence en 5e (les autres
    // monnaies s'y convertissent), donc la seule à toujours apparaître à la
    // même position — les autres boxes peuvent se décaler selon que
    // platine/électrum sont affichées (voir le resolver), une emphase basée
    // sur la position (ex. "toujours la 1re box") n'aurait donc pas de sens
    // stable.
    final emphasized = box.unit == 'PO';

    return Container(
      width: CharacterInventoryStatBoxesRow._boxWidth,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: emphasized ? AppColors.goldEnd : AppColors.woodLight,
          width: emphasized ? AppBorders.cardEmphasis : AppBorders.card,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            box.value,
            // Toujours `textPrimary`, jamais `AppColors.goldEnd` : la
            // maquette affiche le montant de la box "PO" dans un ton doré,
            // mais reproduire cette couleur en texte sur `parchmentCard`
            // recréerait exactement le défaut de contraste (~2,4:1, sous le
            // seuil AA 4,5:1) déjà trouvé et corrigé sur l'onglet
            // Compétences (voir `character_skills_card.dart`/
            // `character_spells_section.dart::_SpellSlotDots`) — la bordure
            // dorée ci-dessus suffit à porter l'emphase visuelle sans
            // dégrader la lisibilité du montant.
            style: AppTypography.body(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            box.unit,
            style: AppTypography.body(
              // Plancher d'accessibilité strict du design système (section
              // 7), même règle que `character_ability_score_grid.dart`.
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
