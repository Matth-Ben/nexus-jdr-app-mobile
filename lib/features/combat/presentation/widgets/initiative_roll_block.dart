import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../characters/domain/signed_modifier_formatter.dart';
import '../../../characters/presentation/widgets/dice_roll_sheet.dart';
import '../combat_announcer.dart';

/// Ouvre le lanceur de d20 et renvoie le total retenu (`null` si fermé sans
/// « Utiliser »). Remplaçable dans les tests : le vrai lanceur anime un dé 3D.
typedef InitiativeRollOpener = Future<int?> Function(
  BuildContext context, {
  required String label,
  required int modifier,
  required String Function(int total) useResultLabel,
});

Future<int?> defaultInitiativeRollOpener(
  BuildContext context, {
  required String label,
  required int modifier,
  required String Function(int total) useResultLabel,
}) => showDiceRollSheet(
  context,
  label: label,
  modifier: modifier,
  useResultLabel: useResultLabel,
);

/// Bloc « d20 » de la feuille d'initiative : aide « Dextérité : +3 → d20 + 3 »
/// (PJ seulement, [showDexHelp]) et bouton « Lancer un d20 ». Le total retenu
/// est écrit dans [controller] (champ toujours modifiable : la table peut avoir
/// lancé un vrai dé), le focus revient sur [focusNode] et l'annonce « Résultat
/// repris : {total} » est émise.
///
/// [modifier] : modificateur d'initiative déjà exposé par
/// `CharacterDetail.initiative` (jamais recalculé ici) ; 0 pour un monstre.
class InitiativeRollBlock extends StatelessWidget {
  const InitiativeRollBlock({
    required this.controller,
    required this.focusNode,
    required this.modifier,
    required this.onChanged,
    required this.announcer,
    this.showDexHelp = false,
    this.opener = defaultInitiativeRollOpener,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int modifier;
  final VoidCallback onChanged;
  final CombatSheetAnnouncer announcer;
  final bool showDexHelp;
  final InitiativeRollOpener opener;

  Future<void> _roll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final total = await opener(
      context,
      label: l10n.combatInitiativeField,
      modifier: modifier,
      useResultLabel: l10n.combatUseRoll,
    );
    if (total == null || !context.mounted) return;
    controller.value = TextEditingValue(
      text: '$total',
      selection: TextSelection.collapsed(offset: '$total'.length),
    );
    onChanged();
    focusNode.requestFocus();
    announcer(context, l10n.combatRollUsedAnnounce(total));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signed = SignedModifierFormatter.format(modifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDexHelp)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.combatDexHelp(signed),
              key: const Key('combatDexHelp'),
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        SecondaryButton(
          label: l10n.combatRollD20,
          surface: SecondaryButtonSurface.parchment,
          onPressed: () => _roll(context),
        ),
      ],
    );
  }
}
