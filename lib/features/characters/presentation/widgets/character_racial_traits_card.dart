import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_racial_trait.dart';
import 'racial_trait_info_panel.dart';

/// Carte "TRAITS RACIAUX" de l'onglet "Aptitudes" : une ligne par trait
/// racial de [traits] (`CharacterDetail.racialTraits` — race de base
/// d'abord, puis sous-race à la suite, voir sa documentation de classe),
/// dans l'ordre authored en base (PAS de tri alphabétique, contrairement à
/// `character_class_features_card.dart`).
///
/// Même coquille/ligne que `character_class_features_card.dart`
/// (`_FeatureRow`) : nom à gauche, libellé "Passive" à droite en
/// `fontSize:12/w600/textMuted`, chevron, `Material`+`InkWell`+
/// `ConstrainedBox(minHeight: 44)`, tap -> panneau "Infos"
/// ([showRacialTraitInfoPanel]).
///
/// **Décision tranchée, à respecter strictement** (consigne d'origine de ce
/// chantier) : TOUS les traits affichent "Passive", y compris une aptitude
/// active à usages limités comme "Poussée d'adrénaline" (Orc) — AUCUNE
/// variante visuelle, AUCUN compteur, AUCUN bouton d'usage. Le suivi de
/// ressources des traits raciaux (compteur d'usages restants, repos court/
/// long, bouton "Utiliser"...) est explicitement HORS PÉRIMÈTRE de cette
/// carte, à traiter dans un chantier séparé si un jour souhaité — ceci n'est
/// PAS un oubli : ne pas "compléter" silencieusement cette implémentation
/// sans en reparler au chef de projet. Le texte RAW de la limite d'usage
/// reste dans la description du trait, lue au tap ([showRacialTraitInfoPanel]).
///
/// N'affiche rien tant que [traits] est vide — appelant responsable de ne
/// pas monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
class CharacterRacialTraitsCard extends StatelessWidget {
  const CharacterRacialTraitsCard({required this.traits, super.key});

  final List<CharacterRacialTrait> traits;

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
            'TRAITS RACIAUX',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final trait in traits) _RacialTraitRow(trait: trait),
        ],
      ),
    );
  }
}

class _RacialTraitRow extends StatelessWidget {
  const _RacialTraitRow({required this.trait});

  final CharacterRacialTrait trait;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(trait.name, style: AppTypography.body(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            // Toujours "Passive" — voir la documentation de classe de
            // [CharacterRacialTraitsCard], aucune exception.
            'Passive',
            textAlign: TextAlign.right,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.xs / 2),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showRacialTraitInfoPanel(context, trait: trait),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: row,
        ),
      ),
    );
  }
}
