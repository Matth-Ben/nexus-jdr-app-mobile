import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/currency_kind.dart';
import '../../domain/inventory_catalog_item.dart';
import '../../domain/inventory_category_filter.dart';
import '../../domain/inventory_stat_boxes_resolver.dart';
import 'add_item_flow.dart';
import 'character_inventory_capacity_gauge.dart';
import 'character_inventory_item_card.dart';
import 'character_inventory_stat_boxes_row.dart';
import 'currency_adjustment_sheet.dart';
import 'item_action_sheet.dart';

/// Contenu de l'onglet "Inventaire" de la fiche personnage — voir
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
/// Inventaire".
///
/// Toutes les actions d'écriture (Utiliser/Équiper/Retirer un objet,
/// ajuster une monnaie, ajouter un objet du catalogue/personnalisé)
/// délèguent leur logique d'écriture (optimiste + réseau + message) à
/// l'appelant (`character_detail_screen.dart`), même principe que
/// `CharacterSpellsTabBody`/`onCastSpell` — cet écran se contente
/// d'orchestrer l'ouverture des sheets et de relayer leur résultat.
///
/// Les objets sont affichés dans l'ordre renvoyé par la requête
/// (`SupabaseCharacterRepository._buildCharacterDetailPayload`/
/// `_mapCharacterDetailPayload`), sans tri ni
/// regroupement par catégorie : `character_inventory` n'a pas de colonne de
/// tri naturelle côté schéma (vérifié contre les migrations réelles), et la
/// maquette ne montre elle-même aucun regroupement visuel par catégorie.
///
/// `StatefulWidget` (depuis l'ajout de la bascule de filtre "Tout"/"Armes"/
/// "Armures"/"Consomm."/"Divers", voir `domain/inventory_category_filter.dart`)
/// : même rationale que `CharacterSpellsTabBody` (confort d'affichage
/// purement local, rien à persister).
///
/// [CharacterInventoryCapacityGauge] (charge portée vs. capacité de
/// transport dérivée de la Force) est affichée juste sous les stat boxes de
/// monnaie, toujours présente (même inventaire vide) — voir sa
/// documentation de classe.
class CharacterInventoryTabBody extends StatefulWidget {
  const CharacterInventoryTabBody({
    required this.detail,
    required this.onUseItem,
    required this.onToggleItemEquipped,
    required this.onToggleItemAttuned,
    required this.onRemoveItem,
    required this.onAdjustCurrency,
    required this.onAddInventoryItem,
    required this.onAddCustomInventoryItem,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;

  final UseInventoryItemCallback onUseItem;
  final ToggleInventoryItemEquippedCallback onToggleItemEquipped;
  final ToggleInventoryItemAttunedCallback onToggleItemAttuned;
  final RemoveInventoryItemCallback onRemoveItem;

  /// Reçoit la monnaie ajustée et le nouveau montant *absolu* déjà calculé
  /// par la sheet (`currency_adjustment_sheet.dart`).
  final void Function(CurrencyKind currency, int newAmount) onAdjustCurrency;

  /// Reçoit l'objet du catalogue choisi et la quantité déjà saisie (sheet
  /// "Depuis le catalogue", `add_item_flow.dart`).
  final void Function(InventoryCatalogItem item, int quantity)
  onAddInventoryItem;

  /// Reçoit le nom saisi et la quantité (sheet "Objet personnalisé").
  final void Function(String customName, int quantity) onAddCustomInventoryItem;

  /// `true` pendant qu'une écriture de cet onglet est en vol (voir
  /// `character_detail_screen.dart::_isWritingInventory`) : désactive le tap
  /// sur chaque carte d'objet, chaque stat box de monnaie et la tuile
  /// "Ajouter un objet" — aucun repos (court ou long) ne touche l'inventaire
  /// ou la monnaie (vérifié contre `CharacterRepository.applyRest`), donc ce
  /// verrou est le seul nécessaire ici, contrairement aux onglets "Sorts"/
  /// "Compétences" qui doivent aussi se verrouiller pendant un repos.
  final bool actionsDisabled;

  @override
  State<CharacterInventoryTabBody> createState() =>
      _CharacterInventoryTabBodyState();
}

class _CharacterInventoryTabBodyState
    extends State<CharacterInventoryTabBody> {
  InventoryCategoryFilter _filter = InventoryCategoryFilter.all;

  Future<void> _openItemActions(
    BuildContext context,
    CharacterInventoryItem item,
  ) {
    return showItemActionSheet(
      context,
      item: item,
      onUseItem: widget.onUseItem,
      onToggleEquipped: widget.onToggleItemEquipped,
      onToggleAttuned: widget.onToggleItemAttuned,
      onRemoveItem: widget.onRemoveItem,
      attunedCount: widget.detail.attunedItemCount,
    );
  }

  Future<void> _openCurrencyAdjustment(
    BuildContext context,
    CurrencyKind currency,
  ) {
    return showCurrencyAdjustmentSheet(
      context,
      currency: currency,
      currentAmount: _currentAmountOf(widget.detail, currency),
      onApply: (newAmount) => widget.onAdjustCurrency(currency, newAmount),
    );
  }

  Future<void> _openAddItem(BuildContext context) async {
    final picked = await pickInventoryAddition(context);
    if (picked == null) return;

    if (picked.isCustom) {
      widget.onAddCustomInventoryItem(picked.customName!, picked.quantity);
    } else {
      widget.onAddInventoryItem(picked.item!, picked.quantity);
    }
  }

  static int _currentAmountOf(CharacterDetail detail, CurrencyKind currency) =>
      switch (currency) {
        CurrencyKind.platinum => detail.currencyPp,
        CurrencyKind.gold => detail.currencyGp,
        CurrencyKind.electrum => detail.currencyEp,
        CurrencyKind.silver => detail.currencySp,
        CurrencyKind.copper => detail.currencyCp,
      };

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final statBoxes = InventoryStatBoxesResolver.resolve(detail);
    final isEmpty = detail.inventory.isEmpty;
    final filteredItems = InventoryCategoryFilter.apply(
      detail.inventory,
      _filter,
    );
    final noFilterMatch = !isEmpty && filteredItems.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CharacterInventoryStatBoxesRow(
          boxes: statBoxes,
          onTapCurrency: widget.actionsDisabled
              ? null
              : (currency) => _openCurrencyAdjustment(context, currency),
        ),
        const SizedBox(height: AppSpacing.md),
        CharacterInventoryCapacityGauge(detail: detail),
        if (!isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SegmentedToggle<InventoryCategoryFilter>(
            options: [
              for (final option in InventoryCategoryFilter.values)
                SegmentedToggleOption(value: option, label: option.label),
            ],
            value: _filter,
            onChanged: (value) => setState(() => _filter = value),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (isEmpty)
          const _EmptyInventoryState()
        else if (noFilterMatch)
          const _NoFilterMatchState()
        else
          for (final item in filteredItems) ...[
            CharacterInventoryItemCard(
              item: item,
              onTap: widget.actionsDisabled
                  ? null
                  : () => _openItemActions(context, item),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (isEmpty) const SizedBox(height: AppSpacing.md),
        DashedAddTile(
          label: 'Ajouter un objet',
          onTap: widget.actionsDisabled ? null : () => _openAddItem(context),
        ),
      ],
    );
  }
}

/// État "aucun objet dans cette catégorie" — distinct de
/// [_EmptyInventoryState] (inventaire réellement vide) : au moins un objet
/// existe, mais aucun ne correspond au filtre actuellement actif (voir
/// `domain/inventory_category_filter.dart`). Même
/// agencement compact que
/// `character_spells_tab_body.dart::_NoSearchMatchState`.
class _NoFilterMatchState extends StatelessWidget {
  const _NoFilterMatchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Text(
          'Aucun objet dans cette catégorie.',
          textAlign: TextAlign.center,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

/// État vide (aucun objet dans l'inventaire) — calque
/// `character_spells_tab_body.dart::_EmptySpellsState`. Les stat boxes de
/// monnaie et la tuile "Ajouter un objet" restent affichées autour de cet
/// état (voir [CharacterInventoryTabBody.build]) : contrairement à l'onglet
/// "Sorts" (où l'état vide remplace tout l'écran), la monnaie existe
/// indépendamment du contenu de la liste d'objets.
class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.backpack, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'INVENTAIRE VIDE',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun objet dans cet inventaire pour l\'instant.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
