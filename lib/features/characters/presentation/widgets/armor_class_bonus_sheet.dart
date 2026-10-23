import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/stepper_counter.dart';

enum _ArmorClassAdjustmentSign { bonus, malus }

/// Ouvre la sheet d'ajustement manuel de Classe d'Armure (tap sur la tuile
/// "CA" de `CharacterStatPillsRow`) — calque exact de
/// `currency_adjustment_sheet.dart` (lui-même calqué sur
/// `hp_adjustment_sheet.dart`) : `SegmentedToggle` "Bonus"/"Malus",
/// `StepperCounter` centré pour la magnitude (toujours >= 0, jamais de "-"
/// brut affiché — le signe est porté par le toggle), pied "Effacer"/
/// "Valider".
///
/// Contrairement à `showCurrencyAdjustmentSheet`/`showHpAdjustmentSheet`,
/// pas de 3ème bouton "Annuler" : la sheet est déjà dismissible (tap en
/// dehors, swipe vers le bas) et un bouton dédié serait redondant une fois
/// "Effacer" présent (spec de la tâche "Ajustement de CA").
///
/// [currentBonus] peut être négatif (malus) — voir `CharacterDetail
/// .armorClassBonus`. [onApply] reçoit la nouvelle valeur **absolue** déjà
/// signée (même principe que `showCurrencyAdjustmentSheet` : l'appelant,
/// `character_detail_screen.dart`, est responsable de l'écrire en base via
/// `CharacterRepository.setArmorClassBonus`).
Future<void> showArmorClassBonusSheet(
  BuildContext context, {
  required int currentBonus,
  required ValueChanged<int> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _ArmorClassBonusSheetContent(
      currentBonus: currentBonus,
      onApply: onApply,
    ),
  );
}

class _ArmorClassBonusSheetContent extends StatefulWidget {
  const _ArmorClassBonusSheetContent({
    required this.currentBonus,
    required this.onApply,
  });

  final int currentBonus;
  final ValueChanged<int> onApply;

  @override
  State<_ArmorClassBonusSheetContent> createState() =>
      _ArmorClassBonusSheetContentState();
}

class _ArmorClassBonusSheetContentState
    extends State<_ArmorClassBonusSheetContent> {
  late _ArmorClassAdjustmentSign _sign;
  late int _magnitude;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage (spec de la tâche) : un bonus nul ou positif ouvre sur
    // "Bonus" (jamais "Malus" pour 0, qui n'a pas de signe propre), un bonus
    // strictement négatif ouvre sur "Malus" avec sa magnitude positive.
    if (widget.currentBonus < 0) {
      _sign = _ArmorClassAdjustmentSign.malus;
      _magnitude = -widget.currentBonus;
    } else {
      _sign = _ArmorClassAdjustmentSign.bonus;
      _magnitude = widget.currentBonus;
    }
  }

  void _clear() {
    widget.onApply(0);
    Navigator.of(context).pop();
  }

  void _apply() {
    final value = _sign == _ArmorClassAdjustmentSign.malus
        ? -_magnitude
        : _magnitude;
    widget.onApply(value);
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
              'Ajustement de CA',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedToggle<_ArmorClassAdjustmentSign>(
              options: const [
                SegmentedToggleOption(
                  value: _ArmorClassAdjustmentSign.bonus,
                  label: 'Bonus',
                ),
                SegmentedToggleOption(
                  value: _ArmorClassAdjustmentSign.malus,
                  label: 'Malus',
                ),
              ],
              value: _sign,
              onChanged: (sign) => setState(() => _sign = sign),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StepperCounter(
                value: _magnitude,
                onIncrement: () => setState(() => _magnitude++),
                onDecrement: _magnitude > 0
                    ? () => setState(() => _magnitude--)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Effacer',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: _clear,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(label: 'Valider', onPressed: _apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
