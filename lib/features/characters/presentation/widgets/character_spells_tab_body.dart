import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';
import '../../domain/spellcasting_class_names.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'character_spells_section.dart';
import 'spell_action_sheet.dart';

/// Contenu de l'onglet "Sorts" de la fiche personnage — scindé de l'onglet
/// "Compétences" (voir `character_skills_tab_body.dart`) pour donner aux
/// sorts leur propre onglet à part entière, spec validée par l'agent
/// `direction-artistique`.
///
/// [onCastSpell]/[actionsDisabled] délégués tels quels à
/// [CharacterSpellsSection] — voir sa documentation de classe.
class CharacterSpellsTabBody extends StatelessWidget {
  const CharacterSpellsTabBody({
    required this.detail,
    required this.onCastSpell,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;
  final CastSpellCallback onCastSpell;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final spellGroups = SpellsByLevelGrouper.group(detail.spells);
    if (spellGroups.isEmpty) {
      final isSpellcaster = detail.classes.any(
        (classRow) => spellcastingClassNames.contains(classRow.className),
      );
      return isSpellcaster
          ? const _EmptySpellsState()
          : _NonCasterEmptyState(
              characterName: detail.name,
              className: detail.primaryClass?.className ?? 'cette classe',
            );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CharacterSpellsSection(
          groups: spellGroups,
          spellSlots: detail.spellSlots,
          pactSlot: detail.pactSpellSlot,
          onCastSpell: onCastSpell,
          actionsDisabled: actionsDisabled,
        ),
      ],
    );
  }
}

/// État vide (aucun sort sur la fiche) : même agencement (icône + titre +
/// sous-titre centrés) que `_EmptyStoryState` de
/// `character_story_tab_body.dart`.
class _EmptySpellsState extends StatelessWidget {
  const _EmptySpellsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_fix_high_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AUCUN SORT',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun sort sur cette fiche pour l\'instant. Pour les classes '
              'qui lancent des sorts, ils se choisissent depuis l\'assistant '
              'de création ou à la montée de niveau.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide d'une classe structurellement non lanceuse de sorts (ex.
/// Guerrier, Roublard) — distinct de [_EmptySpellsState] (voir maquette
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "État vide —
/// Sorts") : l'onglet reste accessible par cohérence de navigation entre
/// personnages, mais ce message précise que ce n'est pas juste "pas encore
/// choisi".
class _NonCasterEmptyState extends StatelessWidget {
  const _NonCasterEmptyState({
    required this.characterName,
    required this.className,
  });

  final String characterName;
  final String className;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cette classe ne lance pas de sorts',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$characterName est $className — hors archétype dédié (ex. '
              'Chevalier occulte), cette classe ne dispose pas '
              'd\'emplacements de sorts. Cet onglet reste accessible par '
              'cohérence de navigation, mais restera vide pour ce '
              'personnage.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
