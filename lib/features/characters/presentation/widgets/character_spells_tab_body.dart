import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'character_spells_section.dart';

/// Contenu de l'onglet "Sorts" de la fiche personnage — scindé de l'onglet
/// "Compétences" (voir `character_skills_tab_body.dart`) pour donner aux
/// sorts leur propre onglet à part entière, spec validée par l'agent
/// `direction-artistique`.
///
/// Portée volontairement en lecture seule à cette itération, comme les
/// autres onglets déjà livrés : aucune action d'écriture n'est câblée ici
/// (pas de lancer de sort/consommation d'emplacement) — voir la
/// documentation de classe de `character_spells_section.dart` pour le détail
/// du report.
class CharacterSpellsTabBody extends StatelessWidget {
  const CharacterSpellsTabBody({required this.detail, super.key});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final spellGroups = SpellsByLevelGrouper.group(detail.spells);
    if (spellGroups.isEmpty) {
      return const _EmptySpellsState();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        CharacterSpellsSection(
          groups: spellGroups,
          spellSlots: detail.spellSlots,
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
