import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/spell_cast_eligibility.dart';
import '../../domain/spell_subtitle_formatter.dart';
import 'character_spells_section.dart';
import 'spell_info_panel.dart';

/// Callback d'exécution d'un lancer de sort, appelé une fois le niveau
/// d'emplacement retenu (ou `null` pour un sort niveau 0, rien à persister)
/// — délègue toute la logique d'écriture (optimiste + réseau + message) à
/// l'appelant, voir `character_detail_screen.dart::_castSpell`.
typedef CastSpellCallback = void Function(
  CharacterSpellEntry spell,
  int? slotLevel,
);

/// Ouvre la sheet "Actions de sort" (tap sur une ligne de sort de l'onglet
/// "Sorts", `character_spells_section.dart::_SpellRow`) — gabarit A
/// (`parchmentCard`, pas de bandeau bois) : deux actions, "Infos" (ouvre
/// [showSpellInfoPanel]) et "Lancer" (voir [castSpellFlow]).
///
/// Même patron que `showPortraitUploadSheet` : la sheet elle-même ne fait que
/// retourner l'action choisie (`_SpellSheetAction`), toute la suite du flux
/// (ouverture du panneau "Infos"/de la sheet de choix de niveau) est
/// orchestrée ici sur le [context] appelant (stable), jamais sur celui —
/// éphémère — de la sheet une fois refermée.
Future<void> showSpellActionSheet(
  BuildContext context, {
  required CharacterSpellEntry spell,
  required List<CharacterSpellSlot> spellSlots,
  required CastSpellCallback onCastSpell,
}) async {
  final action = await showModalBottomSheet<_SpellSheetAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _SpellActionSheetContent(spell: spell, spellSlots: spellSlots),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _SpellSheetAction.info:
      await showSpellInfoPanel(
        context,
        spell: spell,
        spellSlots: spellSlots,
        onCastSpell: onCastSpell,
      );
    case _SpellSheetAction.cast:
      await castSpellFlow(
        context,
        spell: spell,
        spellSlots: spellSlots,
        onCastSpell: onCastSpell,
      );
  }
}

/// Orchestre l'action "Lancer" (bouton de [showSpellActionSheet] ou pied du
/// panneau "Infos", [showSpellInfoPanel]) : appelle directement [onCastSpell]
/// quand un seul niveau d'emplacement est éligible (ou pour un sort niveau
/// 0, `slotLevel: null`), ouvre sinon une sheet de choix de niveau
/// ([_SpellSlotChoiceSheetContent]).
///
/// Niveaux éligibles = tous les `L >= spell.level` de [spellSlots],
/// indépendamment de `remaining` (voir [SpellCastEligibility.eligibleSlots])
/// — ne devrait jamais être appelée pour un sort dont aucun niveau éligible
/// n'a `remaining > 0` (l'action "Lancer" est désactivée en amont dans ce
/// cas, voir [SpellCastEligibility.hasAvailableSlot]), mais reste sans effet
/// si [spellSlots] ne contient aucun niveau éligible du tout (garde-fou).
Future<void> castSpellFlow(
  BuildContext context, {
  required CharacterSpellEntry spell,
  required List<CharacterSpellSlot> spellSlots,
  required CastSpellCallback onCastSpell,
}) async {
  if (spell.level <= 0) {
    onCastSpell(spell, null);
    return;
  }

  final eligible = SpellCastEligibility.eligibleSlots(
    spellSlots: spellSlots,
    spellLevel: spell.level,
  );
  if (eligible.isEmpty) return;
  if (eligible.length == 1) {
    onCastSpell(spell, eligible.single.level);
    return;
  }

  final chosenLevel = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _SpellSlotChoiceSheetContent(spell: spell, eligible: eligible),
  );
  if (chosenLevel == null) return;
  onCastSpell(spell, chosenLevel);
}

enum _SpellSheetAction { info, cast }

class _SpellActionSheetContent extends StatelessWidget {
  const _SpellActionSheetContent({
    required this.spell,
    required this.spellSlots,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> spellSlots;

  @override
  Widget build(BuildContext context) {
    final hasSlot = SpellCastEligibility.hasAvailableSlot(
      spellSlots: spellSlots,
      spellLevel: spell.level,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spell.name,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              SpellSubtitleFormatter.format(spell),
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB)),
            SheetActionRow(
              icon: Icons.info_outline,
              label: 'Infos',
              onTap: () => Navigator.of(context).pop(_SpellSheetAction.info),
            ),
            SheetActionRow(
              icon: Icons.auto_fix_high_outlined,
              label: 'Lancer',
              enabled: hasSlot,
              trailingText: hasSlot ? null : 'Aucun emplacement',
              trailingTextColor: AppColors.accentBrick,
              onTap: () => Navigator.of(context).pop(_SpellSheetAction.cast),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpellSlotChoiceSheetContent extends StatefulWidget {
  const _SpellSlotChoiceSheetContent({
    required this.spell,
    required this.eligible,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> eligible;

  @override
  State<_SpellSlotChoiceSheetContent> createState() =>
      _SpellSlotChoiceSheetContentState();
}

class _SpellSlotChoiceSheetContentState
    extends State<_SpellSlotChoiceSheetContent> {
  late int? _selectedLevel = SpellCastEligibility.defaultSelectedLevel(
    spellSlots: widget.eligible,
    spellLevel: widget.spell.level,
  );

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
              'Lancer ${widget.spell.name}',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Choisissez le niveau d'emplacement à utiliser.",
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final slot in widget.eligible) ...[
              _SpellSlotOptionRow(
                slot: slot,
                selected: _selectedLevel == slot.level,
                onSelect: () => setState(() => _selectedLevel = slot.level),
              ),
              if (slot != widget.eligible.last)
                const SizedBox(height: AppSpacing.xs),
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
                    label: 'Lancer',
                    onPressed: _selectedLevel != null
                        ? () => Navigator.of(context).pop(_selectedLevel)
                        : null,
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

/// Une ligne de niveau d'emplacement de la sheet de choix — enveloppe
/// [SelectableOptionTile] (réutilisé tel quel) dans un
/// `ConstrainedBox(minHeight: 44)` : sans `subtitle` (seulement un `leading`
/// discret et un titre court "Niveau {L}"), le composant seul ne garantit
/// pas une zone de tap de 44px de haut (vérifié, contrairement à ses autres
/// usages du dépôt qui portent tous un `subtitle`) — voir la consigne
/// d'accessibilité de la tâche ("ne suppose pas").
class _SpellSlotOptionRow extends StatelessWidget {
  const _SpellSlotOptionRow({
    required this.slot,
    required this.selected,
    required this.onSelect,
  });

  final CharacterSpellSlot slot;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final exhausted = slot.remaining == 0;

    final Widget? leading;
    if (exhausted) {
      leading = Text(
        'Épuisé',
        style: AppTypography.body(fontSize: 11, color: AppColors.accentBrick),
      );
    } else if (slot.total > 0) {
      leading = SpellSlotDots(slot: slot);
    } else {
      leading = Text(
        '${slot.remaining}/${slot.total} restants',
        style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
      );
    }

    final tile = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: SelectableOptionTile(
        title: 'Niveau ${slot.level}',
        selected: selected,
        leading: leading,
        // No-op explicite (pas `null`) pour un niveau épuisé : voir la spec
        // visuelle ("non sélectionnable... onTap no-op").
        onTap: exhausted ? () {} : onSelect,
      ),
    );

    return exhausted ? Opacity(opacity: 0.45, child: tile) : tile;
  }
}
