import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/numeric_amount_stepper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/currency_kind.dart';
import 'currency_conversion_sheet.dart';

enum _CurrencyAdjustmentMode { add, remove }

/// Borne haute de la saisie d'un ajout de monnaie (6 chiffres).
const int _maxAddAmount = 999999;

/// Ouvre la sheet d'ajustement de monnaie (tap sur une stat box de monnaie
/// de tête d'onglet, `character_inventory_stat_boxes_row.dart`) — calque
/// exact de `hp_adjustment_sheet.dart` (`SegmentedToggle`
/// "Ajouter"/"Retirer", `NumericAmountStepper` centré, pied
/// Annuler/Appliquer).
///
/// [onApply] reçoit le nouveau montant **absolu** déjà calculé (même
/// principe que `showHpAdjustmentSheet` : l'appelant, `character_detail_screen
/// .dart::_adjustCurrency`, est responsable de l'écrire en base via
/// `CharacterRepository.adjustCurrency`).
///
/// Si [balances] et [onConvert] sont fournis, un bouton secondaire "Changer"
/// ferme cette sheet et ouvre `showCurrencyConversionSheet` ; [onConvert]
/// reçoit alors les nouveaux soldes **absolus** des deux pièces touchées.
Future<void> showCurrencyAdjustmentSheet(
  BuildContext context, {
  required CurrencyKind currency,
  required int currentAmount,
  required ValueChanged<int> onApply,
  Map<CurrencyKind, int>? balances,
  ValueChanged<Map<CurrencyKind, int>>? onConvert,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _CurrencyAdjustmentSheetContent(
      currency: currency,
      currentAmount: currentAmount,
      onApply: onApply,
      balances: balances,
      onConvert: onConvert,
    ),
  );
}

class _CurrencyAdjustmentSheetContent extends StatefulWidget {
  const _CurrencyAdjustmentSheetContent({
    required this.currency,
    required this.currentAmount,
    required this.onApply,
    required this.balances,
    required this.onConvert,
  });

  final CurrencyKind currency;
  final int currentAmount;
  final ValueChanged<int> onApply;
  final Map<CurrencyKind, int>? balances;
  final ValueChanged<Map<CurrencyKind, int>>? onConvert;

  @override
  State<_CurrencyAdjustmentSheetContent> createState() =>
      _CurrencyAdjustmentSheetContentState();
}

class _CurrencyAdjustmentSheetContentState
    extends State<_CurrencyAdjustmentSheetContent> {
  _CurrencyAdjustmentMode _mode = _CurrencyAdjustmentMode.add;
  int _amount = 0;

  /// En mode "Retirer", [_amount] ne peut jamais dépasser le solde actuel —
  /// jamais de solde négatif, même règle que `HpAdjustmentCalculator`.
  /// Réévalué à chaque changement de mode (bascule "Ajouter" -> "Retirer"
  /// avec un montant déjà saisi supérieur au solde disponible).
  int get _maxAmount => _mode == _CurrencyAdjustmentMode.remove
      ? widget.currentAmount.clamp(0, _maxAddAmount)
      : _maxAddAmount;

  void _selectMode(_CurrencyAdjustmentMode mode) {
    setState(() {
      _mode = mode;
      if (_amount > _maxAmount) _amount = _maxAmount;
    });
  }

  void _apply() {
    final newAmount = _mode == _CurrencyAdjustmentMode.add
        ? widget.currentAmount + _amount
        : widget.currentAmount - _amount;
    widget.onApply(newAmount);
    Navigator.of(context).pop();
  }

  void _openConversion() {
    final navigator = Navigator.of(context);
    final balances = widget.balances!;
    final onConvert = widget.onConvert!;
    navigator.pop();
    // Le contexte du Navigator survit à la fermeture de cette sheet.
    showCurrencyConversionSheet(
      navigator.context,
      balances: balances,
      initialSource: widget.currency,
      onApply: onConvert,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canConvert = widget.balances != null && widget.onConvert != null;

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
                l10n.currencyAdjustmentSheetTitle(widget.currency.fullLabel),
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedToggle<_CurrencyAdjustmentMode>(
                options: [
                  SegmentedToggleOption(
                    value: _CurrencyAdjustmentMode.add,
                    label: l10n.currencyAdjustmentSheetAddOption,
                  ),
                  SegmentedToggleOption(
                    value: _CurrencyAdjustmentMode.remove,
                    label: l10n.currencyAdjustmentSheetRemoveOption,
                  ),
                ],
                value: _mode,
                onChanged: _selectMode,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NumericAmountStepper(
                      value: _amount,
                      max: _maxAmount,
                      autofocus: true,
                      fieldLabel: l10n.currencyAdjustmentSheetAmountFieldLabel,
                      decrementLabel: l10n.numericAmountDecreaseLabel,
                      incrementLabel: l10n.numericAmountIncreaseLabel,
                      onChanged: (value) => setState(() => _amount = value),
                    ),
                    _AmountHint(
                      _mode == _CurrencyAdjustmentMode.remove
                          ? l10n.currencyAdjustmentSheetBalanceHint(
                              widget.currentAmount,
                            )
                          : l10n.numericAmountMaxHint(_maxAddAmount),
                    ),
                  ],
                ),
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
                      label: l10n.currencyAdjustmentSheetApplyButton,
                      onPressed: _amount > 0 ? _apply : null,
                    ),
                  ),
                ],
              ),
              if (canConvert) ...[
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: l10n.currencyAdjustmentSheetConvertButton,
                  surface: SecondaryButtonSurface.parchment,
                  icon: Icons.swap_horiz,
                  onPressed: _openConversion,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Aide sous le champ de montant (borne saisissable), `text.muted` 11 px.
class _AmountHint extends StatelessWidget {
  const _AmountHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
      ),
    );
  }
}
