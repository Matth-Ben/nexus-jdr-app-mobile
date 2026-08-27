import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Chip "nom seul" utilisé par les cartes compactes de l'onglet
/// "Compétences" (`CharacterToolProficienciesCard`/`CharacterLanguagesCard`).
///
/// Reprend telle quelle la recette déjà établie par `_QuotaBadge`
/// (`character_creation/presentation/skills_and_tools_step_screen.dart` et
/// `spells_step_screen.dart`, dupliquée à l'identique entre ces deux
/// écrans) : fond `parchmentCardAlt`, bordure fine `woodLight`, texte
/// `w700`/`textSecondary` — signalé en revue direction-artistique après que
/// les deux premières versions de ce chip (dans `characters/presentation/`)
/// aient réinventé un pattern légèrement différent (pas de bordure, texte
/// `w400`, padding vertical plus fin).
///
/// Partagé entre les deux cartes de `characters/presentation/widgets/`
/// plutôt que dupliqué une 3e fois : contrairement à la convention
/// habituelle de ce dépôt (un mapping/pattern dupliqué par écran, voir
/// `RaceRowMapper`), les deux cartes vivent dans le même dossier de la même
/// fonctionnalité et partagent exactement le même rôle visuel — dupliquer
/// encore aurait fait diverger silencieusement les deux cartes à la
/// prochaine retouche. `_QuotaBadge` (feature `character_creation`) reste,
/// lui, dupliqué entre ses deux écrans : pas dans le périmètre de cette
/// tâche de le faire pointer ici (cross-feature, à arbitrer séparément si
/// ça se reproduit une 3e fois côté création).
class CharacterNameTagChip extends StatelessWidget {
  const CharacterNameTagChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: 1),
      ),
      child: Text(
        name,
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
