import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/weight_formatter.dart';

/// Une carte de l'onglet "Inventaire" — badge de catégorie, nom, sous-titre
/// "{catégorie} · x{quantité}", et un poids ou un badge "ÉQUIPÉ" à droite.
///
/// Cliquable : ouvre la sheet d'actions "Infos"/"Utiliser"/"Équiper-
/// Déséquiper"/"Retirer" (`item_action_sheet.dart::showItemActionSheet`) —
/// voir [onTap], `null` désactive le tap (verrou `actionsDisabled` de tout
/// l'onglet, `character_inventory_tab_body.dart`) sans changer le rendu au
/// repos, même convention que `_SpellRow`/`_FeatureRow` côté sorts/aptitudes.
class CharacterInventoryItemCard extends StatelessWidget {
  const CharacterInventoryItemCard({required this.item, this.onTap, super.key});

  final CharacterInventoryItem item;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              _CategoryBadge(category: item.category),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${InventoryCategoryRules.labelFor(item.category)} · x${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Trailing(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge carré de catégorie (40×40, voir [AccentIconBadge]) — un cadre en
/// pointillés avec une icône "+" pour un objet personnalisé
/// ([CharacterInventoryItem.isCustom]), plutôt qu'une couleur cyclée
/// arbitraire : ce n'est pas "une catégorie de plus", mais l'absence de
/// catégorie (aucune ligne `items` du tout, voir `domain
/// /inventory_category_rules.dart`).
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String? category;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    if (category == null) {
      return Container(
        width: _size,
        height: _size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: CustomPaint(
          painter: const DashedBorderPainter(color: AppColors.textMuted),
          child: const Center(
            child: Icon(Icons.add, size: 20, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return AccentIconBadge(
      icon: InventoryCategoryRules.iconFor(category),
      color: InventoryCategoryRules.colorFor(category),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.item});

  final CharacterInventoryItem item;

  @override
  Widget build(BuildContext context) {
    // Priorité au badge "ÉQUIPÉ" sur le poids quand les deux seraient
    // affichables (spec de la maquette : "le poids et le badge ne sont pas
    // montrés en même temps") — un objet équipé reste porté quel que soit
    // son poids, l'information la plus utile au joueur dans ce cas est
    // "est-ce que je le porte", pas son poids.
    if (item.equipped) {
      return const _EquippedBadge();
    }

    final totalWeight = item.totalWeight;
    if (totalWeight == null) {
      // Poids inconnu (objet personnalisé, ou `items.weight` nul en base) —
      // voir la documentation de `CharacterInventoryItem.totalWeight` : rien
      // n'est affiché plutôt qu'un "0 kg" trompeur.
      return const SizedBox.shrink();
    }

    return Text(
      '${WeightFormatter.format(totalWeight)} kg',
      style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
    );
  }
}

/// Badge "ÉQUIPÉ" — même recette fond/texte doré que le pilule d'onglet
/// sélectionné (`character_detail_tab_bar.dart::_TabButton`) : fond
/// `AppColors.goldEnd`, texte `AppColors.woodDark` (contraste déjà validé
/// pour cette combinaison, contrairement à un texte doré sur fond clair —
/// voir la note de contraste de `character_inventory_stat_boxes_row.dart`).
///
/// `AppTypography.body`, pas `.display` : corrigé en revue
/// direction-artistique — `font.display` (design système section 2) est
/// réservé aux titres d'écran/de carte, labels de navigation et boutons
/// d'action, pas à un badge d'état sur une carte (voir par comparaison
/// `CharacterNameTagChip`/`character_skills_card.dart::_MasteredLegend`,
/// tous deux déjà en `.body`).
class _EquippedBadge extends StatelessWidget {
  const _EquippedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldEnd,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'ÉQUIPÉ',
        style: AppTypography.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.woodDark,
        ),
      ),
    );
  }
}
