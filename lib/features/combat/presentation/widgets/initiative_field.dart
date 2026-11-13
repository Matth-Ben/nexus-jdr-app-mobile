import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/initiative_input.dart';

/// Champ numérique signé (-20..60) encadré de compteurs − / + (zone de tap
/// 44×44, visuel 28). Vide : « + » / « − » donnent 10 ; hors bornes : erreur
/// (fond `alert-bg`, bordure brick, icône + « Entre -20 et 60 ») ; vide : pas
/// d'erreur (c'est l'appelant qui désactive « Enregistrer »).
class InitiativeField extends StatelessWidget {
  const InitiativeField({
    required this.controller,
    required this.onChanged,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final FocusNode? focusNode;

  void _step(int delta) {
    final next = stepInitiative(parseInitiativeInput(controller.text), delta);
    controller.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final input = parseInitiativeInput(controller.text);
    final invalid = input.status == InitiativeInputStatus.invalid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.combatInitiativeField,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            StepperButton(
              icon: Icons.remove,
              onPressed: () => _step(-1),
              semanticLabel: l10n.combatInitiativeDecrease,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: TextField(
                  key: const Key('combatInitiativeField'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (_) => onChanged(),
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-−]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: AppTypography.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: _decoration(invalid),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StepperButton(
              icon: Icons.add,
              onPressed: () => _step(1),
              semanticLabel: l10n.combatInitiativeIncrease,
            ),
          ],
        ),
        if (invalid)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.accentBrick,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.combatInitiativeRangeError,
                      style: AppTypography.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBrick,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  InputDecoration _decoration(bool invalid) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: color, width: 1.5),
    );
    return InputDecoration(
      filled: true,
      fillColor: invalid
          ? AppColors.alertBannerBackground
          : AppColors.parchmentCard,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      enabledBorder: border(
        invalid ? AppColors.accentBrick : AppColors.woodLight,
      ),
      focusedBorder: border(
        invalid ? AppColors.accentBrick : AppColors.woodMedium,
      ),
    );
  }
}
