import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../domain/hp_adjustment.dart';

enum _HpAdjustmentMode { damage, heal, temporary }

/// Ouvre la feuille d'ajustement PV détaillée (bouton crayon du bandeau PV) —
/// voir `domain/hp_adjustment.dart` pour la logique de calcul (dégâts/soins/
/// PV temporaires). [onApply] reçoit le nouvel état déjà calculé ; l'appelant
/// (`character_detail_screen.dart`) est responsable de l'écrire en base
/// (`CharacterRepository.updateHp`) et de rafraîchir la fiche.
Future<void> showHpAdjustmentSheet(
  BuildContext context, {
  required HpState state,
  required ValueChanged<HpState> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) =>
        _HpAdjustmentSheetContent(state: state, onApply: onApply),
  );
}

class _HpAdjustmentSheetContent extends StatefulWidget {
  const _HpAdjustmentSheetContent({required this.state, required this.onApply});

  final HpState state;
  final ValueChanged<HpState> onApply;

  @override
  State<_HpAdjustmentSheetContent> createState() =>
      _HpAdjustmentSheetContentState();
}

class _HpAdjustmentSheetContentState extends State<_HpAdjustmentSheetContent> {
  _HpAdjustmentMode _mode = _HpAdjustmentMode.damage;
  int _amount = 0;

  void _apply() {
    final newState = switch (_mode) {
      _HpAdjustmentMode.damage => HpAdjustmentCalculator.applyDamage(
        widget.state,
        _amount,
      ),
      _HpAdjustmentMode.heal => HpAdjustmentCalculator.applyHeal(
        widget.state,
        _amount,
      ),
      _HpAdjustmentMode.temporary => HpAdjustmentCalculator.applyTemporaryHp(
        widget.state,
        _amount,
      ),
    };
    widget.onApply(newState);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
              'Ajuster les PV',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedToggle<_HpAdjustmentMode>(
              options: const [
                SegmentedToggleOption(
                  value: _HpAdjustmentMode.damage,
                  label: 'Dégâts',
                ),
                SegmentedToggleOption(
                  value: _HpAdjustmentMode.heal,
                  label: 'Soins',
                ),
                SegmentedToggleOption(
                  value: _HpAdjustmentMode.temporary,
                  label: 'PV temp.',
                ),
              ],
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StepperCounter(
                value: _amount,
                onIncrement: () => setState(() => _amount++),
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
