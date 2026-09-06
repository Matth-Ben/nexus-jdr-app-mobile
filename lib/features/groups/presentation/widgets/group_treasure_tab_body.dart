import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
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
              CharacterInventoryStatBoxesRow(boxes: boxes),
              const SizedBox(height: AppSpacing.sm),
              _ClaimCurrencyLink(
                onTap: (!isBusy && !treasure.hasNoCurrency)
                    ? onClaimCurrency
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
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
          child: PrimaryButton(
            label: '+ Ajouter au butin',
            onPressed: isBusy ? null : onAddToTreasure,
          ),
        ),
      ],
    );
  }
}

/// Lien texte "S'attribuer de la monnaie" — calque `_RestLink`
/// (`character_vitals_card.dart`) : `Icons.savings_outlined` 14px, `body`
/// 700/13 `textSecondary`, zone de tap 44px min-height. Désactivé (`onTap`
/// `null`) si le butin commun n'a aucune monnaie ou qu'une écriture est déjà
/// en vol.
class _ClaimCurrencyLink extends StatelessWidget {
  const _ClaimCurrencyLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textMuted : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.savings_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                "S'attribuer de la monnaie",
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne d'objet en attente d'attribution — calque `_RewardItemRow`
/// (`add_reward_sheet.dart`), lecture seule (pas de suppression ici) +
/// `IconButton(44×44, Icons.call_split)` pour réclamer une partie/la
/// totalité de la quantité disponible.
class _TreasureItemRow extends StatelessWidget {
  const _TreasureItemRow({required this.item, required this.onClaim});

  final GroupTreasureItem item;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.displayName} × ${item.quantity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'Réclamer',
              onPressed: onClaim,
              icon: const Icon(
                Icons.call_split,
                color: AppColors.textSecondary,
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
