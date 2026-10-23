import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_feat_summary.dart';
import 'feat_info_panel.dart';

/// Carte "DONS" de l'onglet "Aptitudes" : une ligne par don déjà possédé
/// par le personnage ([feats] — `CharacterDetail.feats`, déjà triés par
/// niveau d'acquisition croissant côté données, voir
/// `data/character_detail_row_mapper.dart::parseFeats`).
///
/// Ligne allégée par rapport à `character_class_features_card.dart`/
/// `character_racial_traits_card.dart` : pas de libellé central "Passive" —
/// un don n'a pas ce statut (spec de ce chantier) — juste le nom à gauche
/// et un chevron, même enrobage tap (`Material`+`InkWell`+
/// `ConstrainedBox(minHeight: 44)`).
///
/// Tap -> panneau "Infos" ([showFeatInfoPanel]), réutilisé tel quel (pas
/// dupliqué) avec l'étape "Choix à faire" de la montée de niveau — rendu
/// pixel-identique, voir la documentation de classe de
/// `feat_info_panel.dart`. Pas de bouton d'action : un don déjà possédé ne
/// s'active pas.
///
/// N'affiche rien tant que [feats] est vide — appelant responsable de ne pas
/// monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
class CharacterFeatsCard extends StatelessWidget {
  const CharacterFeatsCard({required this.feats, super.key});

  final List<CharacterFeatSummary> feats;

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
            'DONS',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final feat in feats) _FeatRow(feat: feat),
        ],
      ),
    );
  }
}

class _FeatRow extends StatelessWidget {
  const _FeatRow({required this.feat});

  final CharacterFeatSummary feat;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(feat.name, style: AppTypography.body(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showFeatInfoPanel(
          context,
          name: feat.name,
          description: feat.description,
          prerequisiteText: feat.prerequisiteText,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: row,
        ),
      ),
    );
  }
}
