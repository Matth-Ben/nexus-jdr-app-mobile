import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'spell_action_sheet.dart';
import 'spell_info_panel.dart';

/// Section "SORTS" de l'onglet "Sorts" : les sorts connus/préparés du
/// personnage, groupés par niveau (0 = "Sorts mineurs"), avec les
/// emplacements disponibles du niveau affichés en pastilles à côté du titre
/// de chaque niveau ≥ 1.
///
/// Chaque sort (`_SpellRow`) est cliquable, ouvrant directement le panneau
/// "Infos" ([showSpellInfoPanel], qui porte déjà son propre bouton
/// "Lancer" en pied) — la sheet intermédiaire "Infos"/"Lancer" qui précédait
/// ce panneau a été retirée : elle n'ajoutait qu'un aller-retour, "Lancer"
/// étant de toute façon accessible depuis le panneau "Infos" (retour
/// utilisateur). [onCastSpell] délègue toute la logique
/// d'écriture (optimiste + réseau) à l'appelant
/// (`character_detail_screen.dart::_castSpell`), même principe que
/// `onTapAdjustHp`/`onTapRest` de `_CharacterTabBody`.
///
/// N'affiche rien tant que [groups] est vide — appelant responsable de ne
/// pas monter cette section dans ce cas (voir
/// `character_spells_tab_body.dart`).
class CharacterSpellsSection extends StatelessWidget {
  const CharacterSpellsSection({
    required this.groups,
    required this.spellSlots,
    required this.onCastSpell,
    this.actionsDisabled = false,
    super.key,
  });

  final List<SpellLevelGroup> groups;

  /// Emplacements de sorts par niveau — indexé par niveau dans [build] pour
  /// afficher les pastilles du bon niveau à côté de chaque titre de groupe,
  /// et transmis tel quel à [showSpellInfoPanel] (calcul d'éligibilité).
  final List<CharacterSpellSlot> spellSlots;

  final CastSpellCallback onCastSpell;

  /// `true` pendant qu'un repos long est en cours d'application (voir
  /// `character_detail_screen.dart::_isApplyingRest`) : désactive le tap sur
  /// chaque sort, un repos long réinitialisant les emplacements de sorts —
  /// même verrou déjà appliqué au bandeau PV (`CharacterVitalsCard
  /// .hpActionsDisabled`), ferme ici le même type de course qu'un lancer de
  /// sort démarré pendant que le repos écrit encore en base (voir la
  /// documentation de `_castSpell`).
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final slotsByLevel = {for (final slot in spellSlots) slot.level: slot};

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
            'SORTS',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          for (final group in groups)
            _SpellLevelGroupSection(
              group: group,
              slot: slotsByLevel[group.level],
              spellSlots: spellSlots,
              onCastSpell: onCastSpell,
              actionsDisabled: actionsDisabled,
            ),
        ],
      ),
    );
  }
}

class _SpellLevelGroupSection extends StatelessWidget {
  const _SpellLevelGroupSection({
    required this.group,
    required this.slot,
    required this.spellSlots,
    required this.onCastSpell,
    required this.actionsDisabled,
  });

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;
  final List<CharacterSpellSlot> spellSlots;
  final CastSpellCallback onCastSpell;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    // Les pastilles d'emplacement n'ont de sens qu'à partir du niveau 1 (les
    // sorts mineurs, niveau 0, ne consomment jamais d'emplacement) et
    // seulement si des emplacements existent réellement pour ce niveau
    // (`character_spell_slots` peut ne porter aucune ligne pour un niveau
    // donné, ex. personnage pas encore assez haut niveau).
    final showPips = group.level > 0 && slot != null && slot!.total > 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.label,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showPips) ...[
                const SizedBox(width: AppSpacing.xs),
                SpellSlotDots(slot: slot!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          for (final spell in group.spells)
            _SpellRow(
              spell: spell,
              spellSlots: spellSlots,
              onCastSpell: onCastSpell,
              enabled: !actionsDisabled,
            ),
        ],
      ),
    );
  }
}

/// Emplacements de sorts d'un niveau, en pastilles pleines/vides — mêmes
/// couleurs que le point de maîtrise déjà utilisé ailleurs dans cet onglet
/// (`character_skills_card.dart::_SkillDot`,
/// `character_saving_throws_card.dart::_ProficiencyDot`) : un vrai cercle
/// graphique plutôt qu'un glyphe Unicode "●"/"○" coloré en texte
/// (`domain/spell_slot_pips_formatter.dart::SpellSlotPipsFormatter.format`,
/// gardé pour ses tests unitaires et une éventuelle réutilisation ultérieure,
/// mais plus utilisé ici) — le contraste texte `AppColors.goldEnd` sur
/// `AppColors.parchmentCard` (~2,4:1) était très sous le minimum AA 4.5:1,
/// signalé en revue direction-artistique. [Semantics.label] porte une phrase
/// lisible ("X restants sur Y") plutôt que le rendu en pastilles, plus
/// adaptée à un lecteur d'écran qu'une suite de glyphes pleins/vides.
class SpellSlotDots extends StatelessWidget {
  const SpellSlotDots({required this.slot, super.key});

  final CharacterSpellSlot slot;

  @override
  Widget build(BuildContext context) {
    final total = slot.total < 0 ? 0 : slot.total;
    final remaining = slot.remaining;

    return Semantics(
      label: 'Emplacements de sorts : $remaining restants sur $total',
      // `container: true` : ce noeud de sémantique ne doit jamais fusionner
      // dans celui du `Text` voisin (le libellé de niveau, ex. "Niveau 1")
      // — sans quoi le libellé ci-dessus disparaîtrait, absorbé dans le
      // texte du parent.
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _SpellSlotDot(filled: i < remaining),
          ],
        ],
      ),
    );
  }
}

class _SpellSlotDot extends StatelessWidget {
  const _SpellSlotDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.goldEnd : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
    );
  }
}

class _SpellRow extends StatelessWidget {
  const _SpellRow({
    required this.spell,
    required this.spellSlots,
    required this.onCastSpell,
    required this.enabled,
  });

  final CharacterSpellEntry spell;
  final List<CharacterSpellSlot> spellSlots;
  final CastSpellCallback onCastSpell;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final school = spell.school.trim();

    // Deux `Text` distincts (nom, puis école entre parenthèses) plutôt qu'un
    // seul `Text.rich`/`TextSpan` : plus simple à cibler par
    // `find.text(...)` dans les tests de widget, et cohérent avec le
    // découpage nom/valeur des autres cartes de cet onglet (ex.
    // `character_skills_card.dart::_SkillRow`).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () => showSpellInfoPanel(
                context,
                spell: spell,
                spellSlots: spellSlots,
                onCastSpell: onCastSpell,
              )
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    spell.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(fontSize: 13),
                  ),
                ),
                if (school.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs / 2),
                  Flexible(
                    child: Text(
                      '($school)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs / 2),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
