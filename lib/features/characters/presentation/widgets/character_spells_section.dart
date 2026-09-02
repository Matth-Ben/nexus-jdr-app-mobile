import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_spell_entry.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/spells_by_level_grouper.dart';

/// Section "SORTS" de l'onglet "Sorts" : les sorts connus/préparés du
/// personnage, groupés par niveau (0 = "Sorts mineurs"), avec les
/// emplacements disponibles du niveau affichés en pastilles à côté du titre
/// de chaque niveau ≥ 1.
///
/// Portée volontairement limitée à cette itération : affichage seul, en
/// lecture seule. Chaque sort est une simple ligne (nom + école), **pas**
/// cliquable — la spec du cahier des charges
/// (`04-fonctionnalites-app-mobile.md`, section "Sorts — consultation et
/// lancer") prévoit un panneau "Infos"/"Lancer" par sort (description
/// complète, décompte d'emplacement à l'usage), explicitement reporté à une
/// tâche ultérieure. Pas de `InkWell`/`GestureDetector` sur `_SpellRow` :
/// à ajouter avec le panneau, pas avant, pour ne jamais laisser un item qui
/// réagit au tap sans rien faire.
///
/// N'affiche rien tant que [groups] est vide — appelant responsable de ne
/// pas monter cette section dans ce cas (voir
/// `character_spells_tab_body.dart`).
class CharacterSpellsSection extends StatelessWidget {
  const CharacterSpellsSection({
    required this.groups,
    required this.spellSlots,
    super.key,
  });

  final List<SpellLevelGroup> groups;

  /// Emplacements de sorts par niveau — indexé par niveau dans [build] pour
  /// afficher les pastilles du bon niveau à côté de chaque titre de groupe.
  final List<CharacterSpellSlot> spellSlots;

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
            ),
        ],
      ),
    );
  }
}

class _SpellLevelGroupSection extends StatelessWidget {
  const _SpellLevelGroupSection({required this.group, required this.slot});

  final SpellLevelGroup group;
  final CharacterSpellSlot? slot;

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
                _SpellSlotDots(slot: slot!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          for (final spell in group.spells) _SpellRow(spell: spell),
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
class _SpellSlotDots extends StatelessWidget {
  const _SpellSlotDots({required this.slot});

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
  const _SpellRow({required this.spell});

  final CharacterSpellEntry spell;

  @override
  Widget build(BuildContext context) {
    final school = spell.school.trim();

    // Deux `Text` distincts (nom, puis école entre parenthèses) plutôt qu'un
    // seul `Text.rich`/`TextSpan` : plus simple à cibler par
    // `find.text(...)` dans les tests de widget, et cohérent avec le
    // découpage nom/valeur des autres cartes de cet onglet (ex.
    // `character_skills_card.dart::_SkillRow`).
    return Padding(
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
        ],
      ),
    );
  }
}
