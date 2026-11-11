import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_spell_slot.dart';
import '../providers/character_detail_provider.dart';
import 'character_spells_section.dart';

/// Écrit la nouvelle valeur *absolue* de `slots_used` de [slot] (voir
/// `character_detail_screen.dart::_setSlotUsed`).
typedef SetSlotUsedCallback = void Function(
  CharacterSpellSlot slot,
  int newUsed,
);

/// Emplacements que la feuille de correction propose d'ajuster : un par
/// niveau disponible de la table combinée (multiclasse inclus), puis le pool
/// de pacte à part (jamais fusionné avec les classiques). Les niveaux sans
/// emplacement (`total == 0`) sont omis.
List<CharacterSpellSlot> correctableSpellSlots(CharacterDetail detail) {
  final classic = [
    for (final slot in detail.spellSlots)
      if (!slot.isPact && slot.level >= 1 && slot.total > 0) slot,
  ]..sort((a, b) => a.level.compareTo(b.level));
  final pact = detail.pactSpellSlot;
  return [
    ...classic,
    if (pact != null && pact.total > 0)
      CharacterSpellSlot(
        level: pact.level,
        total: pact.total,
        used: pact.used,
        isPact: true,
      ),
  ];
}

/// Ouvre la feuille « Corriger les emplacements » (P9) : ajustement manuel
/// du suivi des emplacements (Récupération arcanique, Perle de pouvoir, magie
/// de pacte, erreur de saisie). Les règles D&D n'ont pas d'annulation : c'est
/// une *correction* du suivi, jamais présentée comme une annulation de règle.
///
/// **Chaque appui écrit immédiatement** ([onSetUsed], valeur absolue par
/// niveau, même kind de file `spell_slot` que le lancer) : pas de bouton
/// « Appliquer ». [effectiveOf] fournit la fiche *effective* (superposition
/// optimiste de l'écran) pour que la feuille reflète l'écriture dès l'appui.
/// [isBusy] désactive les steppers (repos en cours).
Future<void> showSpellSlotCorrectionSheet(
  BuildContext context, {
  required String characterId,
  required CharacterDetail Function(CharacterDetail detail) effectiveOf,
  required bool Function() isBusy,
  required SetSlotUsedCallback onSetUsed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.parchmentBg,
    builder: (context) => SpellSlotCorrectionSheet(
      characterId: characterId,
      effectiveOf: effectiveOf,
      isBusy: isBusy,
      onSetUsed: onSetUsed,
    ),
  );
}

class SpellSlotCorrectionSheet extends ConsumerStatefulWidget {
  const SpellSlotCorrectionSheet({
    required this.characterId,
    required this.effectiveOf,
    required this.isBusy,
    required this.onSetUsed,
    super.key,
  });

  final String characterId;
  final CharacterDetail Function(CharacterDetail detail) effectiveOf;
  final bool Function() isBusy;
  final SetSlotUsedCallback onSetUsed;

  @override
  ConsumerState<SpellSlotCorrectionSheet> createState() =>
      _SpellSlotCorrectionSheetState();
}

class _SpellSlotCorrectionSheetState
    extends ConsumerState<SpellSlotCorrectionSheet> {
  void _setUsed(CharacterSpellSlot slot, int newUsed) {
    // Bornes 0..total (aucune contrainte côté serveur : `slots_used` n'a pas
    // de CHECK), appliquées ici une dernière fois par sécurité.
    final bounded = newUsed.clamp(0, slot.total);
    if (bounded == slot.total - slot.remaining) return;
    widget.onSetUsed(slot, bounded);
    // L'écran a posé sa surcouche optimiste de façon synchrone : relit-la.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(characterDetailProvider(widget.characterId)).value;
    final slots = detail == null
        ? const <CharacterSpellSlot>[]
        : correctableSpellSlots(widget.effectiveOf(detail));
    final busy = widget.isBusy();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeaderBar(title: l10n.spellSlotCorrectionSheetTitle.toUpperCase()),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spellSlotCorrectionHintRecover,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.spellSlotCorrectionHintNoUndo,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final slot in slots) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CorrectionRow(
                    slot: slot,
                    busy: busy,
                    onSetUsed: (newUsed) => _setUsed(slot, newUsed),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: PrimaryButton(
            label: l10n.spellSlotCorrectionDoneButton,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _CorrectionRow extends StatelessWidget {
  const _CorrectionRow({
    required this.slot,
    required this.busy,
    required this.onSetUsed,
  });

  final CharacterSpellSlot slot;
  final bool busy;
  final ValueChanged<int> onSetUsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = slot.remaining;
    // Normalisé : une donnée incohérente (used > total) ne produit jamais
    // de valeur hors 0..total.
    final used = slot.total - remaining;
    final rowLabel = slot.isPact
        ? l10n.spellSlotCorrectionPactRowSemanticLabel(
            slot.level,
            remaining,
            slot.total,
          )
        : l10n.spellSlotCorrectionRowSemanticLabel(
            slot.level,
            remaining,
            slot.total,
          );
    final title = slot.isPact
        ? l10n.spellSlotCorrectionPactRowLabel(slot.level)
        : l10n.characterSpellsTabBodySlotsLevelLabel(slot.level);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        // Libellé et pastilles décoratifs pour le lecteur d'écran : les
        // boutons portent l'annonce complète (niveau, restants, action).
        ExcludeSemantics(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                title,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SpellSlotDots(
                slot: slot,
                filledColor: slot.isPact
                    ? AppColors.accentTeal
                    : AppColors.goldEnd,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StepperCounter(
              value: remaining,
              decrementLabel:
                  '$rowLabel. ${l10n.spellSlotCorrectionRemoveLabel}',
              incrementLabel: '$rowLabel. ${l10n.spellSlotCorrectionAddLabel}',
              // « − » consomme un emplacement (un restant de moins), « + » en
              // rend un.
              onDecrement: busy || remaining <= 0
                  ? null
                  : () => onSetUsed(used + 1),
              onIncrement: busy || remaining >= slot.total
                  ? null
                  : () => onSetUsed(used - 1),
            ),
            ExcludeSemantics(
              child: Text(
                '/${slot.total}',
                style: AppTypography.body(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
