import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../characters/presentation/widgets/character_inventory_stat_boxes_row.dart';
import '../../domain/group_treasure.dart';
import '../../domain/group_treasure_item.dart';
import '../../domain/group_treasure_stat_boxes_resolver.dart';

/// Callback "Réclamer" un objet du butin — voir
/// `GroupRepository.claimTreasureItem`.
typedef ClaimGroupTreasureItemCallback = void Function(GroupTreasureItem item);

/// Contenu de l'onglet "Butin" de l'écran "Groupe" —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
///
/// [isBusy] verrouille toutes les actions d'écriture pendant qu'un appel
/// réseau (réclamation de monnaie/d'objet, ajout au butin) est en vol — même
/// principe que `CharacterInventoryTabBody.actionsDisabled`.
class GroupTreasureTabBody extends StatelessWidget {
  const GroupTreasureTabBody({
    required this.treasure,
    required this.isBusy,
    required this.onClaimCurrency,
    required this.onClaimItem,
    required this.onAddToTreasure,
    super.key,
  });

  final GroupTreasure treasure;
  final bool isBusy;
  final VoidCallback onClaimCurrency;
  final ClaimGroupTreasureItemCallback onClaimItem;
  final VoidCallback onAddToTreasure;

  @override
  Widget build(BuildContext context) {
    final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const _SectionLabel('MONNAIE COMMUNE'),
              const SizedBox(height: AppSpacing.sm),
              CharacterInventoryStatBoxesRow(boxes: boxes),
              const SizedBox(height: AppSpacing.sm),
              DashedButton(
                icon: Icons.savings_outlined,
                label: 'Répartir vers mon inventaire',
                onPressed: (!isBusy && !treasure.hasNoCurrency)
                    ? onClaimCurrency
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionLabel('OBJETS EN ATTENTE'),
              const SizedBox(height: AppSpacing.sm),
              if (treasure.items.isEmpty)
                const _EmptyTreasureItemsState()
              else
                for (final item in treasure.items) ...[
                  _TreasureItemRow(
                    item: item,
                    onClaim: isBusy ? null : () => onClaimItem(item),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SecondaryButton(
            label: 'Ajouter au butin du groupe',
            icon: Icons.card_giftcard,
            surface: SecondaryButtonSurface.parchment,
            borderColor: AppColors.goldEnd,
            onPressed: isBusy ? null : onAddToTreasure,
          ),
        ),
      ],
    );
  }
}

/// Libellé de section ("MONNAIE COMMUNE"/"OBJETS EN ATTENTE") — même style de
/// libellé de section que `ProfilePrivacyScreen` (section "MES DONNÉES",
/// `font.body` 13px/800 `textSecondary`), recettage direction-artistique du
/// 13/09/2026.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Ligne d'objet en attente d'attribution — vignette carrée 40×40
/// (placeholder, aucune image disponible pour ce butin dénormalisé, voir la
/// doc de classe de [GroupTreasureItem]), nom/sous-titre sur 2 lignes puis
/// lien texte "S'attribuer" (calque `GroupRepository.claimTreasureItem`) —
/// recettage direction-artistique du 13/09/2026, remplace l'ancien
/// `IconButton(Icons.call_split)`.
class _TreasureItemRow extends StatelessWidget {
  const _TreasureItemRow({required this.item, required this.onClaim});

  final GroupTreasureItem item;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final disabled = onClaim == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.parchmentCardAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '× ${item.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: InkWell(
              onTap: onClaim,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      "S'attribuer",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? AppColors.textMuted
                            : AppColors.accentTeal,
                      ),
                    ),
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

/// État vide (aucun objet en attente) — les stat boxes de monnaie restent
/// affichées autour de cet état, voir [GroupTreasureTabBody.build].
class _EmptyTreasureItemsState extends StatelessWidget {
  const _EmptyTreasureItemsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun objet en attente.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
