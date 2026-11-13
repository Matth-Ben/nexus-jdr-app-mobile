import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/initiative_input.dart';
import 'initiative_field.dart';

/// Feuille « Initiative de {name} » — version **MJ** (PR2) : champ numérique
/// signé -20..60, compteur − / +, « Enregistrer » désactivé si le champ est
/// vide ou invalide. Pas de lanceur de d20 (saisie par le joueur : PR3).
/// Renvoie l'initiative saisie, ou `null` si annulée.
Future<int?> showInitiativeSheet(
  BuildContext context, {
  required String participantName,
  int? initial,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.parchmentBg,
    builder: (_) =>
        InitiativeSheet(participantName: participantName, initial: initial),
  );
}

class InitiativeSheet extends StatefulWidget {
  const InitiativeSheet({
    required this.participantName,
    this.initial,
    super.key,
  });

  final String participantName;
  final int? initial;

  @override
  State<InitiativeSheet> createState() => _InitiativeSheetState();
}

class _InitiativeSheetState extends State<InitiativeSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  InitiativeInput get _input => parseInitiativeInput(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valid = _input.status == InitiativeInputStatus.valid;
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
                    onChanged: () => setState(() {}),
                  ),
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
