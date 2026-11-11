import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Bouton texte secondaire « Corriger » (icône `tune`, cible d'au moins
/// 44×44) qui ouvre la feuille de correction ; `null` pour [onPressed] le
/// désactive.
class SpellSlotCorrectionButton extends StatelessWidget {
  const SpellSlotCorrectionButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.tune, size: 18),
      label: Text(l10n.spellSlotCorrectionOpenButton),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
        textStyle: AppTypography.body(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
