import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'character_name_tag_chip.dart';

/// Carte compacte "INVOCATIONS CONNUES" de l'onglet "Compétences" — même
/// gabarit visuel que `CharacterLanguagesCard`/`CharacterToolProficienciesCard`
/// (même chip `CharacterNameTagChip` partagé). Toujours vide pour un
/// personnage non Occultiste — voir `domain/character_detail.dart
/// ::knownInvocationNames`.
///
/// N'affiche rien tant que [names] est vide — appelant responsable de ne pas
/// monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
class CharacterInvocationsCard extends StatelessWidget {
  const CharacterInvocationsCard({required this.names, super.key});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
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
            'INVOCATIONS CONNUES',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final name in names) CharacterNameTagChip(name: name),
            ],
          ),
        ],
      ),
    );
  }
}
