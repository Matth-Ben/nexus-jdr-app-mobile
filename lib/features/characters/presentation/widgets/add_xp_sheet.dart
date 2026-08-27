import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';

/// Ouvre la feuille "Ajouter de l'XP" (bouton "+" du bandeau XP de
/// `CharacterVitalsCard`, ou lien discret "Monter de niveau manuellement" —
/// non, ce dernier ouvre directement le flux, voir
/// `character_detail_screen.dart`) — sibling direct de
/// `hp_adjustment_sheet.dart`, même patron (`showModalBottomSheet`, fond
/// `parchment.card`, `isScrollControlled: true`).
///
/// [onApply] reçoit uniquement le *montant* d'XP saisi (pas le nouveau total
/// déjà calculé, contrairement à `showHpAdjustmentSheet`) : l'appelant
/// (`character_detail_screen.dart`) est responsable d'ajouter ce montant à
/// `detail.xp`, d'écrire le résultat en base
/// (`CharacterRepository.addXp`) et de déclencher la montée de niveau si un
/// seuil est franchi.
Future<void> showAddXpSheet(
  BuildContext context, {
  required int currentXp,
  required int? nextLevelXpThreshold,
  required ValueChanged<int> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (context) => _AddXpSheetContent(
      currentXp: currentXp,
      nextLevelXpThreshold: nextLevelXpThreshold,
      onApply: onApply,
    ),
  );
}

class _AddXpSheetContent extends StatefulWidget {
  const _AddXpSheetContent({
    required this.currentXp,
    required this.nextLevelXpThreshold,
    required this.onApply,
  });

  final int currentXp;
  final int? nextLevelXpThreshold;
  final ValueChanged<int> onApply;

  @override
  State<_AddXpSheetContent> createState() => _AddXpSheetContentState();
}

class _AddXpSheetContentState extends State<_AddXpSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  /// Montant saisi, `null` tant qu'il n'est pas un entier strictement
  /// positif (champ vide, "0", ou saisie non numérique — ce dernier cas ne
  /// devrait pas arriver, `FilteringTextInputFormatter.digitsOnly` filtre
  /// déjà la saisie, gardé par robustesse).
  int? get _amount {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _apply() {
    final amount = _amount;
    if (amount == null) return;
    widget.onApply(amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Au niveau maximum (`nextLevelXpThreshold` nul), même repli que
    // `CharacterVitalsCard._XpSection` : le seuil affiché retombe sur l'XP
    // actuelle elle-même.
    final threshold = widget.nextLevelXpThreshold ?? widget.currentXp;
    final amount = _amount;

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
              "Ajouter de l'XP",
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'XP actuelle : ${widget.currentXp} / $threshold',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'XP GAGNÉE',
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Ex. 250'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Montant remis par le MJ en fin de séance, par exemple.',
              style: AppTypography.body(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nouveau total : ${widget.currentXp + amount} XP',
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
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
                    label: 'Ajouter',
                    onPressed: amount != null ? _apply : null,
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
