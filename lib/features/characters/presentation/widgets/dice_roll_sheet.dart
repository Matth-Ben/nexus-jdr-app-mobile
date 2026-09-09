import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/dice_roller.dart';
import '../../domain/signed_modifier_formatter.dart';

/// Ouvre le "mini lancer de dé virtuel" d'un jet de compétence/caractéristique
/// — voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Compétences" : "Jets de compétences/caractéristiques directement
/// lançables depuis la fiche". Tire immédiatement un d20 à l'ouverture
/// (relançable via "Relancer"), affiche le total (d20 + [modifier]) — jamais
/// écrit en base, jamais partagé avec personne d'autre : un pur confort de
/// jeu local, comme un vrai dé qu'on lance sur la table.
///
/// [label] : nom de la compétence ("Athlétisme") ou de la caractéristique
/// ("Force") affiché en titre. Aucune distinction de traitement entre les
/// deux cas — un jet de caractéristique brut est juste un jet sans bonus de
/// maîtrise, déjà reflété dans [modifier] par l'appelant.
Future<void> showDiceRollSheet(
  BuildContext context, {
  required String label,
  required int modifier,
  @visibleForTesting Random? random,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DiceRollSheetContent(
      label: label,
      modifier: modifier,
      random: random,
    ),
  );
}

class _DiceRollSheetContent extends StatefulWidget {
  const _DiceRollSheetContent({
    required this.label,
    required this.modifier,
    this.random,
  });

  final String label;
  final int modifier;

  /// Injectable uniquement pour les tests (`DiceRoller.rollD20` documente le
  /// même besoin) — `null` en production, `Random()` non déterministe.
  final Random? random;

  @override
  State<_DiceRollSheetContent> createState() => _DiceRollSheetContentState();
}

class _DiceRollSheetContentState extends State<_DiceRollSheetContent> {
  late int _rollResult = DiceRoller.rollD20(random: widget.random);

  void _reroll() {
    setState(() => _rollResult = DiceRoller.rollD20(random: widget.random));
  }

  @override
  Widget build(BuildContext context) {
    final total = _rollResult + widget.modifier;
    final isCriticalSuccess = _rollResult == 20;
    final isCriticalFailure = _rollResult == 1;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeaderBar(title: widget.label.toUpperCase()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DieFace(
                    value: _rollResult,
                    isCriticalSuccess: isCriticalSuccess,
                    isCriticalFailure: isCriticalFailure,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'd20 ($_rollResult) '
                    '${SignedModifierFormatter.format(widget.modifier)} = $total',
                    style: AppTypography.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isCriticalSuccess || isCriticalFailure) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isCriticalSuccess
                          ? 'RÉUSSITE CRITIQUE'
                          : 'ÉCHEC CRITIQUE',
                      style: AppTypography.display(
                        fontSize: 11,
                        color: isCriticalSuccess
                            ? AppColors.goldEnd
                            : AppColors.accentBrick,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SecondaryButton(
                    label: 'Relancer',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: _reroll,
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

/// Pastille du résultat brut du d20 — bordure dorée en cas de 20 naturel,
/// brique en cas de 1 naturel (mêmes tokens que le reste de la fiche pour
/// signaler une réussite/un échec marquant), `wood.light` sinon.
class _DieFace extends StatelessWidget {
  const _DieFace({
    required this.value,
    required this.isCriticalSuccess,
    required this.isCriticalFailure,
  });

  final int value;
  final bool isCriticalSuccess;
  final bool isCriticalFailure;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCriticalSuccess
        ? AppColors.goldEnd
        : isCriticalFailure
        ? AppColors.accentBrick
        : AppColors.woodLight;

    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: AppBorders.cardEmphasis),
      ),
      child: Text(
        '$value',
        style: AppTypography.body(fontSize: 36, fontWeight: FontWeight.w800),
      ),
    );
  }
}
