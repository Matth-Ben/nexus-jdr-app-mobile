import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_spell_slot.dart';
import 'character_spells_section.dart';

/// Carte de synthèse "EMPLACEMENTS DE SORTS" en tête de l'onglet "Sorts"
/// (recettage direction-artistique du 13/09) : une ligne par niveau
/// d'emplacement (`spell_slots`, hors magie de pacte — déjà son propre bloc
/// dédié plus bas, `character_spells_section.dart::_PactSlotBanner`), avec
/// les mêmes pastilles pleines/vides ([SpellSlotDots]) que celles utilisées
/// à côté de chaque titre de groupe par niveau.
///
/// N'affiche rien tant qu'aucun niveau n'a d'emplacement réel
/// (`total > 0`) — appelant responsable de ne pas monter cette carte dans ce
/// cas (voir [hasContent]/`character_spells_tab_body.dart`), même convention
/// que les autres cartes optionnelles de la fiche (ex.
/// `character_class_choices_card.dart`).
class CharacterSpellSlotsSummaryCard extends StatelessWidget {
  const CharacterSpellSlotsSummaryCard({required this.spellSlots, super.key});

  final List<CharacterSpellSlot> spellSlots;

  static bool hasContent(List<CharacterSpellSlot> spellSlots) =>
      _visibleSlotsOf(spellSlots).isNotEmpty;

  static List<CharacterSpellSlot> _visibleSlotsOf(
    List<CharacterSpellSlot> spellSlots,
  ) {
    final visible = spellSlots.where((slot) => slot.total > 0).toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _visibleSlotsOf(spellSlots);
    if (slots.isEmpty) {
      // Ne devrait pas arriver : l'appelant est censé avoir déjà vérifié
      // [hasContent] avant d'insérer cette carte.
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMPLACEMENTS DE SORTS',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final slot in slots) ...[
            _SlotSummaryRow(slot: slot),
            if (slot != slots.last) const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Se réinitialisent lors d\'un repos long.',
            style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SlotSummaryRow extends StatelessWidget {
  const _SlotSummaryRow({required this.slot});

  final CharacterSpellSlot slot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Niveau ${slot.level}',
          style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.sm),
        SpellSlotDots(slot: slot),
      ],
    );
  }
}
