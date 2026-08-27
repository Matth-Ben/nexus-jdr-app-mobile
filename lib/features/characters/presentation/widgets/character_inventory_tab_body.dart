import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_painter.dart';
import '../../domain/character_detail.dart';
import '../../domain/inventory_stat_boxes_resolver.dart';
import 'character_inventory_item_card.dart';
import 'character_inventory_stat_boxes_row.dart';

/// Contenu de l'onglet "Inventaire" de la fiche personnage — voir
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
/// Inventaire".
///
/// Portée volontairement en lecture seule à cette itération, pour tout
/// l'onglet : aucune action d'écriture n'est câblée ici. Le tap sur "+
/// Ajouter un objet" se contente de signaler que la fonctionnalité arrive
/// plus tard (même pattern que
/// `character_creation/presentation/appearance_and_backstory_step_screen.dart
/// ::_showPortraitComingSoon`), et chaque [CharacterInventoryItemCard] n'est
/// pas cliquable (voir sa documentation de classe pour le détail du report
/// côté panneau "Infos"/actions sur un objet) — pas d'ajustement de monnaie
/// non plus (les stat boxes de tête sont en lecture seule).
///
/// Les objets sont affichés dans l'ordre renvoyé par la requête
/// (`SupabaseCharacterRepository._fetchInventory`), sans tri ni
/// regroupement par catégorie : `character_inventory` n'a pas de colonne de
/// tri naturelle côté schéma (vérifié contre les migrations réelles), et la
/// maquette ne montre elle-même aucun regroupement visuel par catégorie.
class CharacterInventoryTabBody extends StatelessWidget {
  const CharacterInventoryTabBody({required this.detail, super.key});

  final CharacterDetail detail;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
  }

  @override
  Widget build(BuildContext context) {
    final statBoxes = InventoryStatBoxesResolver.resolve(detail);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CharacterInventoryStatBoxesRow(boxes: statBoxes),
        const SizedBox(height: AppSpacing.md),
        for (final item in detail.inventory) ...[
          CharacterInventoryItemCard(item: item),
          const SizedBox(height: AppSpacing.sm),
        ],
        _AddItemTile(onTap: () => _showComingSoon(context)),
      ],
    );
  }
}

/// Tuile "+ Ajouter un objet" en pointillés, en bas de la liste — même
/// composant que la tuile "Portrait" de l'étape 8/9 de l'assistant de
/// création (`appearance_and_backstory_step_screen.dart::_PortraitTile`,
/// carré au lieu de pleine largeur, mais même [DashedBorderPainter]).
class _AddItemTile extends StatelessWidget {
  const _AddItemTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: CustomPaint(
          painter: const DashedBorderPainter(color: AppColors.textMuted),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Ajouter un objet',
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
