import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_button.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../characters/domain/currency_kind.dart';
import '../../../characters/presentation/widgets/character_inventory_item_card.dart';
import '../../../characters/presentation/widgets/character_inventory_stat_boxes_row.dart';
import '../../../characters/presentation/widgets/character_inventory_tab_body.dart';
import '../../../characters/presentation/widgets/currency_adjustment_sheet.dart';
import '../../data/group_treasure_inventory_adapter.dart';
import '../../domain/group_treasure.dart';
import '../../domain/group_treasure_item.dart';
import '../../domain/group_treasure_stat_boxes_resolver.dart';

/// Contenu de l'onglet "Butin" de l'écran "Groupe" —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2, aligné sur
/// l'onglet « Inventaire » par la décision 91 (`docs/spec-butin-groupe.md`) :
/// mêmes tuiles de monnaie (toucher une tuile l'ajuste, conversion
/// comprise), mêmes cartes d'objet (toucher une carte ouvre la fiche de
/// l'objet, jamais d'action directe sur la ligne) et même tuile « Objet » en
/// pied de liste. Toutes les écritures sont orchestrées par l'appelant
/// (`group_screen.dart`), comme pour l'inventaire.
///
/// [isBusy] verrouille les écritures pendant qu'un appel réseau est en vol ;
/// [isOffline] les verrouille hors connexion (pas de file hors ligne pour
/// le butin, données partagées) avec un bandeau. Toucher une carte reste
/// toujours possible (la fiche s'ouvre en lecture).
///
/// [canClaim] `false` pour un MJ sans personnage (`GroupMember.isGameMaster`)
/// : il gère le butin (ajout, modification, retrait, monnaie) mais ne peut
/// pas s'en attribuer une part — assourdit « Répartir vers mon inventaire ».
class GroupTreasureTabBody extends StatelessWidget {
  const GroupTreasureTabBody({
    required this.treasure,
    required this.isBusy,
    required this.canClaim,
    required this.onClaimCurrency,
    required this.onOpenItem,
    required this.onAddItems,
    required this.onAdjustCurrency,
    this.onConvertCurrency,
    this.isOffline = false,
    super.key,
  });

  final GroupTreasure treasure;
  final bool isBusy;
  final bool canClaim;
  final bool isOffline;

  /// « Répartir vers mon inventaire ».
  final VoidCallback onClaimCurrency;

  /// Toucher une carte : ouvre la fiche de l'objet.
  final ValueChanged<GroupTreasureItem> onOpenItem;

  /// Tuile « Objet » : ajout par le parcours de l'inventaire.
  final VoidCallback onAddItems;

  /// Nouveau solde **absolu** d'une monnaie (sheet d'ajustement de
  /// l'inventaire).
  final void Function(CurrencyKind currency, int newAmount) onAdjustCurrency;

  /// Nouveaux soldes absolus des deux pièces d'une conversion ; `null`
  /// masque « Changer ».
  final ValueChanged<Map<CurrencyKind, int>>? onConvertCurrency;

  bool get _writesEnabled => !isBusy && !isOffline;

  int _amountOf(CurrencyKind currency) => switch (currency) {
    CurrencyKind.platinum => treasure.currencyPp,
    CurrencyKind.gold => treasure.currencyGp,
    CurrencyKind.electrum => treasure.currencyEp,
    CurrencyKind.silver => treasure.currencySp,
    CurrencyKind.copper => treasure.currencyCp,
  };

  Future<void> _openCurrencyAdjustment(
    BuildContext context,
    CurrencyKind currency,
  ) {
    return showCurrencyAdjustmentSheet(
      context,
      currency: currency,
      currentAmount: _amountOf(currency),
      onApply: (newAmount) => onAdjustCurrency(currency, newAmount),
      balances: {for (final kind in CurrencyKind.values) kind: _amountOf(kind)},
      onConvert: onConvertCurrency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (isOffline) ...[
          InfoBanner(
            icon: Icons.cloud_off,
            message: l10n.groupTreasureOfflineBanner,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!canClaim) ...[
          InfoBanner(
            icon: Icons.visibility_outlined,
            message: l10n.groupTreasureGameMasterBanner,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _SectionLabel(l10n.groupTreasureCurrencySectionLabel),
        const SizedBox(height: AppSpacing.sm),
        CharacterInventoryStatBoxesRow(
          boxes: boxes,
          onTapCurrency: _writesEnabled
              ? (currency) => _openCurrencyAdjustment(context, currency)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        DashedButton(
          icon: Icons.savings_outlined,
          label: l10n.groupTreasureSplitCurrencyButton,
          onPressed: (canClaim && _writesEnabled && !treasure.hasNoCurrency)
              ? onClaimCurrency
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel(l10n.groupTreasureItemsSectionLabel),
        const SizedBox(height: AppSpacing.sm),
        if (treasure.items.isEmpty)
          const _EmptyTreasureItemsState()
        else
          for (final item in treasure.items) ...[
            CharacterInventoryItemCard(
              item: GroupTreasureInventoryAdapter.toInventoryItem(item),
              onTap: () => onOpenItem(item),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.sm),
        InventoryAddRowButtons(
          onAddItem: _writesEnabled ? onAddItems : null,
          showRewardButton: false,
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

/// État vide (aucun objet en attente) — les tuiles de monnaie et la tuile
/// « Objet » restent affichées autour de cet état.
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
              AppLocalizations.of(context)!.groupTreasureEmptyItems,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
