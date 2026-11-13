import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/initiative_input.dart';
import 'add_monster_sheet.dart'
    show CombatSheetAnnouncer, defaultCombatAnnouncer;
import 'initiative_field.dart';
import 'initiative_roll_block.dart';

/// Feuille « Initiative de {name} » : champ numérique signé -20..60, compteur
/// − / +, « Enregistrer » désactivé si le champ est vide ou invalide, et —
/// quand [rollModifier] est fourni — « Lancer un d20 » (le total retenu remplit
/// le champ, qui reste modifiable).
///
/// - Joueur (sa propre initiative) : [rollModifier] = modificateur d'initiative
///   de sa fiche (`CharacterDetail.initiative`), [showDexHelp] affiche
///   « Dextérité : +3 → d20 + 3 ».
/// - MJ (PNJ ou ligne d'un autre) : [rollModifier] = 0, pas d'aide.
/// - [rollModifier] `null` : pas de lanceur (modificateur inconnu).
///
/// Renvoie l'initiative saisie, ou `null` si annulée.
Future<int?> showInitiativeSheet(
  BuildContext context, {
  required String participantName,
  int? initial,
  int? rollModifier,
  bool showDexHelp = false,
  CombatSheetAnnouncer announcer = defaultCombatAnnouncer,
  InitiativeRollOpener rollOpener = defaultInitiativeRollOpener,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.parchmentBg,
    builder: (_) => InitiativeSheet(
      participantName: participantName,
      initial: initial,
      rollModifier: rollModifier,
      showDexHelp: showDexHelp,
      announcer: announcer,
      rollOpener: rollOpener,
    ),
  );
}

class InitiativeSheet extends StatefulWidget {
  const InitiativeSheet({
    required this.participantName,
    this.initial,
    this.rollModifier,
    this.showDexHelp = false,
    this.announcer = defaultCombatAnnouncer,
    this.rollOpener = defaultInitiativeRollOpener,
    super.key,
  });

  final String participantName;
  final int? initial;
  final int? rollModifier;
  final bool showDexHelp;
  final CombatSheetAnnouncer announcer;
  final InitiativeRollOpener rollOpener;

  @override
  State<InitiativeSheet> createState() => _InitiativeSheetState();
}

class _InitiativeSheetState extends State<InitiativeSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  InitiativeInput get _input => parseInitiativeInput(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valid = _input.status == InitiativeInputStatus.valid;
    final rollModifier = widget.rollModifier;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeaderBar(
              title: l10n.combatInitiativeSheetTitle(widget.participantName),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InitiativeField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: () => setState(() {}),
                  ),
                  if (rollModifier != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InitiativeRollBlock(
                      controller: _controller,
                      focusNode: _focus,
                      modifier: rollModifier,
                      showDexHelp: widget.showDexHelp,
                      announcer: widget.announcer,
                      opener: widget.rollOpener,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: l10n.combatSave,
                    onPressed: valid
                        ? () => Navigator.of(context).pop(_input.value)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: l10n.combatCancel,
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
