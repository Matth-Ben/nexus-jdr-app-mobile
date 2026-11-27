import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/currency_picker_chips.dart';
import '../../../../core/widgets/numeric_amount_stepper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../character_creation/domain/gold_amount_formatter.dart';
import '../../domain/currency_kind.dart';
import '../../domain/custom_item_enrichment.dart' show priceOverrideAmountMax;

/// Résultat de [showItemPriceOverrideSheet] : surcharge saisie ([amount]/
/// [currency], `null` ensemble = aucune surcharge), ou retrait via le lien
/// « Retirer la surcharge » ([removedViaLink], voir sa documentation).
class ItemPriceOverrideResult {
  const ItemPriceOverrideResult({
    required this.amount,
    required this.currency,
    this.removedViaLink = false,
  });

  final num? amount;
  final CurrencyKind? currency;

  /// `true` : résultat produit par le lien « Retirer la surcharge » (§2d) —
  /// l'appelant affiche alors `itemPriceOverrideRemovedSnack` (aucun
  /// snackbar sinon : la fermeture de la sheet après « Enregistrer » suffit
  /// comme confirmation visuelle, même principe que les autres réglages
  /// d'état de cet onglet).
  final bool removedViaLink;
}

/// Ouvre la sheet autonome de surcharge de prix d'un objet du **catalogue**
/// (spec du prix d'un objet modifiable, §2b/§2d) — ouverte par la nouvelle
/// action « Modifier » de `item_action_sheet.dart` (`onEditItemPrice`),
/// jamais pour un objet personnalisé (son prix se fixe dans
/// `custom_item_form_sheet.dart`, §2a). Ne permet jamais de modifier la
/// quantité (hors périmètre).
///
/// [officialPriceAmount] (en or, `CharacterInventoryItem.costAmount`) :
/// rappelé en légende s'il est connu ; `null` (objet magique sans coût
/// officiel) n'affiche aucune légende. [initialAmount]/[initialCurrency] :
/// surcharge déjà posée (`null` : champ vide/à 0 — jamais le prix officiel
/// pré-converti, aucune règle de conversion fiable d'un montant décimal en
/// or vers un entier dans une autre devise).
Future<ItemPriceOverrideResult?> showItemPriceOverrideSheet(
  BuildContext context, {
  required String itemName,
  double? officialPriceAmount,
  num? initialAmount,
  CurrencyKind? initialCurrency,
}) {
  return showModalBottomSheet<ItemPriceOverrideResult>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _ItemPriceOverrideSheetContent(
      itemName: itemName,
      officialPriceAmount: officialPriceAmount,
      initialAmount: initialAmount,
      initialCurrency: initialCurrency,
    ),
  );
}

class _ItemPriceOverrideSheetContent extends StatefulWidget {
  const _ItemPriceOverrideSheetContent({
    required this.itemName,
    required this.officialPriceAmount,
    required this.initialAmount,
    required this.initialCurrency,
  });

  final String itemName;
  final double? officialPriceAmount;
  final num? initialAmount;
  final CurrencyKind? initialCurrency;

  @override
  State<_ItemPriceOverrideSheetContent> createState() =>
      _ItemPriceOverrideSheetContentState();
}

class _ItemPriceOverrideSheetContentState
    extends State<_ItemPriceOverrideSheetContent> {
  late int _amount = (widget.initialAmount ?? 0).round().clamp(
    0,
    priceOverrideAmountMax,
  );
  late CurrencyKind _currency = widget.initialCurrency ?? CurrencyKind.gold;

  /// Une surcharge existe déjà : affiche le lien « Retirer la surcharge »
  /// (§2d).
  bool get _hasExistingOverride => widget.initialAmount != null;

  void _save() {
    Navigator.of(context).pop(
      ItemPriceOverrideResult(
        amount: _amount > 0 ? _amount : null,
        currency: _amount > 0 ? _currency : null,
      ),
    );
  }

  void _removeOverride() {
    Navigator.of(context).pop(
      const ItemPriceOverrideResult(
        amount: null,
        currency: null,
        removedViaLink: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final official = widget.officialPriceAmount;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.itemPriceOverrideSheetTitle(widget.itemName),
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (official != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.itemPriceOverrideOfficialCaption(
                    l10n.itemPriceValue(
                      GoldAmountFormatter.format(official),
                      CurrencyKind.gold.unitLabel,
                    ),
                  ),
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Center(
                child: NumericAmountStepper(
                  value: _amount,
                  max: priceOverrideAmountMax,
                  autofocus: true,
                  fieldLabel: l10n.customItemPriceSectionLabel,
                  decrementLabel: l10n.numericAmountDecreaseLabel,
                  incrementLabel: l10n.numericAmountIncreaseLabel,
                  onChanged: (value) => setState(() => _amount = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CurrencyPickerChips(
                value: _currency,
                onChanged: (value) => setState(() => _currency = value),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.currencyAdjustmentSheetCancelButton,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.itemPriceOverrideSaveButton,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
              if (_hasExistingOverride) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(child: _RemoveOverrideLink(onTap: _removeOverride)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lien « Retirer la surcharge » (§2d) — même gabarit que
/// `item_info_panel.dart::_ToggleAttunedLink` (`body` 13 w700
/// `textSecondary`, zone de tap 44 px min-height), icône
/// [Icons.remove_circle_outline]. Aucune confirmation (non destructif, le
/// prix officiel n'est jamais perdu).
class _RemoveOverrideLink extends StatelessWidget {
  const _RemoveOverrideLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.itemPriceOverrideRemoveLink,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.remove_circle_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.itemPriceOverrideRemoveLink,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
