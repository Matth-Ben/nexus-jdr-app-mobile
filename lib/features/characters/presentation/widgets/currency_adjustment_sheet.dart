import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../domain/currency_kind.dart';

enum _CurrencyAdjustmentMode { add, remove }

/// Ouvre la sheet d'ajustement de monnaie (tap sur une stat box de monnaie
/// de tête d'onglet, `character_inventory_stat_boxes_row.dart`) — calque
/// exact de `hp_adjustment_sheet.dart` (`SegmentedToggle`
/// "Ajouter"/"Retirer", `StepperCounter` centré, pied Annuler/Appliquer).
///
/// [onApply] reçoit le nouveau montant **absolu** déjà calculé (même
/// principe que `showHpAdjustmentSheet` : l'appelant, `character_detail_screen
/// .dart::_adjustCurrency`, est responsable de l'écrire en base via
/// `CharacterRepository.adjustCurrency`).
Future<void> showCurrencyAdjustmentSheet(
  BuildContext context, {
  required CurrencyKind currency,
  required int currentAmount,
  required ValueChanged<int> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _CurrencyAdjustmentSheetContent(
      currency: currency,
      currentAmount: currentAmount,
      onApply: onApply,
    ),
  );
}

class _CurrencyAdjustmentSheetContent extends StatefulWidget {
  const _CurrencyAdjustmentSheetContent({
    required this.currency,
    required this.currentAmount,
    required this.onApply,
  });

  final CurrencyKind currency;
  final int currentAmount;
  final ValueChanged<int> onApply;

  @override
  State<_CurrencyAdjustmentSheetContent> createState() =>
      _CurrencyAdjustmentSheetContentState();
}

class _CurrencyAdjustmentSheetContentState
    extends State<_CurrencyAdjustmentSheetContent> {
  _CurrencyAdjustmentMode _mode = _CurrencyAdjustmentMode.add;
  int _amount = 0;

  /// En mode "Retirer", [_amount] ne peut jamais dépasser
  /// [CurrencyAdjustmentSheetContent.currentAmount] — jamais de solde
  /// négatif, même règle que `HpAdjustmentCalculator`. Réévalué à chaque
  /// changement de mode (bascule "Ajouter" -> "Retirer" avec un montant déjà
  /// saisi supérieur au solde disponible).
  void _selectMode(_CurrencyAdjustmentMode mode) {
    setState(() {
      _mode = mode;
      if (mode == _CurrencyAdjustmentMode.remove &&
          _amount > widget.currentAmount) {
        _amount = widget.currentAmount;
      }
    });
  }

  void _apply() {
    final newAmount = _mode == _CurrencyAdjustmentMode.add
        ? widget.currentAmount + _amount
        : widget.currentAmount - _amount;
    widget.onApply(newAmount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final atBalanceCap =
        _mode == _CurrencyAdjustmentMode.remove &&
        _amount >= widget.currentAmount;

    return SafeArea(
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
              'Ajuster les ${widget.currency.fullLabel}',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedToggle<_CurrencyAdjustmentMode>(
              options: const [
                SegmentedToggleOption(
                  value: _CurrencyAdjustmentMode.add,
                  label: 'Ajouter',
                ),
                SegmentedToggleOption(
                  value: _CurrencyAdjustmentMode.remove,
                  label: 'Retirer',
                ),
              ],
              value: _mode,
              onChanged: _selectMode,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StepperCounter(
                value: _amount,
                onIncrement: atBalanceCap
                    ? null
                    : () => setState(() => _amount++),
                onDecrement: _amount > 0
                    ? () => setState(() => _amount--)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Appliquer',
                    onPressed: _amount > 0 ? _apply : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
